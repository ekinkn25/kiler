"""Tarif etkilesimi semalari. Tarifin kendisi MongoDB'de tutulur."""
from datetime import datetime
from enum import Enum

from pydantic import Field

from app.models.enums import FeedbackAction
from app.schemas.common import AppBaseModel


class IngredientStatus(str, Enum):
    """W4-T01: tarif detayindaki uc renkli durum."""

    AVAILABLE = "available"   # YESIL  - kilerde yeterli miktar var
    MISSING = "missing"       # KIRMIZI - kilerde yok veya yetersiz
    UNKNOWN = "unknown"       # GRI    - sozlukte karsiligi yok


class RecipeIngredientStatus(AppBaseModel):
    canonical_name: str | None = None
    display_name: str
    required_quantity: float | None = None
    required_unit: str | None = None
    available_quantity: float | None = None
    status: IngredientStatus


class RecipeFeedbackCreate(AppBaseModel):
    recipe_id: str = Field(min_length=24, max_length=24)
    action: FeedbackAction
    rating: int | None = Field(default=None, ge=1, le=5)
    servings_cooked: float | None = Field(default=None, gt=0, le=20)
    comment: str | None = Field(default=None, max_length=500)


class RecipeFeedbackRead(AppBaseModel):
    id: int
    recipe_id: str
    action: FeedbackAction
    rating: int | None = None
    created_at: datetime


class RecipeCookRequest(AppBaseModel):
    """W4-T03: 'Bu Tarifi Yaptim' istegi."""

    servings: float = Field(default=1, gt=0, le=20)
    log_meal: bool = Field(default=True, description="Kalori gunlugune de yazilsin mi?")
    meal_type: str | None = None