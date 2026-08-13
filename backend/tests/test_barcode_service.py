"""W2-T12 birim testleri: barkod -> urun -> kiler akisi.

Gercek Open Food Facts'e AG ISTEGI ATMAZ - fetch_product monkeypatch ile
sahteleştirilir. Gercek API kontrolu scripts/verify_barcode_scan.py'de.
"""
from datetime import timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.exceptions import NotFoundError
from app.db.base import Base
from app.models import Ingredient, PantryEvent, PantryItem, Product, User
from app.models.pantry import utcnow
from app.schemas import ProductCreate
from app.services import barcode_service
from app.services.barcode_service import IngredientRequiredError
from app.services.ingredient_matcher import clear_lookup_cache
from app.services.openfoodfacts import OffProduct, _off_to_product, _serving_size_g


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    clear_lookup_cache()
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="barkod_test@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def domates(db):
    i = Ingredient(canonical_name="domates", display_name="Domates")
    db.add(i)
    db.commit()
    return i


def sahte_off_urunu(ad="Domates Salcasi", kcal=90):
    return OffProduct(
        name=ad, brand="TestMarka", calories_per_100g=kcal,
        protein_per_100g=2, carb_per_100g=18, fat_per_100g=0.5,
        fiber_per_100g=3, sugar_per_100g=10, sodium_mg_per_100g=500,
        image_url=None, serving_size_g=None,
    )


# ------------------------------------------------------------------ OFF ayristirma (saf)
def test_sodyum_gramdan_miligrama_cevrilir():
    ham = {"nutriments": {"sodium_100g": 0.5}}
    assert _off_to_product(ham).sodium_mg_per_100g == 500


def test_sodyum_yoksa_none():
    assert _off_to_product({"nutriments": {}}).sodium_mg_per_100g is None


@pytest.mark.parametrize("ham, beklenen", [
    ("30 g", 30.0), ("30g", 30.0), ("1 adet (250g)", 250.0),
    ("1 porsiyon", None), (None, None),
])
def test_serving_size_ayristirma(ham, beklenen):
    assert _serving_size_g(ham) == beklenen


# ------------------------------------------------------------------ tarama
@pytest.mark.asyncio
async def test_off_bulamazsa_found_false(db, monkeypatch):
    monkeypatch.setattr(barcode_service, "fetch_product", lambda b: _none())
    sonuc = await barcode_service.scan_barcode(db, "0000000000000")
    assert sonuc.found is False


async def _none():
    return None


@pytest.mark.asyncio
async def test_off_bulursa_urun_olusturulur(db, monkeypatch):
    async def sahte(barcode):
        return sahte_off_urunu()
    monkeypatch.setattr(barcode_service, "fetch_product", sahte)

    sonuc = await barcode_service.scan_barcode(db, "1111111111111")
    assert sonuc.found is True
    assert sonuc.product.name == "Domates Salcasi"
    assert sonuc.from_cache is False
    assert db.query(Product).filter_by(barcode="1111111111111").count() == 1


@pytest.mark.asyncio
async def test_urun_adindan_malzeme_otomatik_eslesir(db, domates, monkeypatch):
    async def sahte(barcode):
        return sahte_off_urunu(ad="domates")
    monkeypatch.setattr(barcode_service, "fetch_product", sahte)

    sonuc = await barcode_service.scan_barcode(db, "2222222222222")
    assert sonuc.matched_ingredient is not None
    assert sonuc.matched_ingredient.canonical_name == "domates"
    assert sonuc.product.ingredient_id == domates.id


@pytest.mark.asyncio
async def test_eslesmeyen_urun_ingredient_id_none_kalir(db, monkeypatch):
    async def sahte(barcode):
        return sahte_off_urunu(ad="Tuhaf Marka Urunu XYZ")
    monkeypatch.setattr(barcode_service, "fetch_product", sahte)

    sonuc = await barcode_service.scan_barcode(db, "3333333333333")
    assert sonuc.matched_ingredient is None
    assert sonuc.product.ingredient_id is None


@pytest.mark.asyncio
async def test_taze_urun_off_a_gitmiyor(db, monkeypatch):
    urun = Product(barcode="4444444444444", name="Onbellekteki Urun",
                   calories_per_100g=100, fetched_at=utcnow())
    db.add(urun)
    db.commit()

    cagrildi = False
    async def cagrilirsa_isaretle(barcode):
        nonlocal cagrildi
        cagrildi = True
        return sahte_off_urunu()
    monkeypatch.setattr(barcode_service, "fetch_product", cagrilirsa_isaretle)

    sonuc = await barcode_service.scan_barcode(db, "4444444444444")
    assert sonuc.from_cache is True
    assert cagrildi is False


@pytest.mark.asyncio
async def test_eski_urun_off_a_gider_ve_guncellenir(db, monkeypatch):
    urun = Product(barcode="5555555555555", name="Eski Ad",
                   calories_per_100g=1, fetched_at=utcnow() - timedelta(days=90))
    db.add(urun)
    db.commit()

    async def sahte(barcode):
        return sahte_off_urunu(ad="Yeni Ad", kcal=200)
    monkeypatch.setattr(barcode_service, "fetch_product", sahte)

    sonuc = await barcode_service.scan_barcode(db, "5555555555555")
    assert sonuc.from_cache is False
    assert sonuc.product.name == "Yeni Ad"
    assert sonuc.product.calories_per_100g == 200


# ------------------------------------------------------------------ onay
def test_confirm_kendi_eslesmesiyle_kilere_yazar(db, user, domates):
    urun = Product(barcode="6666666666666", name="X", ingredient_id=domates.id)
    db.add(urun)
    db.commit()

    sonuc = barcode_service.confirm_scanned_product(db, user, urun.id, None)

    assert sonuc["canonical_name"] == "domates"
    kayit = db.query(PantryItem).filter_by(user_id=user.id).one()
    assert kayit.availability.value == "var"
    assert kayit.source.value == "barkod"


def test_confirm_eslesmeyen_urun_ingredient_id_olmadan_hata(db, user):
    urun = Product(barcode="7777777777777", name="Eslesmeyen Urun")
    db.add(urun)
    db.commit()

    with pytest.raises(IngredientRequiredError):
        barcode_service.confirm_scanned_product(db, user, urun.id, None)


def test_confirm_ingredient_id_elle_verilirse_urune_ogretir(db, user, domates):
    urun = Product(barcode="8888888888888", name="Eslesmeyen Urun")
    db.add(urun)
    db.commit()

    barcode_service.confirm_scanned_product(db, user, urun.id, domates.id)

    db.refresh(urun)
    assert urun.ingredient_id == domates.id


def test_confirm_olmayan_urun_404(db, user):
    with pytest.raises(NotFoundError):
        barcode_service.confirm_scanned_product(db, user, 999999, None)


def test_pantry_event_yaziliyor(db, user, domates):
    urun = Product(barcode="9999999999999", name="X", ingredient_id=domates.id)
    db.add(urun)
    db.commit()

    barcode_service.confirm_scanned_product(db, user, urun.id, None)
    olay = db.query(PantryEvent).filter_by(user_id=user.id).one()
    assert olay.event_type.value == "eklendi"


# ------------------------------------------------------------------ manuel urun
def test_manuel_urun_source_user(db):
    urun = barcode_service.create_manual_product(db, ProductCreate(
        barcode="1234567890123", name="Elle Eklenen Urun", calories_per_100g=250,
    ))
    assert urun.source.value == "user"
    assert urun.name == "Elle Eklenen Urun"