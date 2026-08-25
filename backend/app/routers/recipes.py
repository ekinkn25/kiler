"""Tarif uclari. W2-T07: swipe destesi ve geri bildirim."""
import logging
from datetime import timedelta

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import APIRouter, Query, status
from sqlalchemy import func, select

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.core.exceptions import NotFoundError
from app.db.mongo_schema import RECIPE_COLLECTION
from app.models.enums import FeedbackAction
from app.models.recipe import RecipeFeedback, utcnow
from app.schemas import (
    DeckResponse, ErrorResponse, RecipeCard, SwipeRequest, SwipeResponse, RecipeRead,
)
from app.services import swipe_service

logger = logging.getLogger(__name__)

router = APIRouter()

MAX_CARD_IDS = 30

def parse_card_ids(ids: str, *, limit: int = MAX_CARD_IDS) -> list[str]:
    """Virgullu metni SIRAYI KORUYARAK tekil kimlik listesine cevirir."""
    parcalar = [p.strip() for p in ids.split(",") if p.strip()]
    return list(dict.fromkeys(parcalar))[:limit]


def order_like_request(dokumanlar: list[dict], istenen: list[str]) -> list[dict]:
    """Sonucu ISTEK SIRASINA gore dizer.

    Mongo'nun $in sonucu istek sirasini KORUMAZ. Sohbet, tarifleri onem
    sirasiyla oneriyor; kartlarin sirasi degisirse 'en cok onerilen' ustte
    durmaz. Bulunamayan kimlikler sessizce dusulur.
    """
    harita = {str(d["_id"]): d for d in dokumanlar}
    return [harita[k] for k in istenen if k in harita]

async def fetch_cards(mongo_db, istenen: list[str]) -> list[RecipeCard]:
    """Kimlik listesinden SIRAYI KORUYARAK kart verisi ceker.

    /cards ve /planned bu yardimciyi paylasir.
    """
    nesne_kimlikleri = []
    for kimlik in istenen:
        try:
            nesne_kimlikleri.append(ObjectId(kimlik))
        except (InvalidId, TypeError):
            logger.warning("Gecersiz tarif kimligi atlandi: %r", kimlik)
    if not nesne_kimlikleri:
        return []

    imlec = mongo_db[RECIPE_COLLECTION].find(
        {"_id": {"$in": nesne_kimlikleri}, "is_active": {"$ne": False}},
        projection={
            "_id": 1, "title": 1, "slug": 1, "image_url": 1,
            "calories_per_serving": 1, "servings": 1,
            "prep_time": 1, "cook_time": 1, "difficulty": 1, "diet_tags": 1,
        },
    )
    dokumanlar = await imlec.to_list(length=len(nesne_kimlikleri))
    sirali = order_like_request(dokumanlar, istenen)
    return [RecipeCard.model_validate(d) for d in sirali]

@router.get(
    "/cards",
    response_model=list[RecipeCard],
    response_model_by_alias = False,
    summary="Kimlige gore tarif kartlari",
    description=(
        "Virgulle ayrilmis tarif kimlikleri icin SADE kart verisi doner: "
        "fotograf, baslik, kalori, sure, zorluk, diyet etiketleri.\n\n"
        "NEDEN VAR: sohbet yanitindaki `onerilen_tarif_idleri` yalnizca "
        "kimlik tasir; mini kartlar bu uctan beslenir. Ayni uc tarif "
        "detay ekraninin iskeletini de doldurur (W4-T01).\n\n"
        "Sonuc ISTEK SIRASINI korur. Gecersiz veya bulunamayan kimlikler "
        "sessizce atlanir - tek hatali kimlik yuzunden butun istegi "
        "dusurmek dogru olmaz."
    ),
    responses={status.HTTP_403_FORBIDDEN: {"model": ErrorResponse}},
)
async def get_cards(
    mongo_db: MongoDb,
    current_user: ActiveUser,
    ids: str = Query(
        ...,
        min_length=1,
        description="Virgulle ayrilmis tarif kimlikleri (24 karakter ObjectId).",
    ),
) -> list[RecipeCard]:
    kartlar = await fetch_cards(mongo_db, parse_card_ids(ids))
    logger.info("Kart istegi | donen=%d", len(kartlar))
    return kartlar
    # istenen = parse_card_ids(ids)
    # if not istenen:
    #     return []

    # nesne_kimlikleri = []
    # for kimlik in istenen:
    #     try:
    #         nesne_kimlikleri.append(ObjectId(kimlik))
    #     except (InvalidId, TypeError):
    #         logger.warning("Gecersiz tarif kimligi atlandi: %r", kimlik)

    # if not nesne_kimlikleri:
    #     return []

    # imlec = mongo_db[RECIPE_COLLECTION].find(
    #     {"_id": {"$in": nesne_kimlikleri}, "is_active": {"$ne": False}},
    #     projection={
    #         "_id": 1, "title": 1, "slug": 1, "image_url": 1,
    #         "calories_per_serving": 1, "servings": 1,
    #         "prep_time": 1, "cook_time": 1, "difficulty": 1, "diet_tags": 1,
    #     },
    # )
    # dokumanlar = await imlec.to_list(length=len(nesne_kimlikleri))

    # sirali = order_like_request(dokumanlar, istenen)
    # logger.info("Kart istegi | istenen=%d donen=%d", len(istenen), len(sirali))
    # return [RecipeCard.model_validate(d) for d in sirali]


@router.get(
    "/planned",
    response_model=list[RecipeCard],
    summary="Yapacaklarim",
    description=(
        "Kullanicinin son 7 gunde 'Yapacagim' dedigi tarifler, en yeni "
        "ustte. Kesfet ekranindaki 'Yapacaklarim' sekmesini besler."
    ),
)
async def get_planned(
    db: DbSession,
    mongo_db: MongoDb,
    current_user: ActiveUser,
) -> list[RecipeCard]:
    # Ayni tarife birden cok 'yapacagim' varsa en son olani baz al.
    satirlar = db.execute(
        select(
            RecipeFeedback.recipe_id,
            func.max(RecipeFeedback.created_at).label("son"),
        )
        .where(
            RecipeFeedback.user_id == current_user.id,
            RecipeFeedback.action == FeedbackAction.YAPACAGIM,
            RecipeFeedback.created_at > utcnow() - timedelta(days=7),
        )
        .group_by(RecipeFeedback.recipe_id)
        .order_by(func.max(RecipeFeedback.created_at).desc())
    ).all()

    kimlikler = [s[0] for s in satirlar]
    return await fetch_cards(mongo_db, kimlikler)

@router.get(
    "/deck",
    response_model=DeckResponse,
    summary="Swipe destesi",
    description=(
        "Kiler agirlikli skorlamayla siralanmis kart destesi doner.\n\n"
        "**Oturum kurallari:**\n"
        "- `session_id` gonderilmezse yeni oturum acilir ve yanitta doner\n"
        "- Ayni oturumda daha once GORULEN tarifler tekrar gelmez\n"
        "- `reason='sevmedim'` denen tarifler KALICI olarak elenir\n"
        "- `reason='malzeme_yok'` denenler 7 gun elenir\n"
        "- `reason='cok_uzun'` denince o oturumda sure siniri 30 dk'ya duser\n\n"
        "Donen kartlar otomatik olarak 'gorildu' isaretlenir."
    ),
    responses={
        status.HTTP_403_FORBIDDEN: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def get_deck(
    db: DbSession,
    mongo_db: MongoDb,
    current_user: ActiveUser,
    session_id: int | None = Query(
        default=None, description="Yoksa yeni oturum acilir."
    ),
    limit: int = Query(default=10, ge=1, le=30),
) -> DeckResponse:
    deste = await swipe_service.build_deck(
        db, mongo_db, current_user, session_id=session_id, limit=limit
    )
    return DeckResponse(**deste)


@router.post(
    "/{recipe_id}/swipe",
    response_model=SwipeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Kart geri bildirimi",
    description=(
        "Kalici eleme icin `action='begenmedim'` + `reason='sevmedim'` gonder. "
        "Sure esigini daraltmak icin `reason='cok_uzun'` ve `session_id` sart."
    ),
    responses={
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse},
    },
)
async def swipe(
    recipe_id: str,
    data: SwipeRequest,
    db: DbSession,
    mongo_db: MongoDb,
    current_user: ActiveUser,
) -> SwipeResponse:
    kayit, oturum, etki = await swipe_service.record_swipe(
        db, mongo_db, current_user, recipe_id,
        action=data.action,
        reason=data.reason,
        session_id=data.session_id,
        missing_ingredient_ids=(
            data.missing_ingredient_ids
            or ([data.missing_ingredient_id] if data.missing_ingredient_id else [])
        ),
        rating=data.rating,
        servings_cooked=data.servings_cooked,
        comment=data.comment,
    )
    return SwipeResponse(
        feedback_id=kayit.id,
        session_id=kayit.session_id,
        recipe_id=kayit.recipe_id,
        action=kayit.action,
        reason=kayit.reason,
        session_filters=oturum.filters if oturum else {},
        effect=etki,
    )

@router.get(
    "/{recipe_id}",
    response_model=RecipeRead,
    summary="Tarif detayi",
    description=(
        "Tam tarif: malzemeler (canonical_name ile), adimlar, porsiyon, "
        "makrolar. W4-T01 renkli malzeme durumu istemcide kiler ile "
        "capraz eslestirilerek hesaplanir."
    ),
    responses={status.HTTP_404_NOT_FOUND: {"model": ErrorResponse}},
)
async def get_recipe(
    recipe_id: str,
    mongo_db: MongoDb,
    current_user: ActiveUser,
) -> RecipeRead:
    try:
        oid = ObjectId(recipe_id)
    except (InvalidId, TypeError) as exc:
        raise NotFoundError("Gecersiz tarif kimligi.") from exc

    dokuman = await mongo_db[RECIPE_COLLECTION].find_one({"_id": oid})
    if dokuman is None:
        raise NotFoundError("Tarif bulunamadi.")

    return RecipeRead.model_validate(dokuman)