"""Kiler yazma islemleri.

W2-T10: gorme modeli tespitlerinin onaylanmasi (confirm_detected_ingredients)
W2-T12: confirm_single_ingredient artik barcode_service.py ile PAYLASILIYOR
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Ingredient, PantryEvent, PantryItem, User
from app.models.enums import PantryEventType, PantrySource, UnitType

logger = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class ConfirmResult:
    confirmed: list[dict]
    skipped_unknown: list[str]


def confirm_single_ingredient(
    db: Session, user: User, malzeme: Ingredient, source: PantrySource, *, note: str,
) -> dict:
    """Tek bir malzemeyi kilere yazar/gunceller + PantryEvent kaydeder.

    COMMIT ETMEZ - cagiran taraf transaction'i kapatir. Foto onayi
    (confirm_detected_ingredients, coklu) ve barkod onayi
    (barcode_service.confirm_scanned_product, tekli) BU FONKSIYONU
    ORTAK KULLANIR.
    """
    kayit = db.scalar(
        select(PantryItem).where(
            PantryItem.user_id == user.id, PantryItem.ingredient_id == malzeme.id,
        )
    )
    yeni_kayit = kayit is None
    if yeni_kayit:
        kayit = PantryItem(user_id=user.id, ingredient_id=malzeme.id)
        db.add(kayit)

    kayit.confirm(source)
    db.flush()

    db.add(PantryEvent(
        user_id=user.id, ingredient_id=malzeme.id, pantry_item_id=kayit.id,
        event_type=PantryEventType.EKLENDI,
        quantity_base_delta=0.0, unit_type=UnitType.MASS,
        event_note=note,
    ))

    return {
        "ingredient_id": malzeme.id,
        "canonical_name": malzeme.canonical_name,
        "display_name": malzeme.display_name,
        "availability": kayit.availability.value,
        "confidence_expires_at": kayit.confidence_expires_at,
        "is_new": yeni_kayit,
    }


def confirm_detected_ingredients(
    db: Session, user: User, canonical_names: list[str], source: PantrySource,
) -> ConfirmResult:
    """Onaylanan (fotograftan tespit edilen) malzemeleri kilere yazar."""
    sozluk = {
        i.canonical_name: i for i in db.scalars(
            select(Ingredient).where(Ingredient.canonical_name.in_(canonical_names))
        )
    }
    bilinmeyen = [ad for ad in canonical_names if ad not in sozluk]
    if bilinmeyen:
        logger.warning(
            "Onaylanan malzemelerden bazilari sozlukte yok, atlandi: %s", bilinmeyen
        )

    onaylanan = [
        confirm_single_ingredient(
            db, user, sozluk[ad], source,
            note=f"Fotograftan tespit edildi ({source.value}), kullanici onayladi.",
        )
        for ad in canonical_names if ad in sozluk
    ]

    db.commit()
    logger.info(
        "Kiler onayi | kullanici=%s onaylanan=%d atlanan=%d",
        user.id, len(onaylanan), len(bilinmeyen),
    )
    return ConfirmResult(confirmed=onaylanan, skipped_unknown=bilinmeyen)