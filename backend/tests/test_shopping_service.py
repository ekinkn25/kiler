"""W3-T09 birim testleri: alisveris listesine tariften toplu ekleme."""
import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import Ingredient, ShoppingListItem, User
from app.models.enums import ShoppingSource
from app.schemas import ShoppingItemCreate
from app.services.shopping_service import add_from_recipe, list_items

TARIF = "a" * 24
TARIF2 = "b" * 24


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="alisveris@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def malzemeler(db):
    kayitlar = [
        Ingredient(canonical_name="limon", display_name="Limon"),
        Ingredient(canonical_name="domates", display_name="Domates"),
        Ingredient(canonical_name="sogan", display_name="Sogan"),
    ]
    db.add_all(kayitlar)
    db.commit()
    for k in kayitlar:
        db.refresh(k)
    return {k.canonical_name: k.id for k in kayitlar}


def test_tariften_toplu_ekleme(db, user, malzemeler):
    sonuc = add_from_recipe(
        db, user, recipe_id=TARIF,
        items=[
            ShoppingItemCreate(ingredient_id=malzemeler["limon"]),
            ShoppingItemCreate(ingredient_id=malzemeler["domates"]),
        ],
    )

    assert len(sonuc) == 2
    assert all(k.source is ShoppingSource.TARIF for k in sonuc)
    assert all(k.source_recipe_id == TARIF for k in sonuc)
    assert all(k.is_checked is False for k in sonuc)
    assert len(list_items(db, user)) == 2


def test_ayni_malzeme_IKINCI_satir_acmaz(db, user, malzemeler):
    add_from_recipe(db, user, recipe_id=TARIF,
                    items=[ShoppingItemCreate(ingredient_id=malzemeler["limon"])])
    add_from_recipe(db, user, recipe_id=TARIF2,
                    items=[ShoppingItemCreate(ingredient_id=malzemeler["limon"])])

    # Essiz kisit ihlali olmadan tek satir kalmali.
    assert len(list_items(db, user)) == 1
    kayit = list_items(db, user)[0]
    assert kayit.source_recipe_id == TARIF2  # son tarife guncellendi


def test_alindi_isareti_yeniden_eklenince_kalkar(db, user, malzemeler):
    (kayit,) = add_from_recipe(
        db, user, recipe_id=TARIF,
        items=[ShoppingItemCreate(ingredient_id=malzemeler["limon"])],
    )
    kayit.is_checked = True
    db.commit()

    add_from_recipe(db, user, recipe_id=TARIF2,
                    items=[ShoppingItemCreate(ingredient_id=malzemeler["limon"])])

    db.refresh(kayit)
    assert kayit.is_checked is False


def test_ayni_istekteki_tekrarlar_tekillestirilir(db, user, malzemeler):
    sonuc = add_from_recipe(
        db, user, recipe_id=TARIF,
        items=[
            ShoppingItemCreate(ingredient_id=malzemeler["limon"]),
            ShoppingItemCreate(ingredient_id=malzemeler["limon"]),
        ],
    )

    assert len(sonuc) == 1
    assert len(list_items(db, user)) == 1


def test_bilinmeyen_kimlik_atlanir_digerleri_eklenir(db, user, malzemeler):
    sonuc = add_from_recipe(
        db, user, recipe_id=TARIF,
        items=[
            ShoppingItemCreate(ingredient_id=999999),
            ShoppingItemCreate(ingredient_id=malzemeler["sogan"]),
        ],
    )

    assert len(sonuc) == 1
    assert sonuc[0].ingredient_id == malzemeler["sogan"]


def test_isaretliler_haric_listelenebilir(db, user, malzemeler):
    (a, b) = add_from_recipe(
        db, user, recipe_id=TARIF,
        items=[
            ShoppingItemCreate(ingredient_id=malzemeler["limon"]),
            ShoppingItemCreate(ingredient_id=malzemeler["domates"]),
        ],
    )
    a.is_checked = True
    db.commit()

    assert len(list_items(db, user, include_checked=True)) == 2
    assert len(list_items(db, user, include_checked=False)) == 1


def test_baska_kullanicinin_listesi_sizmaz(db, user, malzemeler):
    baskasi = User(email="baska@example.com", hashed_password="x")
    db.add(baskasi)
    db.commit()

    add_from_recipe(db, baskasi, recipe_id=TARIF,
                    items=[ShoppingItemCreate(ingredient_id=malzemeler["limon"])])

    assert list_items(db, user) == []