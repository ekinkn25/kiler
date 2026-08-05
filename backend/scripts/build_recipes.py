"""Ham tarif JSON'larini isler: slug uretir, kaloriyi HESAPLAR, dogrular.

Kullanim (backend/ klasorunde):  python -m scripts.build_recipes

Girdi : ../data/raw_recipes/*.json  + ../data/ingredients_seed.json
Cikti : ../data/recipes_seed.json   + ../data/unmatched_report.txt
"""
import json
import re
import unicodedata
from collections import Counter
from pathlib import Path

from pydantic import ValidationError

from app.schemas import RecipeCreate
from app.services.unit_service import UnitConversionError, to_grams

BASE = Path(__file__).resolve().parents[2] / "data"
HAM_KLASOR = BASE / "raw_recipes"
MALZEME_DOSYA = BASE / "ingredients_seed.json"
CIKTI = BASE / "recipes_seed.json"
RAPOR = BASE / "unmatched_report.txt"

TR_HARF = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")


def slugify(metin: str) -> str:
    """Turkce karakterleri ASCII'ye cevirip URL dostu slug uretir.

    'Karnıyarık' -> 'karniyarik'
    Python'un unicodedata'si Turkce 'ı' ve 'İ' harflerini dogru cevirmez,
    bu yuzden once elle esleme tablosu uygulanir.
    """
    metin = metin.translate(TR_HARF)
    metin = unicodedata.normalize("NFKD", metin).encode("ascii", "ignore").decode()
    metin = re.sub(r"[^a-zA-Z0-9]+", "-", metin).strip("-").lower()
    return re.sub(r"-{2,}", "-", metin)


def main() -> None:
    malzemeler = {m["canonical_name"]: m for m in json.loads(MALZEME_DOSYA.read_text("utf-8"))}
    print(f"Sozlukte {len(malzemeler)} malzeme var.\n")

    ham_tarifler: list[dict] = []
    for dosya in sorted(HAM_KLASOR.glob("*.json")):
        veri = json.loads(dosya.read_text("utf-8"))
        ham_tarifler.extend(veri if isinstance(veri, list) else [veri])
        print(f"  okundu: {dosya.name} ({len(veri)} tarif)")
    print(f"\nToplam ham tarif: {len(ham_tarifler)}")

    gecerli: list[dict] = []
    slug_gorulen: set[str] = set()
    eslesmeyen: Counter = Counter()
    hatalar: list[str] = []

    for ham in ham_tarifler:
        baslik = (ham.get("title") or "").strip()
        if not baslik:
            hatalar.append("Basliksiz tarif atlandi")
            continue

        # --- 1) Slug ve mukerrer kontrolu
        slug = slugify(baslik)
        if slug in slug_gorulen:
            hatalar.append(f"MUKERRER atlandi: {baslik}")
            continue
        slug_gorulen.add(slug)

        # --- 2) Malzemeleri temizle ve kaloriyi hesapla
        toplam = {"kcal": 0.0, "protein": 0.0, "carb": 0.0, "fat": 0.0, "fiber": 0.0}
        temiz_malzemeler = []
        hesaplanabildi = True

        for mal in ham.get("ingredients", []):
            ad = (mal.get("name") or "").strip()
            if not ad:
                continue
            cn = (mal.get("canonical_name") or "").strip().lower() or None

            # Sozlukte yoksa canonical_name'i null yap ve raporla (GRI durumu)
            if cn and cn not in malzemeler:
                eslesmeyen[cn] += 1
                cn = None

            temiz_malzemeler.append({
                "name": ad,
                "canonical_name": cn,
                "quantity": mal.get("quantity"),
                "unit": mal.get("unit"),
                "optional": bool(mal.get("optional", False)),
                "note": mal.get("note"),
            })

            if cn is None or mal.get("quantity") in (None, 0) or not mal.get("unit"):
                continue  # olcusuz malzeme (tuz vb.) kaloriye katilmaz

            meta = malzemeler[cn]
            try:
                gram = to_grams(
                    float(mal["quantity"]),
                    mal["unit"],
                    grams_per_piece=meta.get("gpp"),
                    ml_to_gram=meta.get("ml2g"),
                )
            except (UnitConversionError, ValueError) as exc:
                hatalar.append(f"{baslik}: {ad} birim hatasi -> {exc}")
                hesaplanabildi = False
                continue

            oran = gram / 100.0
            toplam["kcal"] += oran * (meta.get("kcal") or 0)
            toplam["protein"] += oran * (meta.get("protein") or 0)
            toplam["carb"] += oran * (meta.get("carb") or 0)
            toplam["fat"] += oran * (meta.get("fat") or 0)
            toplam["fiber"] += oran * (meta.get("fiber") or 0)

        porsiyon = int(ham.get("servings") or 4)
        if porsiyon < 1:
            porsiyon = 4

        kcal_porsiyon = round(toplam["kcal"] / porsiyon, 1)

        # --- 3) Akil saglamasi
        if not hesaplanabildi or kcal_porsiyon <= 0:
            hatalar.append(f"{baslik}: kalori hesaplanamadi ({kcal_porsiyon} kcal)")
            continue
        if kcal_porsiyon > 1500:
            hatalar.append(f"{baslik}: SUPHELI kalori {kcal_porsiyon} kcal/porsiyon")

        # --- 4) Diyet etiketi tutarlilik kontrolu
        hayvansal = {"kiyma", "kuzu_eti", "dana_eti", "tavuk_gogsu", "tavuk_but",
                     "sucuk", "sut", "yogurt", "beyaz_peynir", "kasar_peyniri",
                     "lor_peyniri", "tereyagi", "krema", "yumurta"}
        etli = {"kiyma", "kuzu_eti", "dana_eti", "tavuk_gogsu", "tavuk_but", "sucuk"}
        kullanilan = {m["canonical_name"] for m in temiz_malzemeler if m["canonical_name"]}

        etiketler = [t for t in (ham.get("diet_tags") or []) if t]
        if "vegan" in etiketler and kullanilan & hayvansal:
            etiketler.remove("vegan")
            hatalar.append(f"{baslik}: hatali 'vegan' etiketi kaldirildi")
        if "vejetaryen" in etiketler and kullanilan & etli:
            etiketler.remove("vejetaryen")
            hatalar.append(f"{baslik}: hatali 'vejetaryen' etiketi kaldirildi")

        tarif = {
            "title": baslik,
            "slug": slug,
            "description": ham.get("description"),
            "image_url": None,
            "ingredients": temiz_malzemeler,
            "steps": [s.strip() for s in ham.get("steps", []) if s and s.strip()],
            "servings": porsiyon,
            "prep_time": int(ham.get("prep_time") or 0),
            "cook_time": int(ham.get("cook_time") or 0),
            "difficulty": ham.get("difficulty") or "orta",
            "calories_per_serving": kcal_porsiyon,
            "macros": {
                "protein_g": round(toplam["protein"] / porsiyon, 1),
                "carb_g": round(toplam["carb"] / porsiyon, 1),
                "fat_g": round(toplam["fat"] / porsiyon, 1),
                "fiber_g": round(toplam["fiber"] / porsiyon, 1),
            },
            "diet_tags": etiketler,
            "allergens": [a for a in (ham.get("allergens") or []) if a],
            "cuisine": ham.get("cuisine") or "turk",
            "source": "llm-uretimi + elle dogrulama",
            "source_url": None,
            "is_active": True,
        }

        # --- 5) Pydantic ile son dogrulama (MongoDB'ye gitmeden once)
        try:
            RecipeCreate.model_validate(tarif)
        except ValidationError as exc:
            ilk = exc.errors()[0]
            hatalar.append(f"{baslik}: sema hatasi {ilk['loc']} -> {ilk['msg']}")
            continue

        gecerli.append(tarif)

    CIKTI.write_text(json.dumps(gecerli, ensure_ascii=False, indent=2), "utf-8")

    rapor = ["ESLESMEYEN MALZEMELER (siklik sirasina gore)", "=" * 50]
    rapor += [f"{sayi:4d}  {ad}" for ad, sayi in eslesmeyen.most_common()]
    rapor += ["", "SORUNLAR / UYARILAR", "=" * 50, *hatalar]
    RAPOR.write_text("\n".join(rapor), "utf-8")

    print(f"\n{'=' * 55}")
    print(f"Gecerli tarif      : {len(gecerli)}")
    print(f"Elenen / uyari     : {len(hatalar)}")
    print(f"Eslesmeyen malzeme : {len(eslesmeyen)} farkli ad")
    if gecerli:
        ort = sum(t["calories_per_serving"] for t in gecerli) / len(gecerli)
        print(f"Ortalama kalori    : {ort:.0f} kcal/porsiyon")
    print(f"\nCikti  : {CIKTI}")
    print(f"Rapor  : {RAPOR}")


if __name__ == "__main__":
    main()