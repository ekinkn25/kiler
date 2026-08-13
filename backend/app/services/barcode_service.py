"""Barkod -> urun -> kiler akisi. W2-T12.

Iki asamali: (1) scan_barcode onbellek/OFF'tan urunu getirir ve ONAY
EKRANINA doner - kilere HICBIR SEY YAZILMAZ. (2) confirm_scanned_product
kullanicinin onayladigi urunu kilere yazar.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError
from app.models import Ingredient, Product, User
from app.models.enums import PantrySource, ProductSource
from app.models.pantry import utcnow
from app.schemas import ProductCreate
from app.services.ingredient_matcher import get_lookup, match_name
from app.services.openfoodfacts import fetch_product
from app.services.pantry_service import confirm_single_ingredient

logger = logging.getLogger(__name__)


class IngredientRequiredError(AppError):
    status_code = 422
    code = "ingredient_required"
    message = "Bu urun sozlukteki bir malzemeyle eslesmedi; ingredient_id belirt."


@dataclass(frozen=True, slots=True)
class ScanResult:
    found: bool
    product: Product | None
    matched_ingredient: Ingredient | None
    from_cache: bool


def _taze_mi(urun: Product) -> bool:
    if urun.fetched_at is None:
        return False
    return utcnow() - urun.fetched_at < timedelta(days=settings.OFF_CACHE_DAYS)


def _malzeme_eslestir(db: Session, urun_adi: str) -> Ingredient | None:
    """Urun adindan sozlukte KESIN bir eslesme arar (T05). Bulanik
    eslesme BILEREK kullanilmiyor: urun adlarinda marka+isim karisimi
    yanlis eslesme riskini buyutur (bkz. T05'teki token_set_ratio tuzagi)."""
    lookup = get_lookup(db)
    sonuc = match_name(urun_adi, lookup)
    if sonuc.canonical_name and sonuc.matched_by in ("canonical", "alias", "canonical_ek"):
        return db.scalar(
            select(Ingredient).where(Ingredient.canonical_name == sonuc.canonical_name)
        )
    return None


async def scan_barcode(db: Session, barcode: str) -> ScanResult:
    """Onbellege, yoksa OFF'a bakar. Kilere HICBIR SEY YAZMAZ."""
    urun = db.scalar(select(Product).where(Product.barcode == barcode))

    if urun is not None and _taze_mi(urun):
        eslesen = db.get(Ingredient, urun.ingredient_id) if urun.ingredient_id else None
        logger.info("Barkod onbellekten karsilandi: %s", barcode)
        return ScanResult(found=True, product=urun, matched_ingredient=eslesen, from_cache=True)

    off_urun = await fetch_product(barcode)
    if off_urun is None:
        logger.info("Barkod OFF'ta bulunamadi: %s", barcode)
        return ScanResult(found=False, product=None, matched_ingredient=None, from_cache=False)

    eslesen = _malzeme_eslestir(db, off_urun.name) if off_urun.name else None

    if urun is None:
        urun = Product(barcode=barcode)
        db.add(urun)

    urun.name = off_urun.name or urun.name or barcode
    urun.brand = off_urun.brand
    urun.calories_per_100g = off_urun.calories_per_100g
    urun.protein_per_100g = off_urun.protein_per_100g
    urun.carb_per_100g = off_urun.carb_per_100g
    urun.fat_per_100g = off_urun.fat_per_100g
    urun.fiber_per_100g = off_urun.fiber_per_100g
    urun.sugar_per_100g = off_urun.sugar_per_100g
    urun.sodium_mg_per_100g = off_urun.sodium_mg_per_100g
    urun.image_url = off_urun.image_url
    urun.serving_size_g = off_urun.serving_size_g
    urun.source = ProductSource.OPENFOODFACTS
    urun.fetched_at = utcnow()
    if eslesen is not None and urun.ingredient_id is None:
        urun.ingredient_id = eslesen.id

    db.commit()
    db.refresh(urun)

    logger.info(
        "Barkod OFF'tan cekildi: %s -> '%s' (eslesen malzeme: %s)",
        barcode, urun.name, eslesen.canonical_name if eslesen else "-",
    )
    return ScanResult(found=True, product=urun, matched_ingredient=eslesen, from_cache=False)


def create_manual_product(db: Session, data: ProductCreate) -> Product:
    """Barkod OFF'ta bulunamayinca kullanicinin elle girdigi urun."""
    urun = Product(
        barcode=data.barcode, name=data.name, brand=data.brand,
        package_quantity=data.package_quantity, package_unit=data.package_unit,
        calories_per_100g=data.calories_per_100g,
        source=ProductSource.USER, fetched_at=utcnow(),
    )
    db.add(urun)
    db.commit()
    db.refresh(urun)
    logger.info("Manuel urun eklendi: '%s' (barkod=%s)", data.name, data.barcode)
    return urun


def confirm_scanned_product(
    db: Session, user: User, product_id: int, ingredient_id: int | None,
) -> dict:
    """Onaylanan urunu kilere yazar. PantryItem.ingredient_id NOT NULL
    oldugu icin urun bir malzemeyle eslesmek ZORUNDA - eslesme yoksa
    istemci ingredient_id'yi ELLE vermeli."""
    urun = db.get(Product, product_id)
    if urun is None:
        raise NotFoundError("Urun bulunamadi.")

    hedef_ingredient_id = ingredient_id or urun.ingredient_id
    if hedef_ingredient_id is None:
        raise IngredientRequiredError()

    malzeme = db.get(Ingredient, hedef_ingredient_id)
    if malzeme is None:
        raise NotFoundError("Malzeme bulunamadi.")

    # Kullanici farkli bir malzeme sectiyse urunu de ogret - bir dahaki
    # tarama otomatik eslesir.
    if urun.ingredient_id is None:
        urun.ingredient_id = malzeme.id

    sonuc = confirm_single_ingredient(
        db, user, malzeme, PantrySource.BARKOD,
        note=f"Barkod tarandi: {urun.barcode or '-'} ({urun.name}).",
    )
    sonuc["product_id"] = urun.id
    db.commit()
    return sonuc