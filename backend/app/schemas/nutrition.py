"""Ogun kaydi ve gunluk kalori ozeti semalari."""
from datetime import date, datetime

from pydantic import Field, model_validator

from app.models.enums import LogSource, MealType
from app.schemas.common import AppBaseModel


class MealLogCreate(AppBaseModel):
    logged_date: date = Field(default_factory=date.today)
    meal_type: MealType
    source: LogSource = LogSource.MANUEL

    product_id: int | None = None
    ingredient_id: int | None = None
    recipe_id: str | None = Field(default=None, min_length=24, max_length=24)
    custom_name: str | None = Field(default=None, max_length=200)

    servings: float = Field(default=1, gt=0, le=20)
    quantity_g: float | None = Field(default=None, gt=0, le=5000)

    @model_validator(mode="after")
    def at_least_one_source(self) -> "MealLogCreate":
        if not any([self.product_id, self.ingredient_id, self.recipe_id, self.custom_name]):
            raise ValueError(
                "product_id, ingredient_id, recipe_id veya custom_name "
                "alanlarindan en az biri zorunludur."
            )
        return self


class MealLogRead(AppBaseModel):
    id: int
    logged_date: date
    meal_type: MealType
    source: LogSource
    item_name: str
    servings: float
    quantity_g: float | None = None
    calories: float
    protein_g: float | None = None
    carb_g: float | None = None
    fat_g: float | None = None
    recipe_id: str | None = None
    created_at: datetime


class MacroBreakdown(AppBaseModel):
    protein_g: float = 0
    carb_g: float = 0
    fat_g: float = 0
    fiber_g: float = 0


class DailySummary(AppBaseModel):
    """W2-T13 kalori ekraninin tek istekle aldigi ozet."""

    logged_date: date
    calorie_target: float
    calories_consumed: float
    calories_remaining: float
    macros_consumed: MacroBreakdown
    macros_target: MacroBreakdown
    meals: dict[MealType, list[MealLogRead]] = Field(
        description="Ogun tipine gore gruplanmis kayitlar"
    )


class WeightLogCreate(AppBaseModel):
    logged_date: date = Field(default_factory=date.today)
    weight_kg: float = Field(gt=20, lt=400)


class WeightLogRead(AppBaseModel):
    id: int
    logged_date: date
    weight_kg: float