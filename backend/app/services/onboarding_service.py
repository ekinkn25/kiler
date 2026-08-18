"""Onboarding anketinin is mantigi."""
from __future__ import annotations

import logging

from bson import ObjectId
from bson.errors import InvalidId
from motor.motor_asyncio import AsyncIOMotorDatabase
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.mongo_schema import RECIPE_COLLECTION
from app.models import Allergen, DietTag, RecipeFeedback, User
from app.models.enums import FeedbackAction
from app.schemas.user import OnboardingRequest
from app.services import profile_service, taste_service

logger = logging.getLogger(__name__)

_RECIPE_PROJECTION = {"cuisine": 1, "difficulty": 1, "diet_tags": 1, "ingredients": 1}


async def complete_onboarding(
    db: Session, mongo_db: AsyncIOMotorDatabase, user: User, data: OnboardingRequest,
) -> User:
    profile_service.upsert_profile(db, user, data.profile)

    if data.diet_tag_codes:
        user.diet_tags = list(db.scalars(
            select(DietTag).where(DietTag.code.in_(data.diet_tag_codes))
        ))
    if data.allergen_codes:
        user.allergens = list(db.scalars(
            select(Allergen).where(Allergen.code.in_(data.allergen_codes))
        ))

    for recipe_id in data.liked_recipe_ids:
        try:
            nesne_kimlik = ObjectId(recipe_id)
        except (InvalidId, TypeError):
            logger.warning("Onboarding: gecersiz tarif kimligi atlandi: %r", recipe_id)
            continue

        tarif = await mongo_db[RECIPE_COLLECTION].find_one(
            {"_id": nesne_kimlik}, projection=_RECIPE_PROJECTION,
        )
        if tarif is None:
            continue

        db.add(RecipeFeedback(
            user_id=user.id, recipe_id=recipe_id, action=FeedbackAction.BEGENDIM,
        ))
        taste_service.register_recipe_signal(db, user.id, tarif, signal=1.0)

    user.onboarding_completed = True
    db.commit()
    db.refresh(user)

    logger.info(
        "Onboarding tamamlandi | kullanici=%s diyet=%d alerjen=%d begenilen=%d",
        user.id, len(data.diet_tag_codes), len(data.allergen_codes), len(data.liked_recipe_ids),
    )
    return user