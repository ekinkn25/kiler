"""Tarif uclari. W2-T07: swipe destesi ve geri bildirim."""
import logging

from fastapi import APIRouter, Query, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.schemas import DeckResponse, ErrorResponse, SwipeRequest, SwipeResponse
from app.services import swipe_service

logger = logging.getLogger(__name__)

router = APIRouter()


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