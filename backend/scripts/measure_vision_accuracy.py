"""W4-T11 olcumu: gorme modeli dogruluk olcumu (precision / recall).

    python -m scripts.measure_vision_accuracy
    python -m scripts.measure_vision_accuracy --only malzeme --etiket v2 \
            --prompt prompts/ingredient_v2.txt
    python -m scripts.measure_vision_accuracy --rapor ../docs/vision_accuracy.md

Ne yapar:
  1) tests/fixtures/vision/ground_truth.json'daki fotograflari URETIM
     akisindan gecirir (detect_ingredients / estimate_meal). Guven esigi ve
     madde tavani dahil; kullanicinin gercekte gordugu cikti olculur.
  2) Beklenen ve bulunan KANONIK adlari karsilastirip foto basina ve genel
     precision / recall / F1 uretir.
  3) En cok kacirilan, en cok uydurulan ve sozlukte karsiligi olmayan
     ciktilari listeler - prompt iyilestirmesi bu listelerden beslenir.
  4) --rapor ile docs/vision_accuracy.md dosyasini uretir.

MODEL CAGRISI PARALIDIR. Yanitlar .vision_cache/ altinda onbelleklenir;
ayni foto + ayni prompt ikinci kez modele GITMEZ. Zorlamak icin --no-cache.

Kabul kriteri: malzeme tanima recall'u >= %70. Altindaysa cikis kodu 1.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time
from collections import Counter
from datetime import date
from hashlib import sha256
from pathlib import Path
from statistics import mean

from rapidfuzz import fuzz

from app.core.config import settings
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo
from app.db.session import SessionLocal
from app.services import meal_estimation, vision_ingredients
from app.services.ingredient_matcher import get_lookup
from app.services.unit_service import normalize_text
from app.services.vision import (
    VisionProvider, VisionResult, VisionUsage, get_vision_provider,
)

KOK = Path(__file__).resolve().parent.parent
VARSAYILAN_SET = KOK / "tests" / "fixtures" / "vision" / "ground_truth.json"
VARSAYILAN_FOTO = KOK / "tests" / "fixtures" / "vision" / "images"
ONBELLEK = KOK / ".vision_cache"

# Kabul kriteri esigi.
HEDEF_RECALL = 0.70

# Yemek adi bulanik eslesme esigi. ingredient_matcher ile ayni deger
# kullaniliyor; iki yerde farkli esik tutmak kafa karistirir.
YEMEK_FUZZY_ESIK = 85


# ==================================================================
# Onbellek: ayni foto + ayni prompt ikinci kez modele gitmesin
# ==================================================================
class OnbellekliSaglayici(VisionProvider):
    """Gercek saglayicinin onune gecen seffaf onbellek katmani.

    Ham model yanitini saklar; boylece esleme veya metrik kodu degisince
    olcum tekrar kosulabilir ama model tekrar CAGRILMAZ.
    """

    def __init__(self, ic: VisionProvider, dizin: Path, aktif: bool = True):
        self._ic = ic
        self._dizin = dizin
        self._aktif = aktif
        self.name = ic.name
        self.isabet = 0
        self.cagri = 0
        dizin.mkdir(parents=True, exist_ok=True)

    def _yol(self, image_bytes: bytes, prompt: str) -> Path:
        anahtar = sha256(
            image_bytes
            + prompt.encode("utf-8")
            + self._ic.name.encode("utf-8")
            + (settings.VISION_MODEL or "").encode("utf-8")
        ).hexdigest()[:32]
        return self._dizin / f"{anahtar}.json"

    async def analyze(self, image_bytes: bytes, prompt: str) -> VisionResult:
        yol = self._yol(image_bytes, prompt)
        if self._aktif and yol.exists():
            kayit = json.loads(yol.read_text(encoding="utf-8"))
            self.isabet += 1
            return VisionResult(
                data=kayit["data"],
                raw_text=kayit["raw_text"],
                usage=VisionUsage(**kayit["usage"]),
            )

        sonuc = await self._ic.analyze(image_bytes, prompt)
        self.cagri += 1
        yol.write_text(json.dumps({
            "data": sonuc.data,
            "raw_text": sonuc.raw_text,
            "usage": {
                "provider": sonuc.usage.provider,
                "model": sonuc.usage.model,
                "prompt_tokens": sonuc.usage.prompt_tokens,
                "completion_tokens": sonuc.usage.completion_tokens,
                "latency_ms": sonuc.usage.latency_ms,
                "image_bytes": sonuc.usage.image_bytes,
            },
        }, ensure_ascii=False), encoding="utf-8")
        return sonuc


def saglayiciyi_degistir(saglayici: VisionProvider) -> None:
    """Iki servis modulunun get_vision_provider adini onbellekliye baglar.

    Her iki modul de fonksiyonu KENDI ad alanina import ediyor
    (`from app.services.vision import get_vision_provider`), bu yuzden
    paketteki tanimi degistirmek yetmez; modul niteligi yamanmali.
    """
    vision_ingredients.get_vision_provider = lambda: saglayici
    meal_estimation.get_vision_provider = lambda: saglayici


# ==================================================================
# Test setini yukleme ve dogrulama
# ==================================================================
def seti_yukle(yol: Path, foto_dizin: Path, tur: str) -> list[dict]:
    if not yol.exists():
        sys.exit(f"Test seti bulunamadi: {yol}")

    ham = json.loads(yol.read_text(encoding="utf-8"))
    kayitlar = []
    for anahtar, deger in ham.items():
        if anahtar.startswith("_"):          # _aciklama gibi alanlar
            continue
        if tur != "hepsi" and deger.get("type") != tur:
            continue
        deger = dict(deger, id=anahtar)
        deger["yol"] = foto_dizin / deger["file"]
        if not deger["yol"].exists():
            print(f"  [ATLA ] {anahtar}: fotograf yok -> {deger['yol']}")
            continue
        kayitlar.append(deger)
    return kayitlar


def beklenenleri_dogrula(db, kayitlar: list[dict]) -> list[str]:
    """Beklenen kanonik adlar sozlukte var mi?

    Bu kontrol olmadan olcum sessizce yalan soyler: sozlukte olmayan bir
    ada recall asla ulasilamaz, ama tabloda 'model kacirdi' gibi gorunur.
    """
    sozluk = set(get_lookup(db).display)
    eksik = []
    for k in kayitlar:
        for ad in list(k.get("expected", [])) + list(k.get("optional", [])):
            if ad not in sozluk:
                eksik.append(f"{k['id']}: {ad}")
    return eksik


# ==================================================================
# Metrikler
# ==================================================================
def foto_metrigi(beklenen: set[str], opsiyonel: set[str], bulunan: set[str]) -> dict:
    dogru = beklenen & bulunan
    kacirilan = beklenen - bulunan
    # Opsiyoneller ne odul ne ceza: yanlis pozitif sayilmaz.
    uydurulan = bulunan - beklenen - opsiyonel

    tp, fp, fn = len(dogru), len(uydurulan), len(kacirilan)
    return {
        "tp": tp, "fp": fp, "fn": fn,
        "precision": tp / (tp + fp) if tp + fp else 0.0,
        "recall": tp / (tp + fn) if tp + fn else 0.0,
        "dogru": sorted(dogru),
        "kacirilan": sorted(kacirilan),
        "uydurulan": sorted(uydurulan),
    }


def f1(p: float, r: float) -> float:
    return 2 * p * r / (p + r) if p + r else 0.0


def yemek_metrigi(kayit: dict, tahmin: dict) -> dict:
    """Yemek adi top-1 dogrulugu ve gram sapmasi."""
    bulunan = normalize_text(tahmin["dish_name"])
    adaylar = [kayit["expected_dish"], *kayit.get("expected_aliases", [])]
    adaylar_n = [normalize_text(a) for a in adaylar]

    if bulunan in adaylar_n:
        isabet = "tam"
    elif max((fuzz.token_set_ratio(bulunan, a) for a in adaylar_n), default=0) >= YEMEK_FUZZY_ESIK:
        isabet = "bulanik"
    else:
        isabet = "yok"

    beklenen_gram = kayit.get("expected_grams")
    tolerans = kayit.get("gram_tolerance", 0.35)
    gram_sapma = gram_ic = None
    if beklenen_gram:
        gram_sapma = abs(tahmin["estimated_grams"] - beklenen_gram)
        gram_ic = gram_sapma <= beklenen_gram * tolerans

    return {
        "isabet": isabet,
        "bulunan": tahmin["dish_name"],
        "beklenen": kayit["expected_dish"],
        "gram_tahmin": tahmin["estimated_grams"],
        "gram_beklenen": beklenen_gram,
        "gram_sapma": gram_sapma,
        "gram_tolerans_icinde": gram_ic,
        "kalori": tahmin.get("calories"),
        "kalori_kaynak": tahmin.get("match_source"),
    }


# ==================================================================
# Kosum
# ==================================================================
async def malzeme_kos(db, kayitlar: list[dict]) -> list[dict]:
    sonuclar = []
    for k in kayitlar:
        ham = k["yol"].read_bytes()
        try:
            # user_id=None: kota kontrolu atlanir, olcum kotayi yemez.
            cikti = await vision_ingredients.detect_ingredients(
                db, raw_image=ham, user_id=None
            )
        except Exception as exc:                              # noqa: BLE001
            print(f"  [HATA ] {k['id']}: {type(exc).__name__}: {exc}")
            sonuclar.append({**k, "hata": str(exc), "metrik": None})
            continue

        bulunan = {i.canonical_name for i in cikti.items if i.canonical_name}
        eslesmeyen = [i.raw_name for i in cikti.items if not i.canonical_name]
        metrik = foto_metrigi(
            set(k.get("expected", [])), set(k.get("optional", [])), bulunan
        )
        sonuclar.append({
            **k, "hata": None, "metrik": metrik,
            "bulunan": sorted(bulunan), "sozlukte_yok": eslesmeyen,
        })
        print(f"  {k['id']:<12} P={metrik['precision']:.2f} R={metrik['recall']:.2f} "
              f"(+{metrik['tp']} -{metrik['fn']} !{metrik['fp']})")
    return sonuclar


async def ogun_kos(db, mongo_db, kayitlar: list[dict]) -> list[dict]:
    sonuclar = []
    for k in kayitlar:
        ham = k["yol"].read_bytes()
        try:
            tahmin = await meal_estimation.estimate_meal(
                db, mongo_db, raw_image=ham, user_id=None
            )
        except Exception as exc:                              # noqa: BLE001
            print(f"  [HATA ] {k['id']}: {type(exc).__name__}: {exc}")
            sonuclar.append({**k, "hata": str(exc), "metrik": None})
            continue

        metrik = yemek_metrigi(k, tahmin)
        sonuclar.append({**k, "hata": None, "metrik": metrik})
        gram = (f"{metrik['gram_sapma']:.0f}g sapma"
                if metrik["gram_sapma"] is not None else "-")
        print(f"  {k['id']:<12} {metrik['isabet']:<8} "
              f"'{metrik['bulunan'][:28]}' | {gram}")
    return sonuclar


# ==================================================================
# Ozet
# ==================================================================
def malzeme_ozeti(sonuclar: list[dict]) -> dict:
    gecerli = [s for s in sonuclar if s["metrik"]]
    if not gecerli:
        return {}

    tp = sum(s["metrik"]["tp"] for s in gecerli)
    fp = sum(s["metrik"]["fp"] for s in gecerli)
    fn = sum(s["metrik"]["fn"] for s in gecerli)

    # Mikro ortalama asil sayidir: her malzeme esit agirlikta.
    # Makro ortalama her FOTOGRAFI esit agirlikta sayar; az malzemeli bir
    # fotograf mikro'da az, makro'da cok soz sahibi olur. Ikisi de raporda.
    mikro_p = tp / (tp + fp) if tp + fp else 0.0
    mikro_r = tp / (tp + fn) if tp + fn else 0.0

    return {
        "foto": len(gecerli),
        "hatali_foto": len(sonuclar) - len(gecerli),
        "tp": tp, "fp": fp, "fn": fn,
        "mikro_precision": round(mikro_p, 4),
        "mikro_recall": round(mikro_r, 4),
        "mikro_f1": round(f1(mikro_p, mikro_r), 4),
        "makro_precision": round(mean(s["metrik"]["precision"] for s in gecerli), 4),
        "makro_recall": round(mean(s["metrik"]["recall"] for s in gecerli), 4),
        "en_cok_kacirilan": Counter(
            a for s in gecerli for a in s["metrik"]["kacirilan"]
        ).most_common(10),
        "en_cok_uydurulan": Counter(
            a for s in gecerli for a in s["metrik"]["uydurulan"]
        ).most_common(10),
        "sozlukte_yok": Counter(
            a for s in gecerli for a in s["sozlukte_yok"]
        ).most_common(15),
    }


def ogun_ozeti(sonuclar: list[dict]) -> dict:
    gecerli = [s for s in sonuclar if s["metrik"]]
    if not gecerli:
        return {}

    tam = sum(1 for s in gecerli if s["metrik"]["isabet"] == "tam")
    bulanik = sum(1 for s in gecerli if s["metrik"]["isabet"] == "bulanik")
    sapmalar = [s["metrik"]["gram_sapma"] for s in gecerli
                if s["metrik"]["gram_sapma"] is not None]
    tolerans_ici = [s["metrik"]["gram_tolerans_icinde"] for s in gecerli
                    if s["metrik"]["gram_tolerans_icinde"] is not None]

    return {
        "foto": len(gecerli),
        "hatali_foto": len(sonuclar) - len(gecerli),
        "tam_isabet": tam,
        "bulanik_isabet": bulanik,
        "top1_dogruluk": round((tam + bulanik) / len(gecerli), 4),
        "tam_dogruluk": round(tam / len(gecerli), 4),
        "gram_mae": round(mean(sapmalar), 1) if sapmalar else None,
        "gram_tolerans_orani": (
            round(sum(tolerans_ici) / len(tolerans_ici), 4) if tolerans_ici else None
        ),
        "kalori_bulunan": sum(1 for s in gecerli if s["metrik"]["kalori"] is not None),
    }


# ==================================================================
# Rapor
# ==================================================================
def rapor_yaz(yol: Path, etiket: str, m_ozet: dict, o_ozet: dict,
              m_sonuc: list[dict], o_sonuc: list[dict], saglayici_adi: str) -> None:
    s = []
    s.append("# Görme Modeli Doğruluk Ölçümü (W4-T11)\n")
    s.append(f"**Koşu:** `{etiket}` &nbsp;|&nbsp; **Tarih:** {date.today().isoformat()} "
             f"&nbsp;|&nbsp; **Sağlayıcı:** `{saglayici_adi}` "
             f"&nbsp;|&nbsp; **Model:** `{settings.VISION_MODEL or 'varsayılan'}`\n")
    s.append(f"Güven eşiği `VISION_MIN_CONFIDENCE={settings.VISION_MIN_CONFIDENCE}`, "
             f"madde tavanı `VISION_MAX_ITEMS={settings.VISION_MAX_ITEMS}`. "
             "Ölçüm üretim akışının kendisinden geçer.\n")

    if m_ozet:
        gecti = "GEÇTİ" if m_ozet["mikro_recall"] >= HEDEF_RECALL else "KALDI"
        s.append("\n## Malzeme tanıma\n")
        s.append(f"**Kabul kriteri (recall ≥ %{HEDEF_RECALL*100:.0f}): "
                 f"{gecti} — %{m_ozet['mikro_recall']*100:.1f}**\n")
        s.append("| Ölçüm | Değer |\n|---|---|")
        s.append(f"| Fotoğraf | {m_ozet['foto']} |")
        s.append(f"| Doğru (TP) / Uydurulan (FP) / Kaçırılan (FN) | "
                 f"{m_ozet['tp']} / {m_ozet['fp']} / {m_ozet['fn']} |")
        s.append(f"| **Mikro recall** | **{m_ozet['mikro_recall']:.4f}** |")
        s.append(f"| Mikro precision | {m_ozet['mikro_precision']:.4f} |")
        s.append(f"| Mikro F1 | {m_ozet['mikro_f1']:.4f} |")
        s.append(f"| Makro recall / precision | "
                 f"{m_ozet['makro_recall']:.4f} / {m_ozet['makro_precision']:.4f} |")

        s.append("\n### Fotoğraf bazında\n")
        s.append("| Foto | P | R | Doğru | Kaçırılan | Uydurulan |\n|---|---|---|---|---|---|")
        for r in m_sonuc:
            if not r["metrik"]:
                s.append(f"| {r['id']} | - | - | HATA | {r['hata'][:60]} | |")
                continue
            mk = r["metrik"]
            s.append(f"| {r['id']} | {mk['precision']:.2f} | {mk['recall']:.2f} | "
                     f"{mk['tp']} | {', '.join(mk['kacirilan']) or '-'} | "
                     f"{', '.join(mk['uydurulan']) or '-'} |")

        if m_ozet["en_cok_kacirilan"]:
            s.append("\n### En çok kaçırılanlar (prompt iyileştirmesi buradan başlar)\n")
            for ad, n in m_ozet["en_cok_kacirilan"]:
                s.append(f"- `{ad}` — {n} fotoğrafta kaçırıldı")
        if m_ozet["en_cok_uydurulan"]:
            s.append("\n### En çok uydurulanlar\n")
            for ad, n in m_ozet["en_cok_uydurulan"]:
                s.append(f"- `{ad}` — {n} fotoğrafta yanlış bulundu")
        if m_ozet["sozlukte_yok"]:
            s.append("\n### Sözlükte karşılığı olmayan model çıktıları\n")
            s.append("Model gördü ama `ingredients` sözlüğü eşleyemedi. "
                     "Bunlar prompt sorunu değil, **sözlük eksiği**:\n")
            for ad, n in m_ozet["sozlukte_yok"]:
                s.append(f"- \"{ad}\" — {n} kez")

    if o_ozet:
        s.append("\n## Yemek tanıma (tabak)\n")
        s.append("| Ölçüm | Değer |\n|---|---|")
        s.append(f"| Fotoğraf | {o_ozet['foto']} |")
        s.append(f"| Top-1 doğruluk (tam + bulanık) | {o_ozet['top1_dogruluk']:.4f} |")
        s.append(f"| Tam isabet | {o_ozet['tam_isabet']} / {o_ozet['foto']} |")
        s.append(f"| Gram MAE | {o_ozet['gram_mae']} g |")
        s.append(f"| Gram toleransı içinde | {o_ozet['gram_tolerans_orani']} |")
        s.append(f"| Kalori kaynağı bulunan | {o_ozet['kalori_bulunan']} / {o_ozet['foto']} |")

        s.append("\n### Fotoğraf bazında\n")
        s.append("| Foto | İsabet | Bulunan | Beklenen | Gram (tahmin/gerçek) |"
                 "\n|---|---|---|---|---|")
        for r in o_sonuc:
            if not r["metrik"]:
                s.append(f"| {r['id']} | HATA | {r['hata'][:50]} | | |")
                continue
            mk = r["metrik"]
            s.append(f"| {r['id']} | {mk['isabet']} | {mk['bulunan']} | "
                     f"{mk['beklenen']} | {mk['gram_tahmin']:.0f} / "
                     f"{mk['gram_beklenen']} |")

    s.append("\n## Tekrar üretme\n")
    s.append("```bash\ncd backend && python -m scripts.measure_vision_accuracy "
             "--rapor ../docs/vision_accuracy.md\n```\n")
    s.append("Model yanıtları `.vision_cache/` altında önbelleklenir; "
             "yeniden koşmak ücretsizdir. Prompt değişince önbellek anahtarı "
             "da değişir, o yüzden `--no-cache` gerekmez.\n")

    yol.parent.mkdir(parents=True, exist_ok=True)
    yol.write_text("\n".join(s), encoding="utf-8")
    print(f"\n  Rapor yazildi: {yol}")


# ==================================================================
async def calistir(args) -> int:
    db = SessionLocal()
    mongo_db = None
    if args.only in ("ogun", "hepsi"):
        await connect_to_mongo()
        mongo_db = mongo.database if mongo.is_connected else None
        if mongo_db is None:
            print("  [UYARI] MongoDB yok; kalori cozumlemesi atlanacak.")

    # Prompt varyanti: modul duzeyindeki sabit gecici olarak degistirilir.
    # A/B icin en kucuk mudahale bu; uretim kodu prompt secimi bilmiyor.
    if args.prompt:
        yeni = Path(args.prompt).read_text(encoding="utf-8")
        vision_ingredients.INGREDIENT_PROMPT = yeni
        print(f"  Prompt degistirildi: {args.prompt} ({len(yeni)} karakter)")

    saglayici = OnbellekliSaglayici(
        get_vision_provider(), ONBELLEK, aktif=not args.no_cache
    )
    saglayiciyi_degistir(saglayici)
    if saglayici.is_fake:
        print("  [UYARI] VISION_PROVIDER='fake'. Olcum ANLAMSIZ - .env'de "
              "gercek saglayici ayarla.")

    m_sonuc = o_sonuc = []
    m_ozet = o_ozet = {}
    baslangic = time.time()

    try:
        if args.only in ("malzeme", "hepsi"):
            kayitlar = seti_yukle(Path(args.set), Path(args.images), "malzeme")
            eksik = beklenenleri_dogrula(db, kayitlar)
            if eksik:
                print("\n  [UYARI] Bu kanonik adlar sozlukte YOK; recall onlara "
                      "asla ulasamaz:")
                for e in eksik:
                    print(f"    - {e}")
            print(f"\n1) Malzeme tanima ({len(kayitlar)} fotograf)")
            m_sonuc = await malzeme_kos(db, kayitlar)
            m_ozet = malzeme_ozeti(m_sonuc)

        if args.only in ("ogun", "hepsi"):
            kayitlar = seti_yukle(Path(args.set), Path(args.images), "ogun")
            print(f"\n2) Yemek tanima ({len(kayitlar)} fotograf)")
            o_sonuc = await ogun_kos(db, mongo_db, kayitlar)
            o_ozet = ogun_ozeti(o_sonuc)
    finally:
        db.close()
        if mongo_db is not None:
            await close_mongo_connection()

    print(f"\n{'='*68}")
    print(f"Onbellek: {saglayici.isabet} isabet, {saglayici.cagri} gercek cagri "
          f"| sure {time.time()-baslangic:.1f} sn")

    if m_ozet:
        print(f"\nMALZEME  recall={m_ozet['mikro_recall']:.4f} "
              f"precision={m_ozet['mikro_precision']:.4f} f1={m_ozet['mikro_f1']:.4f}")
        print(f"         TP={m_ozet['tp']} FP={m_ozet['fp']} FN={m_ozet['fn']}")
    if o_ozet:
        print(f"YEMEK    top1={o_ozet['top1_dogruluk']:.4f} "
              f"gram_mae={o_ozet['gram_mae']}")

    if args.json:
        Path(args.json).write_text(json.dumps({
            "etiket": args.etiket, "malzeme": m_ozet, "ogun": o_ozet,
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  Ozet JSON: {args.json}")

    if args.rapor:
        rapor_yaz(Path(args.rapor), args.etiket, m_ozet, o_ozet,
                  m_sonuc, o_sonuc, saglayici.name)

    if m_ozet and m_ozet["mikro_recall"] < HEDEF_RECALL:
        print(f"\n[KALDI] Recall {m_ozet['mikro_recall']:.4f} < {HEDEF_RECALL} "
              "- prompt iyilestirmesi gerekiyor.")
        return 1
    print("\n[TAMAM] Kabul kriteri karsilandi.")
    return 0


def main() -> None:
    a = argparse.ArgumentParser(description=__doc__)
    a.add_argument("--set", default=str(VARSAYILAN_SET))
    a.add_argument("--images", default=str(VARSAYILAN_FOTO))
    a.add_argument("--only", choices=("malzeme", "ogun", "hepsi"), default="hepsi")
    a.add_argument("--prompt", help="INGREDIENT_PROMPT yerine kullanilacak dosya")
    a.add_argument("--etiket", default="v1", help="Rapora yazilacak kosu adi")
    a.add_argument("--rapor", help="Markdown rapor cikti yolu")
    a.add_argument("--json", help="Ozet metrikleri JSON olarak yaz")
    a.add_argument("--no-cache", action="store_true", help="Onbellegi yok say")
    sys.exit(asyncio.run(calistir(a.parse_args())))


if __name__ == "__main__":
    main()