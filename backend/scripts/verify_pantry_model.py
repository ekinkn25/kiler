"""W2-T01 dogrulama: yeni kiler modeli dogru mu?

Kullanim (backend/ klasorunde):  python -m scripts.verify_pantry_model
Bellek-ici veritabani kullanir; gercek kalori.db'ye DOKUNMAZ.
"""
from datetime import timedelta

from sqlalchemy import create_engine, event, inspect, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.base import Base
import app.models  # noqa: F401
from app.models import Category, Ingredient, PantryItem, User
from app.models.enums import Availability, PantrySource, UnitType
from app.models.pantry import filter_confirmed, filter_unknown, utcnow

basarili = basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


engine = create_engine("sqlite:///:memory:", future=True)


@event.listens_for(Engine, "connect")
def _pragma(dbapi_connection, connection_record) -> None:
    cur = dbapi_connection.cursor()
    cur.execute("PRAGMA foreign_keys=ON")
    cur.close()


def main() -> None:
    Base.metadata.create_all(engine)
    sutunlar = {c["name"] for c in inspect(engine).get_columns("pantry_items")}

    print("\n1) Sema")
    for ad in ("availability", "source", "confirmed_at",
               "confidence_expires_at", "detected_confidence"):
        kontrol(f"'{ad}' sutunu eklendi", ad in sutunlar)
    for ad in ("min_threshold_base", "expiry_date", "opened_at", "is_active"):
        kontrol(f"'{ad}' sutunu KALDIRILDI", ad not in sutunlar)

    indeksler = {i["name"] for i in inspect(engine).get_indexes("pantry_items")}
    kontrol("ix_pantry_user_availability var", "ix_pantry_user_availability" in indeksler)
    kontrol("ix_pantry_confidence_expiry var", "ix_pantry_confidence_expiry" in indeksler)

    print(f"\n2) Ayarlar")
    kontrol("PANTRY_CONFIDENCE_DAYS tanimli",
            settings.PANTRY_CONFIDENCE_DAYS > 0, f"-> {settings.PANTRY_CONFIDENCE_DAYS} gun")
    kontrol("PANTRY_UNKNOWN_WEIGHT tanimli",
            0 < settings.PANTRY_UNKNOWN_WEIGHT < 1, f"-> {settings.PANTRY_UNKNOWN_WEIGHT}")

    with Session(engine) as db:
        kat = Category(code="bakliyat", display_name="Bakliyat")
        m1 = Ingredient(canonical_name="kirmizi_mercimek",
                        display_name="Kirmizi Mercimek", category=kat)
        m2 = Ingredient(canonical_name="sogan", display_name="Sogan", category=kat)
        m3 = Ingredient(canonical_name="havuc", display_name="Havuc", category=kat)
        u = User(email="t@ornek.com", hashed_password="x")
        db.add_all([kat, m1, m2, m3, u])
        db.flush()

        # (a) fotograftan gelen taze kayit
        taze = PantryItem(user_id=u.id, ingredient_id=m1.id, unit_type=UnitType.MASS)
        taze.confirm(PantrySource.FOTO, confidence=0.92)

        # (b) suresi dolmus kayit
        eski = PantryItem(user_id=u.id, ingredient_id=m2.id, unit_type=UnitType.COUNT)
        eski.confirm(PantrySource.BARKOD)
        eski.confidence_expires_at = utcnow() - timedelta(days=1)

        # (c) bitti isaretli kayit
        bitmis = PantryItem(user_id=u.id, ingredient_id=m3.id, unit_type=UnitType.MASS)
        bitmis.confirm(PantrySource.FOTO)
        bitmis.mark_finished()

        db.add_all([taze, eski, bitmis])
        db.commit()

        print("\n3) Guven suresi mantigi")
        kontrol("Taze kayit -> VAR", taze.effective_availability == Availability.VAR)
        kontrol("Suresi dolmus -> BILINMIYOR",
                eski.effective_availability == Availability.BILINMIYOR,
                "(gunluk temizlik gorevi calismasa bile)")
        kontrol("Bitti isaretli -> BITTI", bitmis.effective_availability == Availability.BITTI)
        kontrol("Kalan gun dogru hesaplaniyor",
                taze.days_remaining == settings.PANTRY_CONFIDENCE_DAYS - 1
                or taze.days_remaining == settings.PANTRY_CONFIDENCE_DAYS,
                f"-> {taze.days_remaining} gun")

        print("\n4) SQL filtreleri")
        kesin = db.scalars(select(PantryItem).where(
            PantryItem.user_id == u.id, filter_confirmed())).all()
        emin_degil = db.scalars(select(PantryItem).where(
            PantryItem.user_id == u.id, filter_unknown())).all()
        kontrol("filter_confirmed 1 kayit donuyor", len(kesin) == 1, f"-> {len(kesin)}")
        kontrol("filter_unknown 1 kayit donuyor", len(emin_degil) == 1, f"-> {len(emin_degil)}")
        kontrol("'bitti' hicbir filtreye girmiyor",
                bitmis.id not in {k.id for k in kesin + emin_degil})

        print("\n5) Durum degistirme")
        eski.confirm(PantrySource.BARKOD)
        db.commit()
        kontrol("[Var] denince sure yenileniyor",
                eski.effective_availability == Availability.VAR)

        taze.mark_unknown()
        db.commit()
        kontrol("Tarif yapilinca guven dusuyor (miktar degil)",
                taze.effective_availability == Availability.BILINMIYOR)

        print("\n6) Kisitlar")
        try:
            kotu = PantryItem(user_id=u.id, ingredient_id=m1.id,
                              detected_confidence=1.7)
            db.add(kotu)
            db.commit()
            kontrol("detected_confidence > 1 reddediliyor", False, "-> kabul edildi!")
        except Exception:
            db.rollback()
            kontrol("detected_confidence > 1 reddediliyor", True)

    print(f"\n{'-' * 52}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")


if __name__ == "__main__":
    main()