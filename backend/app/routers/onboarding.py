"""Onboarding ucu."""
from fastapi import APIRouter, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.schemas import ErrorResponse, OnboardingRequest, UserRead
from app.services import onboarding_service

router = APIRouter()


@router.post(
    "",
    response_model=UserRead,
    summary="4 adimli tanima anketini tek seferde isler",
    description=(
        "profile -> user_profiles (BMR/TDEE hesaplanir).\n"
        "diet_tag_codes / allergen_codes -> user_diet_tags / user_allergens.\n"
        "liked_recipe_ids -> recipe_feedback('begendim') + UserTasteWeight guncellemesi.\n"
        "Her adim 'Atla' ile bos gonderilebilir; varsayilanlar devreye girer."
    ),
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
async def complete_onboarding(
    data: OnboardingRequest, db: DbSession, mongo_db: MongoDb, current_user: ActiveUser,
) -> UserRead:
    user = await onboarding_service.complete_onboarding(db, mongo_db, current_user, data)
    return UserRead.model_validate(user)