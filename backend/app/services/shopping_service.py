"""Alisveris listesi. W3-T09: swipe'ta 'malzemem yok' denen malzemeler buraya duser.

DIKKAT: tabloda (user_id, ingredient_id) ESSIZ kisiti var. Ayni malzemeyi
ikinci kez INSERT etmeye calismak IntegrityError -> 500 demektir; bu yuzden
ekleme mantigi 'varsa guncelle, yoksa ekle' seklinde yazildi.
"""
from __future__ import annotations

import logging
from typing import Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Ingredient, ShoppingListItem, User
from app.models.enums import ShoppingSource

logger = logging.getLogger(__name__)


def list_items(
    db: Session, user: User, *, include_checked: bool = True
) -> list[ShoppingListItem]:
    """Kullanicinin alisveris listesi, en yeni ustte."""
    sorgu = select(ShoppingListItem).where(ShoppingListItem.user_id == user.id)
    if not include_checked:
        sorgu = sorgu.where(ShoppingListItem.is_checked.is_(False))
    return list(db.scalars(sorgu.order_by(ShoppingListItem.created_at.desc())))


def add_from_recipe(
    db: Session,
    user: User,
    *,
    recipe_id: str,
    items: Sequence,  # ShoppingItemCreate
    source: ShoppingSource = ShoppingSource.TARIF,
) -> list[ShoppingListItem]:
    """Tarif kaynakli toplu ekleme.

    UYGULANAN KURALLAR:
      - Malzeme listede ZATEN varsa yeni satir acilmaz, var olan
        GUNCELLENIR (essiz kisit ihlali onlenir).
      - Var olan satir 'alindi' isaretliyse isaret KALDIRILIR: kullanici
        malzemeyi yeniden istiyor demektir.
      - Ayni istekteki tekrarli kimlikler TEKILLESTIRILIR.
      - Sozlukte olmayan ingredient_id sessizce ATLANIR; tek hatali kimlik
        yuzunden butun toplu eklemeyi dusurmek dogru olmaz.
      - custom_name'li satirlarda essiz kisit yok (ingredient_id NULL),
        her biri ayri satir olur.
    """
    sonuc: list[ShoppingListItem] = []
    islenen: set[int] = set()

    for istek in items:
        if istek.ingredient_id is not None:
            if istek.ingredient_id in islenen:
                continue
            islenen.add(istek.ingredient_id)

            if db.get(Ingredient, istek.ingredient_id) is None:
                logger.warning(
                    "Bilinmeyen malzeme kimligi atlandi: %s", istek.ingredient_id
                )
                continue

            mevcut = db.scalar(
                select(ShoppingListItem).where(
                    ShoppingListItem.user_id == user.id,
                    ShoppingListItem.ingredient_id == istek.ingredient_id,
                )
            )
            if mevcut is not None:
                mevcut.is_checked = False
                mevcut.checked_at = None
                mevcut.source = source
                mevcut.source_recipe_id = recipe_id
                if istek.quantity is not None:
                    mevcut.quantity = istek.quantity
                    mevcut.unit = istek.unit
                if istek.item_note:
                    mevcut.item_note = istek.item_note
                sonuc.append(mevcut)
                continue

        kayit = ShoppingListItem(
            user_id=user.id,
            ingredient_id=istek.ingredient_id,
            custom_name=istek.custom_name,
            quantity=istek.quantity,
            unit=istek.unit,
            source=source,
            source_recipe_id=recipe_id,
            item_note=istek.item_note,
        )
        db.add(kayit)
        sonuc.append(kayit)

    db.commit()
    for kayit in sonuc:
        db.refresh(kayit)

    logger.info(
        "Alisveris listesi | kullanici=%s tarif=%s eklenen/guncellenen=%d",
        user.id, recipe_id, len(sonuc),
    )
    return sonuc