"""Kiler yazma islemleri. W2-T10: gorme modeli tespitlerinin onaylanmasi.

DIKKAT: Bu servis GORME MODELINI CAGIRMAZ. detect_ingredients() (W2-T04)
zaten calisip malzeme ADAYLARINI uretmisti; burasi yalnizca kullanicinin
ONAYLADIGI adaylari pantry_items'a YAZAR. Onay olmadan hicbir foto
tespiti kilere gitmez - W2-T10'un temel guvenlik/UX kurali budur.
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
    confirmed: list[dict]           # yazilan malzemeler
    skipped_unknown: list[str]      # sozlukte olmayan canonical_name'ler


def confirm_detected_ingredients(
    db: Session, user: User, canonical_names: list[str], source: PantrySource,
) -> ConfirmResult:
    """Onaylanan malzemeleri kilere yazar.

    Her malzeme icin PantryItem.confirm() cagrilir (W2-T02'de yazilmisti):
    availability='var', confirmed_at=simdi,
    confidence_expires_at=simdi+PANTRY_CONFIDENCE_DAYS (varsayilan 7 gun).

    Var olan kayit varsa GUNCELLENIR (sure yeniden baslar), yoksa
    OLUSTURULUR - boylece ayni malzeme iki kez fotograflanirsa
    uq_pantry_user_ingredient kisitina CARPMAZ.
    """
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

    onaylanan: list[dict] = []
    for ad in canonical_names:
        malzeme = sozluk.get(ad)
        if malzeme is None:
            continue

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
        db.flush()  # kayit.id'yi PantryEvent icin garanti eder

        db.add(PantryEvent(
            user_id=user.id, ingredient_id=malzeme.id, pantry_item_id=kayit.id,
            event_type=PantryEventType.EKLENDI,
            # Fotograftan gelen tespitte MIKTAR bilinmiyor - bu bir VARLIK
            # teyidi, miktar hareketi degil. quantity_base_delta NOT NULL
            # oldugu icin 0 yaziyoruz.
            quantity_base_delta=0.0, unit_type=UnitType.MASS,
            event_note=f"Fotograftan tespit edildi ({source.value}), kullanici onayladi.",
        ))

        onaylanan.append({
            "ingredient_id": malzeme.id,
            "canonical_name": malzeme.canonical_name,
            "display_name": malzeme.display_name,
            "availability": kayit.availability.value,
            "confidence_expires_at": kayit.confidence_expires_at,
            "is_new": yeni_kayit,
        })

    db.commit()
    logger.info(
        "Kiler onayi | kullanici=%s onaylanan=%d atlanan=%d",
        user.id, len(onaylanan), len(bilinmeyen),
    )
    return ConfirmResult(confirmed=onaylanan, skipped_unknown=bilinmeyen)