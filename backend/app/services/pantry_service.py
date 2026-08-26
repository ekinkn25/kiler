"""Kiler yazma islemleri.

W2-T10: gorme modeli tespitlerinin onaylanmasi (confirm_detected_ingredients)
W2-T12: confirm_single_ingredient artik barcode_service.py ile PAYLASILIYOR
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models import Ingredient, PantryEvent, PantryItem, User
from app.core.exceptions import NotFoundError
from app.models.enums import Availability, PantryEventType, PantrySource, UnitType

logger = logging.getLogger(__name__)
_ARANMADI = object() 


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


@dataclass(frozen=True, slots=True)
class ConfirmResult:
    confirmed: list[dict]
    skipped_unknown: list[str]


def confirm_single_ingredient(
    # db: Session, user: User, malzeme: Ingredient, source: PantrySource, *, note: str,
    db, user, malzeme, source, *, note: str, mevcut=_ARANMADI,
) -> dict:
    """Tek bir malzemeyi kilere yazar/gunceller + PantryEvent kaydeder.

    COMMIT ETMEZ - cagiran taraf transaction'i kapatir. Foto onayi
    (confirm_detected_ingredients, coklu) ve barkod onayi
    (barcode_service.confirm_scanned_product, tekli) BU FONKSIYONU
    ORTAK KULLANIR.
    """
    kayit = (
        db.scalar(
            select(PantryItem).where(
                PantryItem.user_id == user.id,
                PantryItem.ingredient_id == malzeme.id,
            )
        )
        if mevcut is _ARANMADI
        else mevcut
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


def confirm_detected_ingredients(db, user, canonical_names, source) -> ConfirmResult:
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

    # W4-T13: mevcut kiler satirlari TEK sorguda.
    mevcutlar = {
        k.ingredient_id: k for k in db.scalars(
            select(PantryItem).where(
                PantryItem.user_id == user.id,
                PantryItem.ingredient_id.in_([i.id for i in sozluk.values()]),
            )
        )
    } if sozluk else {}

    onaylanan = [
        confirm_single_ingredient(
            db, user, sozluk[ad], source,
            note=f"Fotograftan tespit edildi ({source.value}), kullanici onayladi.",
            mevcut=mevcutlar.get(sozluk[ad].id),
        )
        for ad in canonical_names if ad in sozluk
    ]
    db.commit()
    logger.info(
        "Kiler onayi | kullanici=%s onaylanan=%d atlanan=%d",
        user.id, len(onaylanan), len(bilinmeyen),
    )
    return ConfirmResult(confirmed=onaylanan, skipped_unknown=bilinmeyen)


# ==================================================================
# Okuma ve hizli durum degistirme (W3-T18)
# ==================================================================
def list_items(
        db:Session, user : User, *, include_finished: bool = False
) -> list[PantryItem]:
    sorgu = (
        select(PantryItem)
        .options(
            joinedload(PantryItem.ingredient).joinedload(Ingredient.category),
            joinedload(PantryItem.product),
        )
        .where(PantryItem.user_id == user.id)
    )
    if not include_finished:
        sorgu = sorgu.where(PantryItem.availability != Availability.BITTI)
    return list(db.scalars(sorgu.order_by(PantryItem.updated_at.desc())))


def set_availability(
    db: Session, user: User, item_id: int, *, target: Availability
) -> PantryItem:
    """Uc durumlu hizli aksiyon (W3-T21).

    VAR        -> 7 gunluk guven suresi BUGUNDEN yeniden baslar
    BILINMIYOR -> guven dusurulur ('Emin degiliz' bolumune duser)
    BITTI      -> kayit 'bitti' olur, listeden duser

    Her durumda PantryEvent yazilir: kiler gecmisi append-only.
    """
    kayit = db.get(PantryItem, item_id)
    # 404 degil 403 ayrimi gereksiz: baskasinin kaydinin VAR oldugunu
    # bile sizdirmiyoruz.
    if kayit is None or kayit.user_id != user.id:
        raise NotFoundError("Kiler kaydi bulunamadi.")

    if target is Availability.VAR:
        kayit.confirm(kayit.source)
        olay = PantryEventType.DUZELTME
        not_metni = "Kullanici 'hala var' dedi, guven suresi yenilendi."
    elif target is Availability.BILINMIYOR:
        kayit.availability = Availability.BILINMIYOR
        kayit.confidence_expires_at = utcnow()  # suresi 'dolmus' say
        olay = PantryEventType.DUZELTME
        not_metni = "Kullanici 'emin degilim' dedi."
    else:  # BITTI
        kayit.mark_finished()
        olay = PantryEventType.TUKETILDI_MANUEL
        not_metni = "Kullanici 'bitti' dedi."

    db.add(PantryEvent(
        user_id=user.id,
        ingredient_id=kayit.ingredient_id,
        pantry_item_id=kayit.id,
        event_type=olay,
        quantity_base_delta=0.0,
        unit_type=UnitType.MASS,
        event_note=not_metni,
    ))

    db.commit()
    db.refresh(kayit)
    logger.info(
        "Kiler durumu | kullanici=%s kayit=%s -> %s",
        user.id, kayit.id, kayit.availability.value,
    )
    return kayit


def add_manual_item(db: Session, user: User, ingredient_id: int) -> PantryItem:
    """Kullanicinin elle sectigi malzemeyi kilere yazar (W3-T21).

    confirm_single_ingredient'i source=MANUEL ile paylasir; foto/barkod
    onayiyla ayni 'var + 7 gun' davranisini uygular.
    """
    malzeme = db.get(Ingredient, ingredient_id)
    if malzeme is None:
        raise NotFoundError("Malzeme bulunamadi.")

    confirm_single_ingredient(
        db, user, malzeme, PantrySource.MANUEL, note="Kullanici elle ekledi."
    )
    db.commit()

    kayit = db.scalar(
        select(PantryItem).where(
            PantryItem.user_id == user.id,
            PantryItem.ingredient_id == ingredient_id,
        )
    )
    logger.info("Kiler elle ekleme | kullanici=%s malzeme=%s", user.id, malzeme.canonical_name)
    return kayit
