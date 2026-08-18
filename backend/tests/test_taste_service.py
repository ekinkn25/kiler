"""W3-T02B birim testleri: ornek-ortalamasi guncelleme kurali."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import User
from app.models.enums import TasteDimension
from app.models.recipe import UserTasteWeight
from app.services.taste_service import apply_taste_event, register_recipe_signal


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="taste@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


def test_ilk_sinyal_agirligi_dogrudan_esitler(db, user):
    apply_taste_event(db, user.id, TasteDimension.CUISINE, "italyan", 1.0)
    db.commit()
    satir = db.query(UserTasteWeight).one()
    assert satir.weight == 1.0
    assert satir.event_count == 1


def test_ikinci_zit_sinyal_ortalamayi_sifira_ceker(db, user):
    apply_taste_event(db, user.id, TasteDimension.CUISINE, "italyan", 1.0)
    apply_taste_event(db, user.id, TasteDimension.CUISINE, "italyan", -1.0)
    db.commit()
    satir = db.query(UserTasteWeight).one()
    assert satir.weight == 0.0
    assert satir.event_count == 2


def test_agirlik_daima_araliktan_tasmaz(db, user):
    for _ in range(50):
        apply_taste_event(db, user.id, TasteDimension.CUISINE, "italyan", 1.0)
    satir = db.query(UserTasteWeight).one()
    assert -1.0 <= satir.weight <= 1.0


def test_farkli_boyut_ve_anahtar_ayri_satir_acar(db, user):
    apply_taste_event(db, user.id, TasteDimension.CUISINE, "italyan", 1.0)
    apply_taste_event(db, user.id, TasteDimension.DIFFICULTY, "kolay", 1.0)
    apply_taste_event(db, user.id, TasteDimension.CUISINE, "meksika", 1.0)
    assert db.query(UserTasteWeight).count() == 3


def test_register_recipe_signal_tum_boyutlari_isler(db, user):
    tarif = {
        "cuisine": "italyan",
        "difficulty": "kolay",
        "diet_tags": ["vegan"],
        "ingredients": [
            {"canonical_name": "domates", "optional": False},
            {"canonical_name": "maydanoz", "optional": True},
        ],
    }
    register_recipe_signal(db, user.id, tarif, signal=1.0)
    db.commit()
    anahtarlar = {(s.dimension, s.taste_key) for s in db.query(UserTasteWeight).all()}
    assert anahtarlar == {
        (TasteDimension.CUISINE, "italyan"),
        (TasteDimension.DIFFICULTY, "kolay"),
        (TasteDimension.DIET_TAG, "vegan"),
        (TasteDimension.INGREDIENT, "domates"),
    }


def test_tekrar_parametresi_event_count_u_katlar(db, user):
    register_recipe_signal(db, user.id, {"cuisine": "italyan"}, signal=1.0, tekrar=3)
    satir = db.query(UserTasteWeight).one()
    assert satir.event_count == 3