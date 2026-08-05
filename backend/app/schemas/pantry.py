"""Kiler, kiler hareketleri ve alisveris listesi semalari."""
from datetime import date, datetime

from pydantic import Field, model_validator

from app.models.enums import PantryEventType, ShoppingSource, UnitCode, UnitType
from app.schemas.catalog import IngredientRead, ProductRead
from app.schemas.common import AppBaseModel, UtcDatetime


# ------------------------------------------------------------------ kiler
class PantryItemCreate(AppBaseModel):
    """Kullanici 'mercimek, 5, kg' gonderir.

    Servis katmani bunu quantity_base=5000 + unit_type=mass'e cevirir.
    DTO'nun sekli tabloyla AYNI DEGILDIR ve olmasi da gerekmez.
    """

    ingredient_id: int | None = Field(
        default=None, description="Sozlukten secildiyse malzeme kimligi"
    )
    custom_name: str | None = Field(
        default=None, max_length=150,
        description="Sozlukte yoksa kullanicinin yazdigi ad",
    )
    product_id: int | None = None

    quantity: float = Field(gt=0, examples=[5], description="Kullanicinin girdigi miktar")
    unit: UnitCode = Field(examples=["kg"], description="Kullanicinin sectigi birim")
    min_threshold: float = Field(default=0, ge=0, description="Kritik esik (ayni birimde)")
    expiry_date: date | None = None

    @model_validator(mode="after")
    def ingredient_or_name(self) -> "PantryItemCreate":
        if self.ingredient_id is None and not self.custom_name:
            raise ValueError("ingredient_id veya custom_name alanlarindan biri zorunludur.")
        return self


class PantryItemUpdate(AppBaseModel):
    quantity: float | None = Field(default=None, ge=0)
    unit: UnitCode | None = None
    min_threshold: float | None = Field(default=None, ge=0)
    expiry_date: date | None = None
    is_active: bool | None = None


class PantryItemRead(AppBaseModel):
    id: int
    ingredient: IngredientRead | None = None
    product: ProductRead | None = None
    custom_name: str | None = None

    quantity_base: float = Field(description="Temel birimde saklanan miktar (g / ml / adet)")
    unit_type: UnitType
    display_unit: UnitCode
    min_threshold_base: float

    expiry_date: date | None = None
    is_active: bool
    created_at: UtcDatetime
    updated_at: UtcDatetime

    is_low: bool = Field(description="quantity_base <= min_threshold_base")
    display_quantity: float = Field(description="display_unit cinsinden gosterim miktari")


class PantryScanRequest(AppBaseModel):
    """W2-T11: kameradan okunan barkodun gonderildigi istek."""

    barcode: str = Field(min_length=8, max_length=20, examples=["8690504010203"])
    quantity: float | None = Field(default=None, gt=0)
    unit: UnitCode | None = None


# ------------------------------------------------------------------ hareket gunlugu
class PantryEventRead(AppBaseModel):
    id: int
    ingredient_id: int
    event_type: PantryEventType
    quantity_base_delta: float
    unit_type: UnitType
    recipe_id: str | None = None
    estimated_cost: float | None = None
    event_note: str | None = None
    created_at: UtcDatetime


# ------------------------------------------------------------------ alisveris listesi
class ShoppingItemCreate(AppBaseModel):
    ingredient_id: int | None = None
    custom_name: str | None = Field(default=None, max_length=150)
    quantity: float | None = Field(default=None, gt=0)
    unit: UnitCode | None = None
    item_note: str | None = Field(default=None, max_length=255)

    @model_validator(mode="after")
    def ingredient_or_name(self) -> "ShoppingItemCreate":
        if self.ingredient_id is None and not self.custom_name:
            raise ValueError("ingredient_id veya custom_name alanlarindan biri zorunludur.")
        return self


class ShoppingItemUpdate(AppBaseModel):
    quantity: float | None = Field(default=None, gt=0)
    unit: UnitCode | None = None
    is_checked: bool | None = None
    item_note: str | None = Field(default=None, max_length=255)


class ShoppingItemRead(AppBaseModel):
    id: int
    ingredient: IngredientRead | None = None
    custom_name: str | None = None
    quantity: float | None = None
    unit: UnitCode | None = None
    source: ShoppingSource
    source_recipe_id: str | None = None
    is_checked: bool
    item_note: str | None = None
    created_at: datetime


class ShoppingBulkAdd(AppBaseModel):
    """W4-T05: tarif detayindaki eksik malzemelerin toplu eklenmesi."""

    recipe_id: str = Field(min_length=24, max_length=24)
    items: list[ShoppingItemCreate] = Field(min_length=1, max_length=50)