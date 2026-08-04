"""W1-T05 dogrulama: modeller import ediliyor mu, tablolar olusuyor mu,
CASCADE calisiyor mu?

Gecici bir bellek-ici veritabani kullanir; gercek kalori.db'ye dokunmaz.
"""
from sqlalchemy import create_engine, event, inspect, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.db.base import Base
import app.models  # noqa: F401  -- tum modellerin kayit olmasi icin sart
from app.models import (
    Allergen, Category, DietTag, Ingredient, MealLog, PantryEvent,
    PantryItem, User, UserProfile,
)
from app.models.enums import (
    MealType, PantryEventType, UnitCode, UnitType,
)

BEKLENEN_TABLOLAR = {
    "users", "user_profiles", "diet_tags", "user_diet_tags",
    "allergens", "user_allergens",
    "categories", "ingredients", "ingredient_aliases",
    "unmatched_ingredients", "products",
    "pantry_items", "pantry_events", "shopping_list_items",
    "meal_logs", "weight_logs",
    "recipe_feedback", "recipe_favorites", "user_taste_weights",
    "chat_conversations", "chat_messages", "llm_cache",
}

engine = create_engine("sqlite:///:memory:", future=True)


@event.listens_for(Engine, "connect")
def _pragma(dbapi_connection, connection_record) -> None:
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


def main() -> None:
    # --- 1) Tablolar olusuyor mu?
    Base.metadata.create_all(engine)
    olusan = set(inspect(engine).get_table_names())

    print(f"1) Olusan tablo sayisi: {len(olusan)} (beklenen: {len(BEKLENEN_TABLOLAR)})")
    eksik = BEKLENEN_TABLOLAR - olusan
    fazla = olusan - BEKLENEN_TABLOLAR
    if eksik:
        print(f"   EKSIK: {sorted(eksik)}")
    if fazla:
        print(f"   FAZLA: {sorted(fazla)}")
    if not eksik and not fazla:
        print("   TAMAM: tum tablolar eksiksiz olustu.")

    with Session(engine) as db:
        # --- 2) FK zorlamasi acik mi?
        fk_on = db.execute(text("PRAGMA foreign_keys")).scalar()
        print(f"\n2) PRAGMA foreign_keys = {fk_on}  (1 olmali)")

        # --- 3) CASCADE calisiyor mu?
        kategori = Category(code="bakliyat", display_name="Bakliyat")
        malzeme = Ingredient(
            canonical_name="kirmizi_mercimek",
            display_name="Kirmizi Mercimek",
            category=kategori,
        )
        vegan = DietTag(code="vegan", display_name="Vegan")
        findik = Allergen(code="findik", display_name="Findik")

        kullanici = User(email="test@ornek.com", hashed_password="x")
        kullanici.profile = UserProfile(birth_year=2000, height_cm=175, weight_kg=70)
        kullanici.diet_tags.append(vegan)
        kullanici.allergens.append(findik)
        db.add_all([kategori, malzeme, vegan, findik, kullanici])
        db.flush()

        kiler = PantryItem(
            user_id=kullanici.id,
            ingredient_id=malzeme.id,
            quantity_base=5000,          # 5 kg -> 5000 g
            unit_type=UnitType.MASS,
            display_unit=UnitCode.KG,
            min_threshold_base=500,
        )
        db.add(kiler)
        db.flush()

        db.add_all([
            PantryEvent(
                user_id=kullanici.id, ingredient_id=malzeme.id,
                pantry_item_id=kiler.id, event_type=PantryEventType.EKLENDI,
                quantity_base_delta=5000, unit_type=UnitType.MASS,
            ),
            PantryEvent(
                user_id=kullanici.id, ingredient_id=malzeme.id,
                pantry_item_id=kiler.id, event_type=PantryEventType.TUKETILDI_TARIF,
                quantity_base_delta=-2000, unit_type=UnitType.MASS,
            ),
            MealLog(
                user_id=kullanici.id, logged_date=__import__("datetime").date.today(),
                meal_type=MealType.AKSAM, item_name="Mercimek Corbasi", calories=180,
            ),
        ])
        db.commit()

        uid = kullanici.id
        print(f"\n3) Silmeden once  -> kiler: {db.query(PantryItem).count()}, "
              f"olay: {db.query(PantryEvent).count()}, ogun: {db.query(MealLog).count()}")

        # is_low hesaplanan alani
        print(f"   is_low (3000 g > 500 g esik): {kiler.is_low}  (False olmali)")

        db.delete(db.get(User, uid))
        db.commit()

        kalan = (db.query(PantryItem).count() + db.query(PantryEvent).count()
                 + db.query(MealLog).count() + db.query(UserProfile).count())
        print(f"   Silmeden sonra -> kiler: {db.query(PantryItem).count()}, "
              f"olay: {db.query(PantryEvent).count()}, ogun: {db.query(MealLog).count()}, "
              f"profil: {db.query(UserProfile).count()}")
        print(f"   CASCADE: {'TAMAM' if kalan == 0 else 'BASARISIZ - ' + str(kalan) + ' yetim kayit'}")

        # Sozluk kayitlari SILINMEMELI (paylasilan referans verisi)
        print(f"   Malzeme sozlugu korundu mu: "
              f"{'TAMAM' if db.query(Ingredient).count() == 1 else 'HATA'}")


if __name__ == "__main__":
    main()