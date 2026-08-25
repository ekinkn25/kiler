"""W4-T04 dogrulama: ogrenen profil motorunun gercek veriyle sinanmasi.

    python -m scripts.verify_taste_engine
    python -m scripts.verify_taste_engine --swipe 30 --json rapor.json

Ne yapar:
  1) Temiz bir test kullanicisi acar, kilerini sabitler.
  2) HTTP ucundan swipe atar: /recipes/deck -> /recipes/{id} -> /swipe.
     Uretimdeki ogrenme yolu birebir calisir (router + swipe_service +
     taste_service). Sentetik sinyal enjekte EDILMEZ.
  3) event_count ve agirlik dagilimini raporlar (YAKINSAMA olcumu).
  4) T06'nin zevk bilesenini ACIK / KAPALI iki durumda calistirip oneri
     siralamasini karsilastirir: Spearman, Kendall tau, top-10 kesisimi,
     sira kaymasi.

Zevk KAPALI durumu ScoringContext.taste bosaltilarak uretilir; boylece
kiler/kalori/sure bilesenleri iki kosulda da BIREBIR aynidir ve olculen
fark yalnizca ogrenen profilden gelir.

MongoDB + seed edilmis tarifler + seed edilmis sozluk GEREKTIRIR.
Tarif yoksa once: python -m scripts.seed_recipes
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from collections import Counter
from dataclasses import replace
from statistics import mean, median

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.config import settings
from app.core.deps import DbSession, get_current_active_user
from app.core.security import hash_password
from app.db.mongo_schema import RECIPE_COLLECTION
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo
from app.db.session import SessionLocal
from app.main import app
from app.models import Ingredient, PantryItem, User
from app.models.enums import Availability, PantrySource
from app.models.recipe import RecipeFeedback, SwipeSession, UserTasteWeight
from app.services.recipe_scoring import build_context, score_recipes

ONEK = settings.API_V1_PREFIX
TEST_EMAIL = "taste_lab@example.com"

# Sabit zevk profili: bakliyat/sebze sever, kirmizi et sevmez.
# 'tuz'/'su' gibi her tarifte gecen malzemeler BILEREK secilmedi - ayirt
# edici olmayan anahtar zevk vektorunu bilgilendirmez, sadece sisirir.
SEVILEN = ("patlican", "bulgur", "kabak", "kuru_fasulye",
           "nohut", "kirmizi_mercimek", "ispanak")
SEVMEDIGI = ("kiyma", "dana_eti", "sucuk", "kuzu_eti")

# Kiler iki kosulda da ayni; skorun kiler bileseni sabit kalsin diye var.
KILER = ("sogan", "domates", "zeytinyagi", "yumurta", "pirinc", "havuc")

# 'Olculebilir degisim' esikleri.
#
# Spearman/Kendall BILGI amaclidir, kabul kriteri degil: 110 tarifin
# tamami skorlandiginda alt siralardaki kucuk oynamalar korelasyonu
# yuksek tutar, oysa kullanici yalnizca ilk ekrani gorur.
#
# Kriter iki somut olcuye baglandi:
#   - ilk 10 konumun en az 3'unde farkli tarif durmali (gozle gorulur fark)
#   - zevk skoru tariflerin yarisindan fazlasinda essiz olmali; aksi halde
#     bilesen ayrim yapmiyor, sadece herkese sabit bir sayi ekliyordur.
ESIK_TOP10_KONUM = 3
ESIK_ZEVK_AYRIM_ORANI = 0.5

basarili = basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


# ==================================================================
# Siralama metrikleri (scipy yok; saf Python)
# ==================================================================
def spearman(a: list[str], b: list[str]) -> float:
    """Sira korelasyonu. 1.0 = ayni siralama, 0 civari = iliskisiz."""
    sira_b = {k: i for i, k in enumerate(b)}
    ortak = [(i, sira_b[k]) for i, k in enumerate(a) if k in sira_b]
    n = len(ortak)
    if n < 2:
        return 1.0
    d2 = sum((i - j) ** 2 for i, j in ortak)
    return 1.0 - (6.0 * d2) / (n * (n * n - 1))


def kendall_tau(a: list[str], b: list[str]) -> float:
    """Ikili sira uyumu. Spearman'dan daha az 'uc kayma' hassasiyeti var."""
    sira_b = {k: i for i, k in enumerate(b)}
    ortak = [sira_b[k] for k in a if k in sira_b]
    n = len(ortak)
    uyumlu = uyumsuz = 0
    for i in range(n):
        for j in range(i + 1, n):
            fark = ortak[j] - ortak[i]
            if fark > 0:
                uyumlu += 1
            elif fark < 0:
                uyumsuz += 1
    toplam = uyumlu + uyumsuz
    return (uyumlu - uyumsuz) / toplam if toplam else 1.0


def kayma_istatistigi(a: list[str], b: list[str]) -> dict:
    """Her tarifin iki siralama arasindaki konum farki."""
    sira_b = {k: i for i, k in enumerate(b)}
    kaymalar = [abs(i - sira_b[k]) for i, k in enumerate(a) if k in sira_b]
    if not kaymalar:
        return {"ortalama": 0.0, "maksimum": 0, "yer_degistiren": 0}
    return {
        "ortalama": round(mean(kaymalar), 2),
        "maksimum": max(kaymalar),
        "yer_degistiren": sum(1 for k in kaymalar if k > 0),
    }


# ==================================================================
# Hazirlik
# ==================================================================
def test_kullanicisi(db) -> User:
    k = db.scalar(select(User).where(User.email == TEST_EMAIL))
    if k is None:
        k = User(email=TEST_EMAIL, hashed_password=hash_password("Test1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def sifirla(db, user: User) -> None:
    """Onceki kosunun izlerini siler. Olcum tekrar edilebilir olmali."""
    db.query(RecipeFeedback).filter(RecipeFeedback.user_id == user.id).delete()
    db.query(SwipeSession).filter(SwipeSession.user_id == user.id).delete()
    db.query(UserTasteWeight).filter(UserTasteWeight.user_id == user.id).delete()
    db.query(PantryItem).filter(PantryItem.user_id == user.id).delete()
    # Beyan edilen kisit yok: sert filtreler olcumu daraltmasin.
    user.diet_tags.clear()
    user.allergens.clear()
    db.commit()

    eklendi = 0
    for ad in KILER:
        malzeme = db.scalar(select(Ingredient).where(Ingredient.canonical_name == ad))
        if malzeme is None:
            continue
        kayit = PantryItem(user_id=user.id, ingredient_id=malzeme.id,
                           availability=Availability.VAR, source=PantrySource.MANUEL)
        kayit.confirm(PantrySource.MANUEL, confidence=1.0)
        db.add(kayit)
        eklendi += 1
    db.commit()
    print(f"  Kiler kuruldu: {eklendi}/{len(KILER)} malzeme")


def karar(tarif: dict) -> tuple[str | None, str | None]:
    """Sabit profile gore bir tarifin swipe kararini uretir.

    None doner = kullanici karti gecti. Gercek kullanimda oldugu gibi
    kararsiz kartlar da destede yer alsin diye var; deste zaten o karti
    'gordu' olarak isaretledi, ayrica bir sinyal gonderilmez.
    """
    zorunlu = {
        m["canonical_name"] for m in tarif.get("ingredients", [])
        if m.get("canonical_name") and not m.get("optional")
    }
    if zorunlu & set(SEVMEDIGI):
        return "begenmedim", "sevmedim"
    if zorunlu & set(SEVILEN):
        # Kolay olani gercekten pisiriyor, zoru sadece begeniyor.
        return ("yaptim", None) if tarif.get("difficulty") == "kolay" else ("begendim", None)
    return None, None


# ==================================================================
# 1) HTTP uzerinden swipe simulasyonu
# ==================================================================
def _oturuma_bagli_kullanici(db: DbSession) -> User:
    """Auth override'i. Kullaniciyi ISTEGIN KENDI oturumundan yukler.

    Disaridan hazir bir User nesnesi vermek yanlis olurdu: o nesne baska
    (kapanmis) bir Session'a bagli olur, iliski erisimlerinde patlar.
    """
    return db.scalars(select(User).where(User.email == TEST_EMAIL)).one()


def swipe_simulasyonu(hedef: int) -> dict:
    """Gercek uclara istek atarak `hedef` adet OGRENEN sinyal uretir."""
    sayac: Counter[str] = Counter()
    islenen: list[dict] = []

    app.dependency_overrides[get_current_active_user] = _oturuma_bagli_kullanici
    try:
        with TestClient(app) as istemci:
            y = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 10})
            if y.status_code != 200:
                sys.exit(f"Deste alinamadi ({y.status_code}): {y.text[:200]}\n"
                         "Tarifler seed edilmis mi? python -m scripts.seed_recipes")
            deste = y.json()
            oturum = deste["session_id"]

            while sayac["ogrenen"] < hedef:
                for kart in deste["items"]:
                    detay = istemci.get(f"{ONEK}/recipes/{kart['id']}")
                    if detay.status_code != 200:
                        continue
                    eylem, sebep = karar(detay.json())
                    if eylem is None:
                        sayac["gecildi"] += 1
                        continue

                    govde: dict = {"action": eylem, "session_id": oturum}
                    if sebep:
                        govde["reason"] = sebep
                    if eylem == "yaptim":
                        govde["rating"] = 5

                    c = istemci.post(f"{ONEK}/recipes/{kart['id']}/swipe", json=govde)
                    if c.status_code != 201:
                        print(f"  [UYARI] swipe {c.status_code}: {c.text[:120]}")
                        continue

                    sayac[eylem] += 1
                    sayac["toplam"] += 1
                    if eylem in ("begendim", "yaptim", "begenmedim"):
                        sayac["ogrenen"] += 1
                        islenen.append({"title": kart["title"], "action": eylem})
                    if sayac["ogrenen"] >= hedef:
                        break

                if sayac["ogrenen"] >= hedef:
                    break

                deste = istemci.get(f"{ONEK}/recipes/deck",
                                    params={"session_id": oturum, "limit": 10}).json()
                if deste.get("exhausted") or not deste["items"]:
                    print("  [UYARI] Deste tukendi; hedeflenen sinyal sayisina "
                          "ulasilamadi.")
                    break
    finally:
        app.dependency_overrides.clear()

    print(f"\n  Toplam {sayac['toplam']} sinyal: "
          f"yaptim={sayac['yaptim']} begendim={sayac['begendim']} "
          f"sevmedim={sayac['begenmedim']} | gecilen kart={sayac['gecildi']}")
    return {"sayac": dict(sayac), "ogrenen_kartlar": islenen}


# ==================================================================
# 2) Agirlik / event_count dagilimi
# ==================================================================
def agirlik_raporu(db, user: User) -> dict:
    satirlar = list(db.scalars(
        select(UserTasteWeight).where(UserTasteWeight.user_id == user.id)
    ))
    if not satirlar:
        return {"satir": 0}

    print(f"\n  {'boyut':<12}{'satir':<8}{'ev.min':<8}{'ev.med':<8}"
          f"{'ev.maks':<9}{'|w|=1':<8}{'w araligi'}")
    print(f"  {'-'*12}{'-'*8}{'-'*8}{'-'*8}{'-'*9}{'-'*8}{'-'*18}")

    boyutlar: dict[str, dict] = {}
    for boyut in sorted({s.dimension.value for s in satirlar}):
        grup = [s for s in satirlar if s.dimension.value == boyut]
        sayimlar = [s.event_count for s in grup]
        agirliklar = [round(s.weight, 4) for s in grup]
        doygun = sum(1 for w in agirliklar if abs(abs(w) - 1.0) < 1e-9)
        boyutlar[boyut] = {
            "satir": len(grup),
            "event_count": {"min": min(sayimlar), "medyan": median(sayimlar),
                            "maks": max(sayimlar), "toplam": sum(sayimlar)},
            "doygun_agirlik": doygun,
            "agirlik_min": min(agirliklar), "agirlik_maks": max(agirliklar),
            "essiz_agirlik": len(set(agirliklar)),
        }
        print(f"  {boyut:<12}{len(grup):<8}{min(sayimlar):<8}"
              f"{median(sayimlar):<8}{max(sayimlar):<9}"
              f"{f'{doygun}/{len(grup)}':<8}"
              f"[{min(agirliklar):+.3f}, {max(agirliklar):+.3f}]")

    tum_agirliklar = [round(s.weight, 4) for s in satirlar]
    toplam_doygun = sum(1 for w in tum_agirliklar if abs(abs(w) - 1.0) < 1e-9)
    return {
        "satir": len(satirlar),
        "boyutlar": boyutlar,
        "doygun_oran": round(toplam_doygun / len(satirlar), 4),
        "essiz_agirlik": len(set(tum_agirliklar)),
        "event_count_toplam": sum(s.event_count for s in satirlar),
    }


# ==================================================================
# 3) Zevk ACIK / KAPALI siralama karsilastirmasi
# ==================================================================
def siralama_raporu(acik: list[dict], kapali: list[dict]) -> dict:
    a_ids = [t["id"] for t in acik]
    k_ids = [t["id"] for t in kapali]

    top10_ortak = set(a_ids[:10]) & set(k_ids[:10])
    # KUME ve KONUM degisimi ayri seylerdir: ilk 10'daki tarifler ayni
    # kalip sadece siralari degisirse kume farki 0 cikar ama kullanicinin
    # gordugu ekran bastan asagi degismistir. Kabul kriteri KONUM'a bakar.
    top10_konum = sum(1 for i in range(min(10, len(a_ids)))
                      if a_ids[i] != k_ids[i])
    zevk_acik = [t["score_breakdown"]["taste"] for t in acik]
    zevk_kapali = [t["score_breakdown"]["taste"] for t in kapali]

    rapor = {
        "tarif": len(a_ids),
        "spearman": round(spearman(a_ids, k_ids), 4),
        "kendall_tau": round(kendall_tau(a_ids, k_ids), 4),
        "top10_ortak": len(top10_ortak),
        "top10_kume_degisim": 10 - len(top10_ortak),
        "top10_konum_degisim": top10_konum,
        "birinci_degisti": a_ids[0] != k_ids[0],
        "kayma": kayma_istatistigi(a_ids, k_ids),
        # Kosular arasi diff alinabilsin diye ilk 10 basligi da yaziliyor.
        "top10_acik": [t["title"] for t in acik[:10]],
        "top10_kapali": [t["title"] for t in kapali[:10]],
        "zevk_skoru_acik": {
            "essiz_deger": len(set(zevk_acik)),
            "min": min(zevk_acik), "maks": max(zevk_acik),
            "ortalama": round(mean(zevk_acik), 4),
        },
        "zevk_skoru_kapali": {
            "essiz_deger": len(set(zevk_kapali)),
            "min": min(zevk_kapali), "maks": max(zevk_kapali),
        },
    }

    print(f"\n  {'#':<4}{'ZEVK ACIK':<34}{'skor':<9}{'zevk':<8}"
          f"{'| ZEVK KAPALI':<34}{'skor'}")
    print(f"  {'-'*4}{'-'*34}{'-'*9}{'-'*8}{'-'*34}{'-'*8}")
    for i in range(min(10, len(acik))):
        a, k = acik[i], kapali[i]
        isaret = " " if a["id"] == k["id"] else "*"
        print(f"  {i+1:<4}{isaret}{a['title'][:32]:<33}{a['final_score']:<9}"
              f"{a['score_breakdown']['taste']:<8}"
              f"| {k['title'][:31]:<32}{k['final_score']}")
    print("  ('*' = o sirada tarif degisti)")
    return rapor


async def olc(user_id: int) -> dict:
    await connect_to_mongo()
    if not mongo.is_connected:
        sys.exit("MongoDB baglantisi yok. .env icindeki MONGODB_URI'yi kontrol et.")

    db = SessionLocal()
    try:
        user = db.get(User, user_id)
        toplam = await mongo.database[RECIPE_COLLECTION].count_documents(
            {"is_active": {"$ne": False}}
        )

        print("\n3) Ogrenilen zevk vektoru")
        agirlik = agirlik_raporu(db, user)

        ctx_acik = build_context(db, user)
        ctx_kapali = replace(ctx_acik, taste=())
        kontrol("Zevk vektoru baglama dolduruldu", len(ctx_acik.taste) > 0,
                f"-> {len(ctx_acik.taste)} anahtar")
        kontrol("KAPALI kosulda zevk vektoru bos", ctx_kapali.taste == ())
        kontrol("Kiler iki kosulda ayni", ctx_acik.var == ctx_kapali.var,
                f"-> {len(ctx_acik.var)} malzeme")

        print("\n4) Oneri siralamasi: zevk ACIK vs KAPALI  <-- kabul kriteri")
        acik = await score_recipes(mongo.database, ctx_acik, limit=toplam)
        kapali = await score_recipes(mongo.database, ctx_kapali, limit=toplam)
        siralama = siralama_raporu(acik, kapali)
    finally:
        db.close()
        await close_mongo_connection()

    return {"agirlik": agirlik, "siralama": siralama}


# ==================================================================
def main() -> None:
    ayristirici = argparse.ArgumentParser(description=__doc__)
    ayristirici.add_argument("--swipe", type=int, default=30,
                             help="Hedeflenen OGRENEN sinyal sayisi (varsayilan 30)")
    ayristirici.add_argument("--json", dest="json_yolu", default=None,
                             help="Olcum sonucunu bu dosyaya JSON olarak yaz")
    ayristirici.add_argument("--etiket", default="mevcut",
                             help="Rapora yazilacak kosu etiketi (once/sonra)")
    args = ayristirici.parse_args()

    print(f"\n{'='*72}")
    print(f"W4-T04 | ogrenen profil motoru dogrulamasi | kosu: {args.etiket}")
    print(f"{'='*72}")

    print("\n1) Hazirlik")
    db = SessionLocal()
    user = test_kullanicisi(db)
    sifirla(db, user)
    kullanici_kimlik = user.id
    db.close()

    print(f"\n2) HTTP uzerinden swipe simulasyonu (hedef: {args.swipe} ogrenen sinyal)")
    simulasyon = swipe_simulasyonu(args.swipe)
    kontrol(f"EN AZ {args.swipe} OGRENEN SWIPE  <-- kabul kriteri",
            simulasyon["sayac"].get("ogrenen", 0) >= args.swipe,
            f"-> {simulasyon['sayac'].get('ogrenen', 0)} sinyal")

    sonuc = asyncio.run(olc(kullanici_kimlik))

    s = sonuc["siralama"]
    ayrim_orani = s["zevk_skoru_acik"]["essiz_deger"] / max(s["tarif"], 1)
    kontrol("SIRALAMA OLCULEBILIR SEKILDE DEGISIYOR  <-- kabul kriteri",
            s["top10_konum_degisim"] >= ESIK_TOP10_KONUM,
            f"-> ilk 10'un {s['top10_konum_degisim']} konumunda farkli tarif "
            f"(>={ESIK_TOP10_KONUM} olmali) | spearman={s['spearman']} "
            f"kendall={s['kendall_tau']} ort.kayma={s['kayma']['ortalama']}")
    kontrol("Zevk skoru tariflere gore ayrisiyor  <-- kabul kriteri",
            ayrim_orani > ESIK_ZEVK_AYRIM_ORANI,
            f"-> {s['zevk_skoru_acik']['essiz_deger']}/{s['tarif']} essiz deger "
            f"(oran {ayrim_orani:.2f} > {ESIK_ZEVK_AYRIM_ORANI} olmali), "
            f"aralik [{s['zevk_skoru_acik']['min']}, {s['zevk_skoru_acik']['maks']}]")
    kontrol("KAPALI kosulda zevk skoru notr (0.5)",
            s["zevk_skoru_kapali"]["min"] == s["zevk_skoru_kapali"]["maks"] == 0.5,
            f"-> {s['zevk_skoru_kapali']['min']}")
    kontrol("Agirliklarin hepsi doygun DEGIL",
            sonuc["agirlik"].get("doygun_oran", 1.0) < 0.9,
            f"-> doygun oran {sonuc['agirlik'].get('doygun_oran')}, "
            f"essiz agirlik {sonuc['agirlik'].get('essiz_agirlik')}")

    if args.json_yolu:
        with open(args.json_yolu, "w", encoding="utf-8") as dosya:
            json.dump({"etiket": args.etiket, "simulasyon": simulasyon, **sonuc},
                      dosya, ensure_ascii=False, indent=2, default=str)
        print(f"\n  Rapor yazildi: {args.json_yolu}")

    print(f"\n{'-'*72}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()
