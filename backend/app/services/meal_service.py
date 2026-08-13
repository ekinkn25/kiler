"""Öğün kaydı iş mantığı

ANLIK GORUNTU ILKESI: resolve_snapshot() calisma anindaki degerleri
KOPYALAR. Urun/tarif sonradan degisse bile gecmis kayitlar ETKILENMEZ -
MealLog modelinin kendi docstring'i de bunu vurguluyor.

Uc kaynak + serbest giris:
  product_id    -> Product.calories_per_100g
  ingredient_id -> Ingredient.calories_per_100g
  recipe_id     -> Mongo tarifin calories_per_serving (zaten PORSIYON BASI)
  custom_name   -> data.calories (istemciden, sema seviyesinde zorunlu kilinir)
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, replace
from datetime import date

from bson import ObjectId
from bson.errors import InvalidId
from motor.motor_asyncio import AsyncIOMotorDatabase
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AppError, NotFoundError, PermissionDeniedError
from app.db.mongo_schema import RECIPE_COLLECTION
from app.models import Ingredient, MealLog, Product, User
from app.models.enums import UnitType
from app.schemas import MacroBreakdown, MealLogCreate

logger = logging.getLogger(__name__)


class MissingQuantityError(AppError):
    status_code = 422
    code = "missing_quantity"
    message = "Bu kalem icin miktar belirsiz; quantity_g gonder."


# Anlik goruntu
@dataclass(frozen=True, slots=True)
class MealSnapshot:
    item_name: str
    calories: float
    protein_g: float | None
    carb_g: float | None
    fat_g: float | None
    fiber_g: float | None
    sugar_g: float | None
    sodium_mg: float | None
    quantity_g: float | None
    ingredients: list[str]


def _carp(deger: float | None, oran: float) -> float | None:
    return round(deger * oran, 2) if deger is not None else None


def _resolve_from_product(db: Session, data: MealLogCreate) -> MealSnapshot:
    urun = db.get(Product, data.product_id)
    if urun is None:
        raise NotFoundError("Ürün bulunamadı.")

    baz_gram = data.quantity_g if data.quantity_g is not None else urun.serving_size_g
    if baz_gram is None:
        raise MissingQuantityError(
            f"'{urun.name}' için tanımlı porsiyon büyüklüğü yok; quantity_g gönder."
        )
    toplam_gram = baz_gram * data.servings
    oran = toplam_gram / 100.0

    return MealSnapshot(
        item_name=urun.name,
        calories=round((urun.calories_per_100g or 0) * oran, 1),
        protein_g=_carp(urun.protein_per_100g, oran),
        carb_g=_carp(urun.carb_per_100g, oran),
        fat_g=_carp(urun.fat_per_100g, oran),
        fiber_g=_carp(urun.fiber_per_100g, oran),
        sugar_g=_carp(urun.sugar_per_100g, oran),
        sodium_mg=_carp(urun.sodium_mg_per_100g, oran),
        quantity_g=round(toplam_gram, 1),
        ingredients=[],
    )


def _resolve_from_ingredient(db: Session, data: MealLogCreate) -> MealSnapshot:
    malzeme = db.get(Ingredient, data.ingredient_id)
    if malzeme is None:
        raise NotFoundError("Malzeme bulunamadı.")

    if data.quantity_g is not None:
        baz_gram = data.quantity_g
    elif malzeme.default_unit_type == UnitType.COUNT and malzeme.grams_per_piece:
        # 'servings' burada ADET anlamina gelir: 2 yumurta -> 2 * grams_per_piece
        baz_gram = malzeme.grams_per_piece
    else:
        raise MissingQuantityError(
            f"'{malzeme.display_name}' için miktar belirtilmemiş; quantity_g gönder."
        )
    toplam_gram = baz_gram * data.servings
    oran = toplam_gram / 100.0

    return MealSnapshot(
        item_name=malzeme.display_name,
        calories=round((malzeme.calories_per_100g or 0) * oran, 1),
        protein_g=_carp(malzeme.protein_per_100g, oran),
        carb_g=_carp(malzeme.carb_per_100g, oran),
        fat_g=_carp(malzeme.fat_per_100g, oran),
        fiber_g=_carp(malzeme.fiber_per_100g, oran),
        sugar_g=_carp(malzeme.sugar_per_100g, oran),
        sodium_mg=_carp(malzeme.sodium_mg_per_100g, oran),
        quantity_g=round(toplam_gram, 1),
        ingredients=[],
    )


async def _resolve_from_recipe(mongo_db: AsyncIOMotorDatabase, data: MealLogCreate) -> MealSnapshot:
    try:
        oid = ObjectId(data.recipe_id)
    except (InvalidId, TypeError) as exc:
        raise NotFoundError("Geçersiz tarif kimliği.") from exc

    tarif = await mongo_db[RECIPE_COLLECTION].find_one({"_id": oid})
    if tarif is None:
        raise NotFoundError("Tarif bulunamadı.")

    # Recipe.macros zaten PORSIYON BASI (calories_per_serving ile ayni olcekte); T08'deki cig-pismis donusumu burada GEREKMEZ.
    makro = tarif.get("macros") or {}
    kanonikler = [
        m["canonical_name"] for m in tarif.get("ingredients", [])
        if m.get("canonical_name")
    ]

    return MealSnapshot(
        item_name=tarif.get("title", "Tarif"),
        calories=round(float(tarif.get("calories_per_serving") or 0) * data.servings, 1),
        protein_g=round(float(makro.get("protein_g") or 0) * data.servings, 2),
        carb_g=round(float(makro.get("carb_g") or 0) * data.servings, 2),
        fat_g=round(float(makro.get("fat_g") or 0) * data.servings, 2),
        fiber_g=round(float(makro.get("fiber_g") or 0) * data.servings, 2),
        sugar_g=None,
        sodium_mg=None,
        quantity_g=data.quantity_g,
        ingredients=kanonikler,
    )


def _resolve_from_custom(data: MealLogCreate) -> MealSnapshot:
    # Şema seviyesinde doğrulandı: calories burada MUTLAKA dolu.
    return MealSnapshot(
        item_name=data.custom_name,
        calories=round(data.calories, 1),
        protein_g=data.protein_g,
        carb_g=data.carb_g,
        fat_g=data.fat_g,
        fiber_g=data.fiber_g,
        sugar_g=None,
        sodium_mg=None,
        quantity_g=data.quantity_g,
        ingredients=[],
    )


async def resolve_snapshot(
    db: Session, mongo_db: AsyncIOMotorDatabase | None, data: MealLogCreate,
) -> MealSnapshot:
    """Kaynağa gore anlık görüntüyü hesaplar. Öncelik: ürün > malzeme > tarif > serbest."""
    if data.product_id is not None:
        anlik = _resolve_from_product(db, data)
    elif data.ingredient_id is not None:
        anlik = _resolve_from_ingredient(db, data)
    elif data.recipe_id is not None:
        anlik = await _resolve_from_recipe(mongo_db, data)
    else:
        anlik = _resolve_from_custom(data)

    # custom_name bir referansla birlikte geldiyse gorünen adı değiştirir, kalori HALA referanstan hesaplanır.
    if data.custom_name and (data.product_id or data.ingredient_id or data.recipe_id):
        anlik = replace(anlik, item_name=data.custom_name)

    return anlik


# CRUD
async def create_meal_log(
    db: Session, mongo_db: AsyncIOMotorDatabase, user: User, data: MealLogCreate,
) -> MealLog:
    anlik = await resolve_snapshot(db, mongo_db, data)

    kayit = MealLog(
        user_id=user.id,
        logged_date=data.logged_date,
        meal_type=data.meal_type,
        source=data.source,
        product_id=data.product_id,
        ingredient_id=data.ingredient_id,
        recipe_id=data.recipe_id,
        item_name=anlik.item_name,
        servings=data.servings,
        quantity_g=anlik.quantity_g,
        calories=anlik.calories,
        protein_g=anlik.protein_g,
        carb_g=anlik.carb_g,
        fat_g=anlik.fat_g,
        fiber_g=anlik.fiber_g,
        sugar_g=anlik.sugar_g,
        sodium_mg=anlik.sodium_mg,
        local_hour=data.local_hour,
    )
    if anlik.ingredients:
        kayit.set_ingredients(anlik.ingredients)

    db.add(kayit)
    db.commit()
    db.refresh(kayit)

    logger.info(
        "Öğün kaydedildi | kullanici=%s tarih=%s tip=%s kaynak=%s kcal=%.0f",
        user.id, data.logged_date, data.meal_type.value, data.source.value, anlik.calories,
    )
    return kayit


def get_daily_summary(db: Session, user: User, hedef_tarih: date) -> dict:
    """Verilen günün tüm kayıtlarını toplar ve öğün tipine göre gruplar."""
    kayitlar = db.scalars(
        select(MealLog)
        .where(MealLog.user_id == user.id, MealLog.logged_date == hedef_tarih)
        .order_by(MealLog.created_at)
    ).all()

    profil = user.profile
    hedef_kcal = float(profil.daily_calorie_target) if profil else 2000.0

    toplam_kcal = sum(k.calories for k in kayitlar)
    makro_tuketilen = MacroBreakdown(
        protein_g=round(sum(k.protein_g or 0 for k in kayitlar), 1),
        carb_g=round(sum(k.carb_g or 0 for k in kayitlar), 1),
        fat_g=round(sum(k.fat_g or 0 for k in kayitlar), 1),
        fiber_g=round(sum(k.fiber_g or 0 for k in kayitlar), 1),
    )
    makro_hedef = MacroBreakdown(
        protein_g=float(profil.protein_target_g) if profil and profil.protein_target_g else 0,
        carb_g=float(profil.carb_target_g) if profil and profil.carb_target_g else 0,
        fat_g=float(profil.fat_target_g) if profil and profil.fat_target_g else 0,
        # UserProfile'da fiber hedefi tanimli degil (W2-T13 kapsaminda eklenebilir); simdilik 0.
        fiber_g=0,
    )

    gruplu: dict = {}
    for k in kayitlar:
        gruplu.setdefault(k.meal_type, []).append(k)

    return {
        "logged_date": hedef_tarih,
        "calorie_target": hedef_kcal,
        "calories_consumed": round(toplam_kcal, 1),
        "calories_remaining": round(hedef_kcal - toplam_kcal, 1),
        "macros_consumed": makro_tuketilen,
        "macros_target": makro_hedef,
        "meals": gruplu,
    }


def delete_meal_log(db: Session, user: User, meal_id: int) -> None:
    kayit = db.get(MealLog, meal_id)
    if kayit is None:
        raise NotFoundError("Ogun kaydi bulunamadi.")
    if kayit.user_id != user.id:
        raise PermissionDeniedError("Bu ogun kaydi size ait degil.")
    db.delete(kayit)
    db.commit()
    logger.info("Ogun kaydi silindi | kullanici=%s id=%s", user.id, meal_id)