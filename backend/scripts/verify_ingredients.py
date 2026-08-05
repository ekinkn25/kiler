"""W1-T12 dogrulama: sozluk tam mi, MongoDB tarifleriyle ortusuyor mu?

Kullanim (backend/ klasorunde):  python -m scripts.verify_ingredients
"""
import asyncio

from sqlalchemy import func, select

from app.db.mongo_schema import RECIPE_COLLECTION
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo
from app.db.session import SessionLocal
from app.models import Allergen, Category, DietTag, Ingredient, IngredientAlias
from app.services.unit_service import normalize_text

basarili = 0
basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


async def main() -> None:
    with SessionLocal() as db:
        malzeme_sayi = db.scalar(select(func.count()).select_from(Ingredient))
        alias_sayi = db.scalar(select(func.count()).select_from(IngredientAlias))

        print("\n1) Tablo doluluk")
        kontrol("Malzeme >= 150", malzeme_sayi >= 150, f"-> {malzeme_sayi}")
        kontrol("Alias >= 300", alias_sayi >= 300, f"-> {alias_sayi}")
        kontrol("Kategoriler dolu",
                db.scalar(select(func.count()).select_from(Category)) >= 9)
        kontrol("Diyet etiketleri dolu",
                db.scalar(select(func.count()).select_from(DietTag)) >= 6)
        kontrol("Alerjenler dolu",
                db.scalar(select(func.count()).select_from(Allergen)) >= 8)

        print("\n2) Veri kalitesi")
        kalorisiz = db.scalar(
            select(func.count()).select_from(Ingredient)
            .where(Ingredient.calories_per_100g.is_(None))
        )
        kontrol("Kalorisi bos malzeme yok", kalorisiz == 0, f"-> {kalorisiz} eksik")

        adet_birimli_gpp_yok = db.scalar(
            select(func.count()).select_from(Ingredient)
            .where(Ingredient.default_unit.in_(["adet", "dilim", "demet", "paket"]))
            .where(Ingredient.grams_per_piece.is_(None))
        )
        kontrol("Adet birimli malzemelerin hepsinde grams_per_piece var",
                adet_birimli_gpp_yok == 0, f"-> {adet_birimli_gpp_yok} eksik")

        staple_sayi = db.scalar(
            select(func.count()).select_from(Ingredient).where(Ingredient.is_staple.is_(True))
        )
        kontrol("Temel malzeme (is_staple) isaretli", staple_sayi >= 10, f"-> {staple_sayi}")

        sozluk = {i.canonical_name for i in db.scalars(select(Ingredient))}
        alias_haritasi = {a.alias for a in db.scalars(select(IngredientAlias))}

    print("\n3) MongoDB tarifleriyle capraz kontrol")
    await connect_to_mongo()
    if not mongo.is_connected:
        print("  MongoDB baglantisi yok, capraz kontrol atlandi.")
    else:
        kol = mongo.database[RECIPE_COLLECTION]
        tarif_malzemeleri: set[str] = set()
        null_sayi = toplam_malzeme_satiri = 0

        async for tarif in kol.find({}, {"ingredients": 1}):
            for m in tarif.get("ingredients", []):
                toplam_malzeme_satiri += 1
                cn = m.get("canonical_name")
                if cn:
                    tarif_malzemeleri.add(cn)
                else:
                    null_sayi += 1

        eksik = sorted(tarif_malzemeleri - sozluk)
        kapsama = (toplam_malzeme_satiri - null_sayi) / toplam_malzeme_satiri * 100

        kontrol("Tariflerdeki her canonical_name sozlukte var",
                len(eksik) == 0, f"-> eksik: {eksik[:10] if eksik else 'yok'}")
        kontrol("Malzeme kapsama orani >= %90", kapsama >= 90, f"-> %{kapsama:.1f}")

        kullanilmayan = sorted(sozluk - tarif_malzemeleri)
        print(f"  [BILGI] Hicbir tarifte kullanilmayan malzeme: {len(kullanilmayan)} "
              f"(zararsiz; kullanici kilerinde olabilir)")

        await close_mongo_connection()

    print("\n4) Alias eslestirme ornekleri")
    for ham in ["Kırmızı Mercimek", "KIRMIZI MERCIMEK", "k mercimek",
                "salça", "sıvı yağ", "kaşar", "nar ekşisi"]:
        norm = normalize_text(ham)
        kontrol(f"'{ham}' eslesiyor", norm in alias_haritasi, f"-> '{norm}'")

    print(f"\n{'=' * 55}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")


if __name__ == "__main__":
    asyncio.run(main())