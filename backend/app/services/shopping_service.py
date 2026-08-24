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

from app.core.exceptions import NotFoundError
from app.models import Ingredient, PantryItem, ShoppingListItem, User
from app.models.enums import PantrySource, ShoppingSource
from app.services.ingredient_matcher import match_one
from app.services.pantry_service import confirm_single_ingredient

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

def add_manual(db: Session, user: User, name: str) -> ShoppingListItem:
    """Elle tek oge ekler (W3-T21).

    Yazilan adi sozlukle EslESTIRIR: eslesirse ingredient_id set edilir
    (boylece sonradan kilere aktarilabilir), eslesmezse custom_name olarak
    saklanir. Ayni malzeme listede varsa YENI satir acilmaz.
    """
    temiz = name.strip()
    sonuc = match_one(db, temiz, source="shopping")

    malzeme = None
    if sonuc.canonical_name is not None:
        malzeme = db.scalar(
            select(Ingredient).where(Ingredient.canonical_name == sonuc.canonical_name)
        )

    if malzeme is not None:
        mevcut = db.scalar(
            select(ShoppingListItem).where(
                ShoppingListItem.user_id == user.id,
                ShoppingListItem.ingredient_id == malzeme.id,
            )
        )
        if mevcut is not None:
            mevcut.is_checked = False
            mevcut.checked_at = None
            db.commit()
            db.refresh(mevcut)
            return mevcut

    kayit = ShoppingListItem(
        user_id=user.id,
        ingredient_id=malzeme.id if malzeme else None,
        custom_name=None if malzeme else temiz,
        source=ShoppingSource.MANUEL,
    )
    db.add(kayit)
    db.commit()
    db.refresh(kayit)
    logger.info("Alisveris elle ekleme | kullanici=%s ad=%r eslesti=%s",
                user.id, temiz, malzeme is not None)
    return kayit


def set_checked(db: Session, user: User, item_id: int, *, checked: bool) -> ShoppingListItem:
    """Bir ogeyi isaretli/isaretsiz yapar."""
    from datetime import datetime, timezone

    kayit = db.get(ShoppingListItem, item_id)
    if kayit is None or kayit.user_id != user.id:
        raise NotFoundError("Alisveris kaydi bulunamadi.")

    kayit.is_checked = checked
    kayit.checked_at = datetime.now(timezone.utc).replace(tzinfo=None) if checked else None
    db.commit()
    db.refresh(kayit)
    return kayit


def transfer_to_pantry(
    db: Session, user: User, item_ids: list[int] | None = None
) -> dict:
    """Isaretli ogeleri kilere 'var' olarak aktarir ve listeden siler.

    item_ids verilmezse TUM isaretliler aktarilir. ingredient_id'si
    olmayan (sozlukte eslesmeyen) ogeler aktarilamaz; skipped'e yazilir.
    """
    sorgu = select(ShoppingListItem).where(
        ShoppingListItem.user_id == user.id,
        ShoppingListItem.is_checked.is_(True),
    )
    if item_ids:
        sorgu = sorgu.where(ShoppingListItem.id.in_(item_ids))

    ogeler = list(db.scalars(sorgu))
    aktarilan: list[str] = []
    atlanan: list[str] = []

    for oge in ogeler:
        if oge.ingredient_id is None:
            atlanan.append(oge.custom_name or "?")
            continue
        malzeme = db.get(Ingredient, oge.ingredient_id)
        if malzeme is None:
            atlanan.append(oge.custom_name or "?")
            continue

        confirm_single_ingredient(
            db, user, malzeme, PantrySource.MANUEL, note="Alisveristen kilere aktarildi."
        )
        aktarilan.append(malzeme.display_name)
        db.delete(oge)  # W3-T21: aktarilinca listeden DUSER

    db.commit()
    logger.info("Alisveris -> kiler | kullanici=%s aktarilan=%d atlanan=%d",
                user.id, len(aktarilan), len(atlanan))
    return {"transferred": aktarilan, "skipped": atlanan}