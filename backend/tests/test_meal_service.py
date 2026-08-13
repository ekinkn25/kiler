"""W2-T11 birim testleri: anlik goruntu hesaplamasi ve gunluk ozet.

MongoDB GEREKTIRMEZ (tarif kaynakli hesaplama scripts/verify_meals.py'de
test edilir). Urun/malzeme/serbest giris yollari ve gunluk ozet burada.
"""
from datetime import date

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.exceptions import PermissionDeniedError
from app.db.base import Base
from app.models import Ingredient, MealLog, Product, User, UserProfile
from app.models.enums import MealType, UnitCode, UnitType
from app.schemas import MealLogCreate
from app.services.meal_service import (
    MissingQuantityError, delete_meal_log, get_daily_summary, resolve_snapshot,
)


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="meal_test@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def user_with_targets(db):
    k = User(email="hedefli@example.com", hashed_password="x")
    db.add(k)
    db.flush()
    db.add(UserProfile(
        user_id=k.id, daily_calorie_target=2200,
        protein_target_g=120, carb_target_g=250, fat_target_g=70,
    ))
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def domates(db):
    i = Ingredient(
        canonical_name="domates", display_name="Domates",
        default_unit_type=UnitType.MASS, default_unit=UnitCode.G,
        calories_per_100g=18, protein_per_100g=0.9, carb_per_100g=3.9,
        fat_per_100g=0.2, fiber_per_100g=1.2,
    )
    db.add(i)
    db.commit()
    return i


@pytest.fixture()
def yumurta(db):
    i = Ingredient(
        canonical_name="yumurta", display_name="Yumurta",
        default_unit_type=UnitType.COUNT, default_unit=UnitCode.ADET,
        grams_per_piece=50,
        calories_per_100g=155, protein_per_100g=13, carb_per_100g=1.1, fat_per_100g=11,
    )
    db.add(i)
    db.commit()
    return i


@pytest.fixture()
def urun(db):
    p = Product(
        name="Yogurt 200g", serving_size_g=200,
        calories_per_100g=60, protein_per_100g=3.5, carb_per_100g=4.7, fat_per_100g=3.3,
    )
    db.add(p)
    db.commit()
    return p


# ------------------------------------------------------------------ malzeme
@pytest.mark.asyncio
async def test_malzeme_gram_ile_hesaplama(db, domates):
    data = MealLogCreate(
        meal_type=MealType.OGLE, ingredient_id=domates.id, quantity_g=200, servings=1,
    )
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.item_name == "Domates"
    assert anlik.calories == pytest.approx(36.0)   # 18 kcal/100g * 200g
    assert anlik.protein_g == pytest.approx(1.8)


@pytest.mark.asyncio
async def test_malzeme_adet_ile_hesaplama(db, yumurta):
    data = MealLogCreate(meal_type=MealType.KAHVALTI, ingredient_id=yumurta.id, servings=2)
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.quantity_g == pytest.approx(100.0)   # 2 adet * 50 g
    assert anlik.calories == pytest.approx(155.0)


@pytest.mark.asyncio
async def test_malzeme_miktar_belirsizse_hata(db, domates):
    data = MealLogCreate(meal_type=MealType.OGLE, ingredient_id=domates.id)
    with pytest.raises(MissingQuantityError):
        await resolve_snapshot(db, None, data)


# ------------------------------------------------------------------ urun
@pytest.mark.asyncio
async def test_urun_serving_size_ile_hesaplama(db, urun):
    data = MealLogCreate(meal_type=MealType.ATISTIRMA, product_id=urun.id, servings=1)
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.quantity_g == pytest.approx(200.0)
    assert anlik.calories == pytest.approx(120.0)


@pytest.mark.asyncio
async def test_urun_quantity_g_serving_size_ustune_gecer(db, urun):
    data = MealLogCreate(
        meal_type=MealType.ATISTIRMA, product_id=urun.id, quantity_g=100, servings=1,
    )
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.calories == pytest.approx(60.0)


@pytest.mark.asyncio
async def test_urun_porsiyon_bilgisi_yoksa_hata(db):
    p = Product(name="Bilinmeyen Urun", calories_per_100g=100)
    db.add(p)
    db.commit()
    data = MealLogCreate(meal_type=MealType.OGLE, product_id=p.id)
    with pytest.raises(MissingQuantityError):
        await resolve_snapshot(db, None, data)


@pytest.mark.asyncio
async def test_servings_carpani_uygulanir(db, urun):
    data = MealLogCreate(meal_type=MealType.OGLE, product_id=urun.id, servings=2)
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.calories == pytest.approx(240.0)


# ------------------------------------------------------------------ serbest giris
@pytest.mark.asyncio
async def test_custom_name_calories_ile(db):
    data = MealLogCreate(
        meal_type=MealType.AKSAM, custom_name="Ev yemegi", calories=450,
        protein_g=20, carb_g=40, fat_g=15,
    )
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.item_name == "Ev yemegi"
    assert anlik.calories == 450


def test_custom_name_tek_basina_calories_zorunlu():
    from pydantic import ValidationError
    with pytest.raises(ValidationError):
        MealLogCreate(meal_type=MealType.AKSAM, custom_name="Ev yemegi")


def test_referansli_girdide_calories_zorunlu_degil():
    data = MealLogCreate(meal_type=MealType.OGLE, ingredient_id=1, quantity_g=100)
    assert data.calories is None


@pytest.mark.asyncio
async def test_custom_name_referansin_ustune_ismi_degistirir(db, urun):
    data = MealLogCreate(
        meal_type=MealType.OGLE, product_id=urun.id, custom_name="Kahvalti yogurdu",
    )
    anlik = await resolve_snapshot(db, None, data)
    assert anlik.item_name == "Kahvalti yogurdu"
    assert anlik.calories == pytest.approx(120.0)   # kalori HALA urunden


# ------------------------------------------------------------------ gunluk ozet - KABUL KRITERI
def _kayit_ekle(db, user, **kwargs):
    varsayilan = dict(
        logged_date=date(2026, 8, 13), source="manuel", item_name="test",
        servings=1, calories=0,
    )
    varsayilan.update(kwargs)
    k = MealLog(user_id=user.id, **varsayilan)
    db.add(k)
    db.commit()
    return k


def test_gunluk_ozet_uc_ogun_toplami_dogru(db, user_with_targets):
    bugun = date(2026, 8, 13)
    _kayit_ekle(db, user_with_targets, logged_date=bugun, meal_type=MealType.KAHVALTI,
               item_name="Yumurta", calories=155, protein_g=13, carb_g=1.1, fat_g=11)
    _kayit_ekle(db, user_with_targets, logged_date=bugun, meal_type=MealType.OGLE,
               item_name="Mercimek Corbasi", calories=220, protein_g=12, carb_g=30, fat_g=4)
    _kayit_ekle(db, user_with_targets, logged_date=bugun, meal_type=MealType.AKSAM,
               item_name="Tavuk Sote", calories=380, protein_g=35, carb_g=10, fat_g=18)

    ozet = get_daily_summary(db, user_with_targets, bugun)

    assert ozet["calories_consumed"] == pytest.approx(755.0)
    assert ozet["calorie_target"] == 2200
    assert ozet["calories_remaining"] == pytest.approx(2200 - 755.0)
    assert ozet["macros_consumed"].protein_g == pytest.approx(60.0)
    assert ozet["macros_consumed"].carb_g == pytest.approx(41.1)
    assert ozet["macros_consumed"].fat_g == pytest.approx(33.0)
    assert len(ozet["meals"]) == 3


def test_gunluk_ozet_baska_gune_sizmaz(db, user_with_targets):
    _kayit_ekle(db, user_with_targets, logged_date=date(2026, 8, 12),
               meal_type=MealType.OGLE, calories=999)
    ozet = get_daily_summary(db, user_with_targets, date(2026, 8, 13))
    assert ozet["calories_consumed"] == 0


def test_gunluk_ozet_baska_kullanicidan_sizmaz(db, user, user_with_targets):
    bugun = date(2026, 8, 13)
    _kayit_ekle(db, user, logged_date=bugun, meal_type=MealType.OGLE, calories=999)
    ozet = get_daily_summary(db, user_with_targets, bugun)
    assert ozet["calories_consumed"] == 0


def test_gunluk_ozet_ogun_tipine_gore_gruplu(db, user_with_targets):
    bugun = date(2026, 8, 13)
    _kayit_ekle(db, user_with_targets, logged_date=bugun, meal_type=MealType.KAHVALTI, calories=100)
    _kayit_ekle(db, user_with_targets, logged_date=bugun, meal_type=MealType.KAHVALTI, calories=50)
    ozet = get_daily_summary(db, user_with_targets, bugun)
    assert len(ozet["meals"][MealType.KAHVALTI]) == 2


def test_profil_yoksa_varsayilan_hedef(db, user):
    ozet = get_daily_summary(db, user, date(2026, 8, 13))
    assert ozet["calorie_target"] == 2000


# ------------------------------------------------------------------ silme
def test_silme_basarili(db, user):
    kayit = _kayit_ekle(db, user, logged_date=date(2026, 8, 13),
                        meal_type=MealType.OGLE, calories=100)
    delete_meal_log(db, user, kayit.id)
    assert db.get(MealLog, kayit.id) is None


def test_silme_baskasinin_kaydini_reddeder(db, user, user_with_targets):
    kayit = _kayit_ekle(db, user, logged_date=date(2026, 8, 13),
                        meal_type=MealType.OGLE, calories=100)
    with pytest.raises(PermissionDeniedError):
        delete_meal_log(db, user_with_targets, kayit.id)