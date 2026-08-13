"""W2-T10 birim testleri: gorme tespitlerinin onaylanmasi.

MongoDB, LLM veya HTTP GEREKTIRMEZ.
"""
from datetime import timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.db.base import Base
from app.models import Ingredient, PantryEvent, PantryItem, User
from app.models.enums import Availability, PantryEventType, PantrySource
from app.models.pantry import utcnow
from app.services.pantry_service import confirm_detected_ingredients


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="pantry_confirm@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def malzemeler(db):
    domates = Ingredient(canonical_name="domates", display_name="Domates")
    sogan = Ingredient(canonical_name="sogan", display_name="Soğan")
    db.add_all([domates, sogan])
    db.commit()
    return {"domates": domates, "sogan": sogan}


def test_yeni_malzeme_var_olarak_yazilir(db, user, malzemeler):
    sonuc = confirm_detected_ingredients(db, user, ["domates"], PantrySource.FOTO)

    assert sonuc.confirmed[0]["canonical_name"] == "domates"
    assert sonuc.confirmed[0]["is_new"] is True

    kayit = db.query(PantryItem).filter_by(user_id=user.id).one()
    assert kayit.availability == Availability.VAR
    assert kayit.source == PantrySource.FOTO


def test_confidence_expires_at_yedi_gun(db, user, malzemeler):
    confirm_detected_ingredients(db, user, ["domates"], PantrySource.FOTO)
    kayit = db.query(PantryItem).filter_by(user_id=user.id).one()

    kalan = kayit.confidence_expires_at - utcnow()
    beklenen = timedelta(days=settings.PANTRY_CONFIDENCE_DAYS)
    assert abs(kalan - beklenen) < timedelta(seconds=5)


def test_var_olan_kayit_guncellenir_yeni_satir_acilmaz(db, user, malzemeler):
    confirm_detected_ingredients(db, user, ["domates"], PantrySource.FOTO)
    kayit = db.query(PantryItem).filter_by(user_id=user.id).one()
    kayit.mark_finished()
    db.commit()

    sonuc = confirm_detected_ingredients(db, user, ["domates"], PantrySource.FOTO)

    assert sonuc.confirmed[0]["is_new"] is False
    assert db.query(PantryItem).filter_by(user_id=user.id).count() == 1
    db.refresh(kayit)
    assert kayit.availability == Availability.VAR


def test_bilinmeyen_canonical_name_atlanir_cokmez(db, user, malzemeler):
    sonuc = confirm_detected_ingredients(
        db, user, ["domates", "olmayan_malzeme_xyz"], PantrySource.FOTO
    )
    assert len(sonuc.confirmed) == 1
    assert sonuc.skipped_unknown == ["olmayan_malzeme_xyz"]


def test_pantry_event_eklendi_olarak_kaydedilir(db, user, malzemeler):
    confirm_detected_ingredients(db, user, ["domates"], PantrySource.FOTO)
    olay = db.query(PantryEvent).filter_by(user_id=user.id).one()
    assert olay.event_type == PantryEventType.EKLENDI
    assert olay.quantity_base_delta == 0.0


def test_birden_fazla_malzeme_tek_istekte(db, user, malzemeler):
    sonuc = confirm_detected_ingredients(
        db, user, ["domates", "sogan"], PantrySource.FOTO
    )
    assert len(sonuc.confirmed) == 2
    assert db.query(PantryItem).filter_by(user_id=user.id).count() == 2