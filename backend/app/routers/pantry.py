"""Kiler uclari. Su an SADECE W2-T10 kapsami: gorme tespitlerinin onayi.

DIKKAT: Kiler listeleme/elle ekleme/silme (W2-T01/T02) BURADA DEGIL -
bu dosya yalnizca /confirm-detected'i icerir.
"""
import logging

from fastapi import APIRouter, status

from app.core.deps import ActiveUser, DbSession
from app.schemas import (
    ErrorResponse, PantryConfirmDetectedRequest, PantryConfirmDetectedResponse,
)
from app.services.pantry_service import confirm_detected_ingredients

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/confirm-detected",
    response_model=PantryConfirmDetectedResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Gorme modeli tespitlerini onayla",
    description=(
        "W2-T04/T08/T10'da fotograftan tespit edilen malzemelerden "
        "kullanicinin SECTIKLERINI kilere yazar. availability='var', "
        "confidence_expires_at=simdi+7 gun (PANTRY_CONFIDENCE_DAYS)."
    ),
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
def confirm_detected(
    data: PantryConfirmDetectedRequest, db: DbSession, current_user: ActiveUser,
) -> PantryConfirmDetectedResponse:
    sonuc = confirm_detected_ingredients(
        db, current_user, data.canonical_name, data.source,
    )
    return PantryConfirmDetectedResponse(
        confirmed=sonuc.confirmed, skipped_unknown=sonuc.skipped_unknown,
    )