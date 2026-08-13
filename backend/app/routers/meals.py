"""Ogun kaydi uclari. W2-T11."""
import logging
from datetime import date

from fastapi import APIRouter, Query, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.schemas import DailySummary, ErrorResponse, MealLogCreate, MealLogRead
from app.services import meal_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "",
    response_model=MealLogRead,
    status_code=status.HTTP_201_CREATED,
    summary="Ogun kaydet",
    description=(
        "ANLIK GORUNTU ILKESI: item_name, calories ve makrolar kayit "
        "aninda kopyalanir. Urun/tarif sonradan degisse bile bu kayit "
        "ETKILENMEZ.\n\n"
        "product_id / ingredient_id / recipe_id / custom_name alanlarindan "
        "EN AZ BIRI zorunludur. custom_name TEK BASINA kullanilirsa "
        "calories alani da zorunludur."
    ),
    responses={
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse},
    },
)
async def create_meal(
    data: MealLogCreate, db: DbSession, mongo_db: MongoDb, current_user: ActiveUser,
) -> MealLogRead:
    kayit = await meal_service.create_meal_log(db, mongo_db, current_user, data)
    return MealLogRead.model_validate(kayit)


@router.get(
    "/daily",
    response_model=DailySummary,
    summary="Gunluk kalori ozeti",
    description=(
        "date gonderilmezse SUNUCUNUN bugunu kullanilir - dogru sonuc "
        "icin istemci HER ZAMAN kendi yerel gununu gondermeli."
    ),
)
def daily_summary(
    db: DbSession, current_user: ActiveUser,
    date_: date | None = Query(default=None, alias="date"),
) -> DailySummary:
    hedef = date_ or date.today()
    ozet = meal_service.get_daily_summary(db, current_user, hedef)
    return DailySummary(**ozet)


@router.delete(
    "/{meal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Ogun kaydini sil",
    responses={
        status.HTTP_403_FORBIDDEN: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
    },
)
def delete_meal(meal_id: int, db: DbSession, current_user: ActiveUser) -> None:
    meal_service.delete_meal_log(db, current_user, meal_id)