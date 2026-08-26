"""W4-T13 olcumu: API gecikmesi, indeks kullanimi ve gorsel boyutu.

    python -m scripts.measure_api_performance
    python -m scripts.measure_api_performance --tekrar 50 --rapor ../docs/w4-t13-performans.md
    python -m scripts.measure_api_performance --gorme --fotolar tests/fixtures/vision/images

Ne yapar:
  1) Uclari SUREC ICINDE (TestClient) N kez cagirir; p50/p95/p99 ve istek
     basina SORGU SAYISI toplar. Sorgu sayisi X-Query-Count basligindan
     gelir (app/core/timing.py). Sayinin sabit kalmasi N+1 olmadiginin kaniti.
  2) Kritik SQL'leri EXPLAIN QUERY PLAN ile suzer: 'SCAN' goruyorsan indeks
     kullanilmiyor, 'SEARCH ... USING INDEX' goruyorsan kullaniliyor.
  3) Gorsel on islemeyi olcer: ham KB -> gonderilen KB, sikistirma suresi.
  4) Gorme modeli gecikmesini vision_requests tablosundan cikarir; --gorme
     ile CANLI da olcer (dikkat: gercek saglayicida bu PARA harcar).

Kabul kriteri: deste ucu p95 < 800 ms, gorme modeli ucu p95 < 6000 ms.
Karsilanmazsa cikis kodu 1.

OLCUM SINIRI: TestClient surec icidir; uvicorn ve ag gecikmesi DAHIL DEGIL.
Yani gercek p95 buradakinden bir miktar yuksek olur; butceyi ona gore oku.
"""
from __future__ import annotations

import argparse
import sys
from datetime import date, datetime, timedelta, timezone
from math import ceil
from pathlib import Path
from statistics import mean
from time import perf_counter

from fastapi.testclient import TestClient
from sqlalchemy import func, select, text

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import User, VisionRequest
from app.models.recipe import RecipeFeedback, SwipeSession
from app.services.vision import prepare_image
from app.models import Ingredient, MealLog, PantryItem, ShoppingListItem
from app.models.enums import LogSource, MealType, PantrySource, ShoppingSource

ONEK = settings.API_V1_PREFIX
KOK = Path(__file__).resolve().parent.parent

# Kabul kriterleri (sprint plani W4-T13)
HEDEF_DESTE_MS = 800
HEDEF_GORME_MS = 6000

TEST_EPOSTA = "perf_test@example.com"


# ==================================================================
# Istatistik
# ==================================================================
def yuzdelik(degerler: list[float], p: float) -> float:
    """En yakin sira (nearest-rank) yontemi.

    Kucuk orneklemde dogrusu budur: 30 olcumun p95'i sirali listenin
    29. degeridir. Ara deger uydurmak (lineer interpolasyon) az sayida
    olcumde gercekte gorulmemis bir sure raporlar.
    """
    if not degerler:
        return 0.0
    sirali = sorted(degerler)
    k = max(0, min(len(sirali) - 1, ceil(p / 100 * len(sirali)) - 1))
    return sirali[k]


def ozetle(ad: str, sureler: list[float], sorgular: list[int]) -> dict:
    return {
        "ad": ad,
        "n": len(sureler),
        "p50": round(yuzdelik(sureler, 50), 1),
        "p95": round(yuzdelik(sureler, 95), 1),
        "p99": round(yuzdelik(sureler, 99), 1),
        "ort": round(mean(sureler), 1) if sureler else 0.0,
        "en_yuksek": round(max(sureler), 1) if sureler else 0.0,
        "sorgu_min": min(sorgular) if sorgular else 0,
        "sorgu_max": max(sorgular) if sorgular else 0,
    }


# ==================================================================
# Hazirlik
# ==================================================================
def test_kullanicisi(db) -> User:
    k = db.scalar(select(User).where(User.email == TEST_EPOSTA))
    if k is None:
        k = User(email=TEST_EPOSTA, hashed_password=hash_password("Perf1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def temizle(db, user: User) -> None:
    """Olcum kullanicisinin swipe gecmisini siler.

    SART: 'gordu' kayitlari birikirse eleme kumesi buyur, deste sorgusu
    her kosuda farkli maliyet cikarir - olcum karsilastirilamaz olur.
    """
    db.query(RecipeFeedback).filter(RecipeFeedback.user_id == user.id).delete()
    db.query(SwipeSession).filter(SwipeSession.user_id == user.id).delete()
    db.commit()


def olc(istemci: TestClient, ad: str, yol: str, tekrar: int, **kw) -> dict | None:
    """Bir ucu isitma turundan sonra `tekrar` kez cagirir."""
    ilk = istemci.get(yol, **kw)
    if ilk.status_code != 200:
        print(f"  [ATLA ] {ad}: HTTP {ilk.status_code} {ilk.text[:120]}")
        return None

    sureler, sorgular = [], []
    for _ in range(tekrar):
        basla = perf_counter()
        y = istemci.get(yol, **kw)
        gecen = (perf_counter() - basla) * 1000
        if y.status_code != 200:
            continue
        # Sunucunun kendi olctugu sure varsa onu tercih et: TestClient'in
        # serilestirme payini disarida birakir.
        sureler.append(float(y.headers.get("X-Process-Time-Ms", gecen)))
        sorgular.append(int(y.headers.get("X-Query-Count", 0)))

    o = ozetle(ad, sureler, sorgular)
    print(f"  {ad:<34} p50={o['p50']:>7.1f} p95={o['p95']:>7.1f} "
          f"p99={o['p99']:>7.1f} ms | sorgu {o['sorgu_min']}-{o['sorgu_max']}")
    return o


# ==================================================================
# 2) Indeks kullanimi
# ==================================================================
EXPLAIN_SORGULARI = {
    "kiler listesi (user_id + availability)":
        "SELECT * FROM pantry_items WHERE user_id = 1 "
        "AND availability != 'bitti' ORDER BY updated_at DESC",
    "kiler tekil (user_id + ingredient_id)":
        "SELECT * FROM pantry_items WHERE user_id = 1 AND ingredient_id = 1",
    "malzeme sozlugu (canonical_name)":
        "SELECT * FROM ingredients WHERE canonical_name = 'kirmizi_mercimek'",
    "alisveris listesi (user_id + created_at)":
        "SELECT * FROM shopping_list_items WHERE user_id = 1 "
        "ORDER BY created_at DESC",
    "yapacaklarim (user_id + action + created_at)":
        "SELECT recipe_id FROM recipe_feedback WHERE user_id = 1 "
        "AND action = 'yapacagim' AND created_at > '2026-01-01'",
    "kalici eleme (user_id + reason)":
        "SELECT recipe_id FROM recipe_feedback WHERE user_id = 1 "
        "AND reason = 'sevmedim'",
    "gunluk ogun ozeti (user_id + logged_date)":
        "SELECT * FROM meal_logs WHERE user_id = 1 AND logged_date = '2026-08-26'",
}


def indeksleri_denetle(db) -> list[dict]:
    print("\n2) Indeks kullanimi (EXPLAIN QUERY PLAN)")
    sonuc = []
    for ad, sql in EXPLAIN_SORGULARI.items():
        plan = [r[3] for r in db.execute(text(f"EXPLAIN QUERY PLAN {sql}"))]
        metin = " / ".join(plan)
        # 'SCAN' = tam tablo taramasi. Kucuk tabloda zararsiz olabilir ama
        # kullanici sayisi arttikca once burasi coker.
        tarama = any(p.strip().startswith("SCAN") for p in plan)
        durum = "TARAMA" if tarama else "INDEKS"
        print(f"  [{durum}] {ad}\n           {metin}")
        sonuc.append({"ad": ad, "plan": metin, "tarama": tarama})
    return sonuc


# ==================================================================
# 3) Gorsel on isleme
# ==================================================================
def gorselleri_olc(dizin: Path) -> dict:
    fotolar = [p for p in sorted(dizin.glob("*"))
               if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}]
    if not fotolar:
        print(f"\n3) Gorsel on isleme: {dizin} bos, atlandi.")
        return {}

    print(f"\n3) Gorsel on isleme ({len(fotolar)} fotograf)")
    ham, islenmis, sureler = [], [], []
    for yol in fotolar:
        veri = yol.read_bytes()
        basla = perf_counter()
        cikti, _ = prepare_image(veri)
        sureler.append((perf_counter() - basla) * 1000)
        ham.append(len(veri))
        islenmis.append(len(cikti))
        print(f"  {yol.name:<28} {len(veri)//1024:>5} KB -> "
              f"{len(cikti)//1024:>4} KB  ({sureler[-1]:.0f} ms)")

    return {
        "foto": len(fotolar),
        "ham_ort_kb": round(mean(ham) / 1024, 1),
        "islenmis_ort_kb": round(mean(islenmis) / 1024, 1),
        "kucultme_orani": round(sum(ham) / sum(islenmis), 2),
        "sikistirma_p95_ms": round(yuzdelik(sureler, 95), 1),
        "max_px": settings.VISION_MAX_IMAGE_PX,
        "kalite": settings.VISION_JPEG_QUALITY,
    }


# ==================================================================
# 4) Gorme modeli gecikmesi
# ==================================================================
def gorme_gecmisi(db, gun: int = 30) -> dict:
    """vision_requests tablosundan p95. Uretimdeki GERCEK cagrilar bunlar."""
    esik = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=gun)
    satirlar = db.scalars(
        select(VisionRequest).where(
            VisionRequest.success.is_(True),
            VisionRequest.latency_ms.isnot(None),
            VisionRequest.created_at > esik,
        )
    ).all()
    if not satirlar:
        print(f"\n4) Gorme modeli: son {gun} gunde kayit yok.")
        return {}

    sureler = [float(s.latency_ms) for s in satirlar]
    boyutlar = [s.image_bytes for s in satirlar if s.image_bytes]
    ozet = {
        "cagri": len(sureler),
        "p50": round(yuzdelik(sureler, 50), 1),
        "p95": round(yuzdelik(sureler, 95), 1),
        "p99": round(yuzdelik(sureler, 99), 1),
        "ort_gonderilen_kb": round(mean(boyutlar) / 1024, 1) if boyutlar else None,
        "saglayici": settings.VISION_PROVIDER,
        "model": settings.VISION_MODEL or "varsayilan",
    }
    print(f"\n4) Gorme modeli ({ozet['cagri']} gercek cagri, son {gun} gun)")
    print(f"   p50={ozet['p50']:.0f} ms  p95={ozet['p95']:.0f} ms  "
          f"p99={ozet['p99']:.0f} ms | ort gonderilen {ozet['ort_gonderilen_kb']} KB")
    return ozet


def gorme_canli(istemci: TestClient, dizin: Path, tekrar: int) -> dict | None:
    """Ucun KENDISINI olcer: on isleme + model + sozluk eslestirmesi."""
    fotolar = [p for p in sorted(dizin.glob("*"))
               if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}]
    if not fotolar:
        print("\n4b) Canli gorme olcumu: fotograf yok, atlandi.")
        return None
    if settings.VISION_PROVIDER == "fake":
        print("\n4b) [UYARI] VISION_PROVIDER='fake' - canli olcum ANLAMSIZ.")

    print(f"\n4b) Canli gorme olcumu ({len(fotolar)} foto x {tekrar})")
    sureler = []
    for yol in fotolar:
        veri = yol.read_bytes()
        for _ in range(tekrar):
            basla = perf_counter()
            y = istemci.post(
                f"{ONEK}/vision/ingredients",
                files={"file": (yol.name, veri, "image/jpeg")},
            )
            gecen = (perf_counter() - basla) * 1000
            if y.status_code == 200:
                sureler.append(gecen)
            else:
                print(f"  [HATA ] {yol.name}: HTTP {y.status_code} {y.text[:100]}")
    if not sureler:
        return None
    o = ozetle("POST /vision/ingredients", sureler, [])
    print(f"  p50={o['p50']:.0f} ms  p95={o['p95']:.0f} ms  p99={o['p99']:.0f} ms")
    return o


# ==================================================================
# Rapor
# ==================================================================
def rapor_yaz(yol: Path, uclar, planlar, gorsel, gorme, gorme_uc, tekrar) -> None:
    s = ["# API Performansı ve İndeksleme (W4-T13)\n"]
    s.append(f"**Tarih:** {date.today().isoformat()} &nbsp;|&nbsp; "
             f"**Tekrar:** {tekrar} &nbsp;|&nbsp; "
             f"**Ölçüm:** süreç içi (TestClient) — ağ ve uvicorn payı hariç\n")

    deste = next((u for u in uclar if u and "deck" in u["ad"]), None)
    if deste:
        gecti = "GEÇTİ" if deste["p95"] < HEDEF_DESTE_MS else "KALDI"
        s.append(f"\n**Kabul kriteri 1 — deste ucu p95 < {HEDEF_DESTE_MS} ms: "
                 f"{gecti} ({deste['p95']:.1f} ms)**\n")
    if gorme:
        gecti = "GEÇTİ" if gorme["p95"] < HEDEF_GORME_MS else "KALDI"
        s.append(f"**Kabul kriteri 2 — görme modeli p95 < {HEDEF_GORME_MS/1000:.0f} sn: "
                 f"{gecti} ({gorme['p95']/1000:.2f} sn)**\n")

    s.append("\n## 1. Uç gecikmeleri\n")
    s.append("| Uç | n | p50 (ms) | p95 (ms) | p99 (ms) | En yüksek | Sorgu (min–maks) |")
    s.append("|---|---|---|---|---|---|---|")
    for u in uclar:
        if not u:
            continue
        s.append(f"| `{u['ad']}` | {u['n']} | {u['p50']} | **{u['p95']}** | "
                 f"{u['p99']} | {u['en_yuksek']} | {u['sorgu_min']}–{u['sorgu_max']} |")
    s.append("\nSorgu sayısı sütunu N+1 göstergesidir: veri büyürken bu sayı "
             "sabit kalmalı. Artıyorsa ilgili serviste `joinedload` eksik demektir.\n")

    s.append("\n## 2. İndeks kullanımı (EXPLAIN QUERY PLAN)\n")
    s.append("| Sorgu | Plan | Durum |\n|---|---|---|")
    for p in planlar:
        s.append(f"| {p['ad']} | `{p['plan']}` | "
                 f"{'⚠️ tam tarama' if p['tarama'] else '✅ indeks'} |")

    if gorsel:
        s.append("\n## 3. Görsel yükleme boyutu\n")
        s.append(f"`VISION_MAX_IMAGE_PX={gorsel['max_px']}`, "
                 f"`VISION_JPEG_QUALITY={gorsel['kalite']}`\n")
        s.append("| Ölçüm | Değer |\n|---|---|")
        s.append(f"| Fotoğraf | {gorsel['foto']} |")
        s.append(f"| Ortalama ham boyut | {gorsel['ham_ort_kb']} KB |")
        s.append(f"| Ortalama gönderilen boyut | {gorsel['islenmis_ort_kb']} KB |")
        s.append(f"| Küçültme oranı | {gorsel['kucultme_orani']}× |")
        s.append(f"| Sıkıştırma p95 | {gorsel['sikistirma_p95_ms']} ms |")

    if gorme:
        s.append("\n## 4. Görme modeli yanıt süresi\n")
        s.append(f"Kaynak: `vision_requests` tablosu, sağlayıcı "
                 f"`{gorme['saglayici']}`, model `{gorme['model']}`.\n")
        s.append("| Ölçüm | Değer |\n|---|---|")
        s.append(f"| Başarılı çağrı | {gorme['cagri']} |")
        s.append(f"| p50 | {gorme['p50']:.0f} ms |")
        s.append(f"| **p95** | **{gorme['p95']:.0f} ms** |")
        s.append(f"| p99 | {gorme['p99']:.0f} ms |")
        s.append(f"| Ortalama gönderilen görsel | {gorme['ort_gonderilen_kb']} KB |")
    if gorme_uc:
        s.append(f"\nUcun tamamı (ön işleme + model + eşleştirme): "
                 f"p95 **{gorme_uc['p95']:.0f} ms**.\n")

    s.append("\n## Bilinen sınırlar\n")
    s.append("- Skorlama pipeline'ındaki `max_total_minutes` filtresi `$expr` "
             "kullanır ve **indeks kullanamaz**. Tarif sayısı yüz binlere "
             "çıkarsa dokümana `total_time` alanı eklenip indekslenmeli.\n")
    s.append("- Ölçüm süreç içidir; ağ gecikmesi ve uvicorn payı dahil değildir.\n")

    s.append("\n## Tekrar üretme\n")
    s.append("```bash\ncd backend && python -m scripts.measure_api_performance "
             "--rapor ../docs/w4-t13-performans.md\n```\n")

    yol.parent.mkdir(parents=True, exist_ok=True)
    yol.write_text("\n".join(s), encoding="utf-8")
    print(f"\n  Rapor yazildi: {yol}")

def veri_hazirla(db, user: User, *, kiler: int = 30, alisveris: int = 20, ogun: int = 8) -> dict:
    """Olcum kullanicisina GERCEKCI hacimde veri yazar.

    NEDEN SART: bos hesapta /pantry sifir satir doner ve tek sorguda biter -
    joinedload olsa da olmasa da 1. N+1 duzeltmesinin kaniti, satir sayisi
    artarken sorgu sayisinin SABIT kalmasidir. Bos hesapta olcum, hicbir sey
    kanitlamayan bir sayi uretir.
    """
    malzemeler = list(db.scalars(select(Ingredient).order_by(Ingredient.id).limit(kiler)))

    for m in malzemeler:
        kayit = db.scalar(select(PantryItem).where(
            PantryItem.user_id == user.id, PantryItem.ingredient_id == m.id))
        if kayit is None:
            kayit = PantryItem(user_id=user.id, ingredient_id=m.id)
            db.add(kayit)
        kayit.confirm(PantrySource.MANUEL)

    for m in malzemeler[:alisveris]:
        varmi = db.scalar(select(ShoppingListItem).where(
            ShoppingListItem.user_id == user.id, ShoppingListItem.ingredient_id == m.id))
        if varmi is None:
            db.add(ShoppingListItem(user_id=user.id, ingredient_id=m.id,
                                    source=ShoppingSource.MANUEL))

    bugun = date.today()
    mevcut = db.scalar(select(func.count()).select_from(MealLog).where(
        MealLog.user_id == user.id, MealLog.logged_date == bugun))
    for i in range(max(0, ogun - (mevcut or 0))):
        m = malzemeler[i % len(malzemeler)]
        db.add(MealLog(
            user_id=user.id, logged_date=bugun,
            meal_type=list(MealType)[i % 4], source=LogSource.MANUEL,
            ingredient_id=m.id, item_name=m.display_name,
            servings=1, quantity_g=150,
            calories=(m.calories_per_100g or 100) * 1.5,
            protein_g=10, carb_g=20, fat_g=5, fiber_g=3,
        ))

    db.commit()
    print(f"  Olcum verisi: kiler={len(malzemeler)} alisveris={alisveris} ogun={ogun}")
    return {"kiler": len(malzemeler), "alisveris": alisveris, "ogun": ogun}


# ==================================================================
def main() -> None:
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument("--tekrar", type=int, default=30)
    a.add_argument("--fotolar", default=str(KOK / "tests" / "fixtures" / "vision" / "images"))
    a.add_argument("--gorme", action="store_true",
                   help="Gorme ucunu CANLI olc (gercek saglayicida PARA harcar)")
    a.add_argument("--gorme-tekrar", type=int, default=3)
    a.add_argument("--rapor", help="Markdown rapor cikti yolu")
    args = a.parse_args()

    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)
    veri_hazirla(db, kullanici)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici

    uclar, gorme_uc = [], None
    # 'with': /deck ve /cards Mongo'ya baglanmak zorunda, lifespan sart.
    with TestClient(app) as istemci:
        print(f"\n1) Uc gecikmeleri ({args.tekrar} tekrar, isitma turu haric)")
        deste = olc(istemci, "GET /recipes/deck", f"{ONEK}/recipes/deck",
                    args.tekrar, params={"limit": 10})
        uclar.append(deste)
        uclar.append(olc(istemci, "GET /pantry", f"{ONEK}/pantry", args.tekrar))
        uclar.append(olc(istemci, "GET /shopping", f"{ONEK}/shopping", args.tekrar))
        uclar.append(olc(istemci, "GET /meals/daily", f"{ONEK}/meals/daily", args.tekrar))
        uclar.append(olc(istemci, "GET /catalog/ingredients",
                         f"{ONEK}/catalog/ingredients", args.tekrar))

        # Kart ucu icin gercek kimlik lazim; desteden aliyoruz.
        y = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 10})
        if y.status_code == 200 and y.json()["items"]:
            kimlikler = [k["id"] for k in y.json()["items"]]
            uclar.append(olc(istemci, "GET /recipes/cards", f"{ONEK}/recipes/cards",
                             args.tekrar, params={"ids": ",".join(kimlikler)}))
            uclar.append(olc(istemci, "GET /recipes/{id}",
                             f"{ONEK}/recipes/{kimlikler[0]}", args.tekrar))

        planlar = indeksleri_denetle(db)
        gorsel = gorselleri_olc(Path(args.fotolar))
        gorme = gorme_gecmisi(db)
        if args.gorme:
            gorme_uc = gorme_canli(istemci, Path(args.fotolar), args.gorme_tekrar)

    temizle(db, kullanici)
    db.close()

    if args.rapor:
        rapor_yaz(Path(args.rapor), uclar, planlar, gorsel, gorme, gorme_uc, args.tekrar)

    print(f"\n{'=' * 70}")
    kaldi = False
    if deste:
        durum = "GECTI" if deste["p95"] < HEDEF_DESTE_MS else "KALDI"
        kaldi |= deste["p95"] >= HEDEF_DESTE_MS
        print(f"DESTE p95 = {deste['p95']:.1f} ms  (hedef < {HEDEF_DESTE_MS}) -> {durum}")
    if gorme:
        durum = "GECTI" if gorme["p95"] < HEDEF_GORME_MS else "KALDI"
        kaldi |= gorme["p95"] >= HEDEF_GORME_MS
        print(f"GORME p95 = {gorme['p95']:.0f} ms  (hedef < {HEDEF_GORME_MS}) -> {durum}")
    if any(p["tarama"] for p in planlar):
        print("[UYARI] Bazi sorgular tam tablo taramasi yapiyor, tabloya bak.")

    sys.exit(1 if kaldi else 0)


if __name__ == "__main__":
    main()