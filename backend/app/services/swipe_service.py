"""Swipe destesi ve oturum filtreleme. W2-T07.

Deste uretimi iki veritabanini birlestirir:
  SQLite -> hangi tarifler ELENMELI (oturum gecmisi, geri bildirimler)
  Mongo  -> kalanlari W2-T06 skorlamasiyla sirala

Eleme kumesi Mongo'ya $nin olarak parametre gecer; iki veritabani
arasindaki tek kopru budur.
"""
from __future__ import annotations

import logging
from typing import Any

from bson import ObjectId
from bson.errors import InvalidId
from motor.motor_asyncio import AsyncIOMotorDatabase
from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundError, PermissionDeniedError
from app.db.mongo_schema import RECIPE_COLLECTION
from app.models import User
from app.models.enums import FeedbackAction, FeedbackReason
from app.models.recipe import (
    RecipeFeedback, SwipeSession,
    ids_already_planned, ids_missing_ingredient_recent,
    ids_permanently_disliked, ids_seen_in_session,
)
from app.services.recipe_scoring import build_context, score_recipes

logger = logging.getLogger(__name__)

# 'Cok uzun' denince oturum sure esiginin dusecegi deger (dakika).
COK_UZUN_ESIK_DK = 30

# 'Malzemem yok' elemesinin omru.
MALZEME_YOK_GUN = 7


# ==================================================================
# Oturum
# ==================================================================
def get_or_create_session(
    db: Session, user: User, session_id: int | None
) -> SwipeSession:
    """Oturumu getirir; yoksa yeni acar.

    session_id gonderilmediginde YENI oturum aciyoruz. Alternatif olarak
    'kullanicinin son acik oturumunu bul' da yapilabilirdi ama bu, dun
    yarim birakilan bir oturumun filtrelerini bugune tasirdi - kullanici
    dun 'cok uzun' dediyse bugun de 30 dk siniriyla karsilasirdi.
    """
    if session_id is None:
        oturum = SwipeSession(user_id=user.id)
        db.add(oturum)
        db.commit()
        db.refresh(oturum)
        logger.info("Yeni swipe oturumu: id=%s kullanici=%s", oturum.id, user.id)
        return oturum

    oturum = db.get(SwipeSession, session_id)
    if oturum is None:
        raise NotFoundError("Oturum bulunamadi.")
    if oturum.user_id != user.id:
        # 404 degil 403: oturumun VAR oldugunu biliyoruz, sahibi degil.
        raise PermissionDeniedError("Bu oturum size ait degil.")
    return oturum


# ==================================================================
# Eleme kumesi
# ==================================================================
def build_exclusions(db: Session, user: User, oturum: SwipeSession) -> list[str]:
    """Bu destede GORUNMEYECEK tarif kimlikleri.

    Uc kural, uc farkli omur:
      (a) bu oturumda gorulenler  -> oturum boyu
      (b) 'sevmedim'              -> KALICI
      (d) 'malzeme_yok'           -> 7 gun
    """
    gorulen = set(db.scalars(ids_seen_in_session(oturum.id)))
    sevmedim = set(db.scalars(ids_permanently_disliked(user.id)))
    malzeme_yok = set(db.scalars(
        ids_missing_ingredient_recent(user.id, days=MALZEME_YOK_GUN)
    ))

    # Gorev tanimindaki 4 kuralin DISINDA. W2-T02'de bu yardimci zaten
    # yazilmisti: 'yapacagim'/'kaydettim' denen tarifi 3 gun tekrar
    # gostermek gereksiz. Istemiyorsan bu iki satiri sil.
    planlanan = set(db.scalars(ids_already_planned(user.id)))

    hepsi = gorulen | sevmedim | malzeme_yok | planlanan
    logger.debug(
        "Eleme: gorulen=%d sevmedim=%d malzeme_yok=%d planlanan=%d toplam=%d",
        len(gorulen), len(sevmedim), len(malzeme_yok), len(planlanan), len(hepsi),
    )
    return list(hepsi)


def mark_shown(db: Session, user: User, oturum: SwipeSession, kartlar: list[dict]) -> None:
    """Donen kartlari 'gordu' olarak isaretler.

    KABUL KRITERININ KILIDI: bu yazilmazsa kullanici kaydirmadan ikinci
    kez deste istediginde ayni 10 karti alir.

    'gordu' kaydinin reason'i YOKTUR; dolayisiyla kalici eleme listesine
    girmez, yalnizca ids_seen_in_session'a takilir.
    """
    for kart in kartlar:
        db.add(RecipeFeedback(
            user_id=user.id,
            recipe_id=kart["id"],
            session_id=oturum.id,
            action=FeedbackAction.GORDU,
        ))
    oturum.shown_count += len(kartlar)
    db.commit()


# ==================================================================
# Deste
# ==================================================================
async def build_deck(
    db: Session,
    mongo_db: AsyncIOMotorDatabase,
    user: User,
    *,
    session_id: int | None = None,
    limit: int = 10,
) -> dict[str, Any]:
    """Swipe destesini uretir ve gorulen olarak isaretler."""
    oturum = get_or_create_session(db, user, session_id)
    elenecek = build_exclusions(db, user, oturum)

    # (c) Oturumda 'cok uzun' denmisse esik burada devreye girer.
    sure_tavani = oturum.filters.get("max_total_time")

    ctx = build_context(db, user, max_total_minutes=sure_tavani)
    kartlar = await score_recipes(
        mongo_db, ctx, limit=limit, exclude_ids=elenecek
    )

    if kartlar:
        mark_shown(db, user, oturum, kartlar)

    logger.info(
        "Deste | oturum=%s kullanici=%s istenen=%d donen=%d elenen=%d sure_tavani=%s",
        oturum.id, user.id, limit, len(kartlar), len(elenecek), sure_tavani,
    )

    return {
        "session_id": oturum.id,
        "items": kartlar,
        "returned": len(kartlar),
        "requested": limit,
        # Istemci 'deste bitti, filtreleri gevset' ekranini bununla acar.
        "exhausted": len(kartlar) < limit,
        "session_filters": oturum.filters,
        "excluded_count": len(elenecek),
    }


# ==================================================================
# Geri bildirim
# ==================================================================
async def record_swipe(
    db: Session,
    mongo_db: AsyncIOMotorDatabase,
    user: User,
    recipe_id: str,
    *,
    action: FeedbackAction,
    reason: FeedbackReason | None = None,
    session_id: int | None = None,
    missing_ingredient_id: int | None = None,
    rating: int | None = None,
    servings_cooked: float | None = None,
    comment: str | None = None,
) -> tuple[RecipeFeedback, SwipeSession | None, str]:
    """Geri bildirimi yazar ve oturum filtresine etkisini uygular.

    Doner: (kayit, oturum, insan_okunur_etki)
    """
    try:
        nesne_kimlik = ObjectId(recipe_id)
    except (InvalidId, TypeError) as exc:
        raise NotFoundError("Gecersiz tarif kimligi.") from exc

    # Var olmayan tarife geri bildirim yazmak ogrenme verisini kirletir.
    # Tek indeksli sorgu; maliyeti ihmal edilebilir.
    varmi = await mongo_db[RECIPE_COLLECTION].find_one(
        {"_id": nesne_kimlik}, projection={"_id": 1}
    )
    if varmi is None:
        raise NotFoundError("Tarif bulunamadi.")

    oturum = None
    if session_id is not None:
        oturum = get_or_create_session(db, user, session_id)

    kayit = RecipeFeedback(
        user_id=user.id,
        recipe_id=recipe_id,
        session_id=oturum.id if oturum else None,
        action=action,
        reason=reason,
        missing_ingredient_id=missing_ingredient_id,
        rating=rating,
        servings_cooked=servings_cooked,
        comment=comment,
    )
    db.add(kayit)

    # (c) 'Cok uzun' bir ELEME degil, oturum filtresinin daralmasidir.
    # tighten_time_limit min() kullanir: esik daralir, asla gevsemez.
    etki = "kaydedildi"
    if reason == FeedbackReason.COK_UZUN and oturum is not None:
        onceki = oturum.filters.get("max_total_time")
        oturum.tighten_time_limit(COK_UZUN_ESIK_DK)
        etki = (f"Oturum sure siniri {oturum.filters['max_total_time']} dk'ya "
                f"dusuruldu (onceki: {onceki or 'yok'}).")
    elif reason == FeedbackReason.SEVMEDIM:
        etki = "Bu tarif bir daha hic onerilmeyecek."
    elif reason == FeedbackReason.MALZEME_YOK:
        etki = f"Bu tarif {MALZEME_YOK_GUN} gun boyunca onerilmeyecek."

    db.commit()
    db.refresh(kayit)

    logger.info(
        "Swipe | kullanici=%s tarif=%s eylem=%s sebep=%s -> %s",
        user.id, recipe_id, action.value, reason.value if reason else "-", etki,
    )
    return kayit, oturum, etki