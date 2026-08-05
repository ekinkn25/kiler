"""Referans verilerini SQLite'a yukler: kategoriler, diyet etiketleri,
alerjenler, malzemeler ve takma adlar.

Kullanim (backend/ klasorunde):  python -m scripts.seed_reference_data

IDEMPOTENT: kac kez calistirilirsa calistirilsin ayni sonucu verir.
"""
import json
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.constants import ALLERGENS, CATEGORIES, DIET_TAGS
from app.db.session import SessionLocal
from app.models import Allergen, Category, DietTag, Ingredient, IngredientAlias
from app.models.enums import UnitCode, UnitType
from app.services.unit_service import normalize_text

VERI = Path(__file__).resolve().parents[2] / "data"
MALZEME_DOSYA = VERI / "ingredients_seed.json"
ALIAS_DOSYA = VERI / "ingredient_aliases.json"


def seed_sozlukler(db: Session) -> None:
    """Kategori, diyet etiketi ve alerjen tablolarini doldurur."""
    for kod, ad in CATEGORIES:
        if not db.scalar(select(Category).where(Category.code == kod)):
            db.add(Category(code=kod, display_name=ad))
    for i, (kod, ad) in enumerate(DIET_TAGS):
        if not db.scalar(select(DietTag).where(DietTag.code == kod)):
            db.add(DietTag(code=kod, display_name=ad))
    for kod, ad in ALLERGENS:
        if not db.scalar(select(Allergen).where(Allergen.code == kod)):
            db.add(Allergen(code=kod, display_name=ad))
    db.commit()
    print(f"[SOZLUK] {len(CATEGORIES)} kategori, {len(DIET_TAGS)} diyet etiketi, "
          f"{len(ALLERGENS)} alerjen")


def seed_malzemeler(db: Session) -> dict[str, int]:
    """ingredients tablosunu doldurur/gunceller. canonical_name -> id doner."""
    kayitlar = json.loads(MALZEME_DOSYA.read_text("utf-8"))
    kategoriler = {c.code: c.id for c in db.scalars(select(Category))}

    eklenen = guncellenen = 0
    for k in kayitlar:
        mevcut = db.scalar(
            select(Ingredient).where(Ingredient.canonical_name == k["canonical_name"])
        )
        alanlar = dict(
            display_name=k["display_name"],
            category_id=kategoriler.get(k.get("category", "diger")),
            default_unit_type=UnitType(k["unit_type"]),
            default_unit=UnitCode(k["default_unit"]),
            grams_per_piece=k.get("gpp"),
            ml_to_gram_factor=k.get("ml2g"),
            cooked_yield_factor=k.get("yield"),
            calories_per_100g=k.get("kcal"),
            protein_per_100g=k.get("protein"),
            carb_per_100g=k.get("carb"),
            fat_per_100g=k.get("fat"),
            fiber_per_100g=k.get("fiber"),
            is_staple=bool(k.get("staple", False)),
        )
        if mevcut:
            for alan, deger in alanlar.items():
                setattr(mevcut, alan, deger)
            guncellenen += 1
        else:
            db.add(Ingredient(canonical_name=k["canonical_name"], **alanlar))
            eklenen += 1

    db.commit()
    print(f"[MALZEME] {eklenen} eklendi, {guncellenen} guncellendi")
    return {i.canonical_name: i.id for i in db.scalars(select(Ingredient))}


def seed_aliaslar(db: Session, id_haritasi: dict[str, int]) -> None:
    """Otomatik uretilen + elle yazilan takma adlari yukler.

    alias sutunu UNIQUE oldugu icin cakisanlar atlanir. Bir varyant iki
    farkli malzemeye isaret ediyorsa ILK gelen kazanir; bu durum raporlanir.
    """
    mevcut_aliaslar = {a.alias for a in db.scalars(select(IngredientAlias))}
    kayitlar = json.loads(MALZEME_DOSYA.read_text("utf-8"))
    elle = json.loads(ALIAS_DOSYA.read_text("utf-8")) if ALIAS_DOSYA.exists() else {}

    otomatik = elle_sayi = cakisma = 0

    def ekle(canonical: str, ham: str, kaynak: str) -> bool:
        nonlocal cakisma
        norm = normalize_text(ham)
        if not norm or norm in mevcut_aliaslar:
            if norm in mevcut_aliaslar:
                cakisma += 1
            return False
        ing_id = id_haritasi.get(canonical)
        if ing_id is None:
            print(f"  [UYARI] '{canonical}' sozlukte yok, alias atlandi: {ham}")
            return False
        db.add(IngredientAlias(ingredient_id=ing_id, alias=norm, source=kaynak))
        mevcut_aliaslar.add(norm)
        return True

    if not ALIAS_DOSYA.exists():
        print(f"  [UYARI] Manuel alias dosyasi bulunamadi: {ALIAS_DOSYA}")

    # 1) Otomatik: display_name ve canonical_name varyantlari
    for k in kayitlar:
        cn = k["canonical_name"]
        for ham in alias_varyantlari(k["display_name"]):
            if ekle(cn, ham, "otomatik"):
                otomatik += 1

    # 2) Elle yazilan kritik varyantlar
    for cn, varyantlar in elle.items():
        for ham in varyantlar:
            if ekle(cn, ham, "manuel"):
                elle_sayi += 1

    db.commit()
    print(f"[ALIAS] {otomatik} otomatik + {elle_sayi} manuel = "
          f"{otomatik + elle_sayi} yeni ({cakisma} cakisma atlandi)")

def alias_varyantlari(display_name: str) -> set[str]:
    """NORMALIZE EDILDIKTEN SONRA birbirinden farkli varyantlar uretir.

    DIKKAT: display_name, canonical_name ve alt cizgisiz hali normalize
    edilince AYNI metne dusuyor ('kirmizi mercimek'). Bu yuzden gercekten
    farkli desenler uretmek gerekir:
        temel      : kirmizi mercimek
        ters sira  : mercimek kirmizi     ("mercimek, kırmızı" yazimi icin)
        kisaltma   : k mercimek           ("K.MERCIMEK" market yazimi icin)
        bosluksuz  : kirmizimercimek      (yazim hatasi toleransi)
    """
    temel = normalize_text(display_name)
    if not temel:
        return set()

    varyantlar = {temel}
    kelimeler = temel.split()

    if len(kelimeler) >= 2:
        varyantlar.add(" ".join(reversed(kelimeler)))
        varyantlar.add(kelimeler[0][0] + " " + " ".join(kelimeler[1:]))

    birlesik = temel.replace(" ", "")
    if birlesik != temel:
        varyantlar.add(birlesik)

    return varyantlar


def main() -> None:
    with SessionLocal() as db:
        seed_sozlukler(db)
        harita = seed_malzemeler(db)
        seed_aliaslar(db, harita)

        toplam_malzeme = db.scalar(select(Ingredient).where(Ingredient.id > 0)) and \
            len(list(db.scalars(select(Ingredient))))
        toplam_alias = len(list(db.scalars(select(IngredientAlias))))
        print(f"\n{'=' * 50}")
        print(f"Toplam malzeme : {toplam_malzeme}  (hedef: 150+)")
        print(f"Toplam alias   : {toplam_alias}  (hedef: 300+)")


if __name__ == "__main__":
    main()