"""Malzeme sozlugu, kategori ve urun semalari."""
from pydantic import Field, field_validator

from app.models.enums import ProductSource, UnitCode, UnitType
from app.schemas.common import AppBaseModel


class CategoryRead(AppBaseModel):
    id: int
    code: str
    display_name: str
    icon: str | None = None


class IngredientRead(AppBaseModel):
    id: int
    canonical_name: str
    display_name: str
    category: CategoryRead | None = None
    default_unit_type: UnitType
    default_unit: UnitCode
    grams_per_piece: float | None = None
    calories_per_100g: float | None = None
    protein_per_100g: float | None = None
    carb_per_100g: float | None = None
    fat_per_100g: float | None = None
    is_staple: bool


class IngredientCreate(AppBaseModel):
    canonical_name: str = Field(
        min_length=2, max_length=100,
        pattern=r"^[a-z0-9_]+$",
        examples=["kirmizi_mercimek"],
        description="Yalnizca kucuk harf, rakam ve alt cizgi. Turkce karakter YASAK.",
    )
    display_name: str = Field(min_length=2, max_length=120)
    category_id: int | None = None
    default_unit_type: UnitType = UnitType.MASS
    default_unit: UnitCode = UnitCode.G
    grams_per_piece: float | None = Field(default=None, gt=0)
    calories_per_100g: float | None = Field(default=None, ge=0, le=900)
    is_staple: bool = False


class ProductRead(AppBaseModel):
    id: int
    barcode: str | None = None
    name: str
    brand: str | None = None
    ingredient_id: int | None = None
    package_quantity: float | None = None
    package_unit: UnitCode | None = None
    serving_size_g: float | None = None
    serving_description: str | None = None
    calories_per_100g: float | None = None
    protein_per_100g: float | None = None
    carb_per_100g: float | None = None
    fat_per_100g: float | None = None
    image_url: str | None = None
    source: ProductSource


class ProductCreate(AppBaseModel):
    """Barkod bulunamadiginda kullanicinin elle girdigi urun (W2-T05)."""

    barcode: str | None = Field(default=None, min_length=8, max_length=20)
    name: str = Field(min_length=2, max_length=200)
    brand: str | None = Field(default=None, max_length=120)
    package_quantity: float | None = Field(default=None, gt=0)
    package_unit: UnitCode | None = None
    calories_per_100g: float | None = Field(default=None, ge=0, le=900)

    @field_validator("barcode")
    @classmethod
    def only_digits(cls, v: str | None) -> str | None:
        if v is not None and not v.isdigit():
            raise ValueError("Barkod yalnizca rakamlardan olusmalidir.")
        return v