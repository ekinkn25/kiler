"""Kiler, kiler hareketleri ve alisveris listesi semalari."""
from datetime import date, datetime

from pydantic import Field, model_validator

from app.models.enums import PantryEventType, ShoppingSource, UnitCode, UnitType, Availability, PantrySource
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


# class PantryItemUpdate(AppBaseModel):
#     quantity: float | None = Field(default=None, ge=0)
#     unit: UnitCode | None = None
#     min_threshold: float | None = Field(default=None, ge=0)
#     expiry_date: date | None = None
#     is_active: bool | None = None


class PantryItemRead(AppBaseModel):
    """Kiler ekraninin (W3-T18) tek kaydi.

    DIKKAT 1: `availability` ORM'deki ham kolon DEGIL,
    PantryItem.effective_availability degeridir - guven suresi dolmus
    bir 'var' kaydi burada 'bilinmiyor' olarak doner. Bu yuzden bu sema
    model_validate ile DOGRUDAN uretilmemeli, alanlar acikca verilmeli.

    DIKKAT 2: expiry_date / is_active / is_low / display_quantity alanlari
    KALDIRILDI. Bunlar W2-T01 oncesi 'envanter' tasarimindan kalmaydi;
    PantryItem modelinde karsiliklari YOK ve semada birakilmalari her
    yaniti 500'e dusururdu.
    """

    id: int
    ingredient: IngredientRead
    product: ProductRead | None = None
    availability: Availability = Field(
        description="Guven suresi dikkate alinmis GERCEK durum"
    )
    source: PantrySource
    confirmed_at: UtcDatetime | None = None
    confidence_expires_at: UtcDatetime | None = None
    days_remaining: int | None = Field(
        default=None, description="Guven suresinin bitmesine kalan gun"
    )
    detected_confidence: float | None = Field(default=None, ge=0, le=1)
    quantity_base: float | None = None
    display_unit: UnitCode | None = None
    created_at: UtcDatetime
    updated_at: UtcDatetime


class PantryScanRequest(AppBaseModel):
    """W2-T11: kameradan okunan barkodun gonderildigi istek."""

    barcode: str = Field(min_length=8, max_length=20, examples=["8690504010203"])
    quantity: float | None = Field(default=None, gt=0)
    unit: UnitCode | None = None

class ProductScanResponse(AppBaseModel):
    """POST /pantry/scan yaniti. Kilere HICBIR SEY YAZILMAZ - onay bekler."""
    found: bool
    product: ProductRead | None = None
    matched_ingredient: IngredientRead | None = None
    from_cache: bool = False
    message: str | None = None


class PantryConfirmScannedRequest(AppBaseModel):
    """Barkod taramasinin onaylanmasi. Foto akisindaki
    PantryConfirmDetectedRequest'ten FARKLI: liste degil TEK urun."""
    product_id: int
    ingredient_id: int | None = Field(
        default=None, description="Urun sozlukte eslesmediyse ZORUNLU."
    )


class PantryItemConfirm(AppBaseModel):
    """[Var]/ [Bitti] hızlı aksiyonu"""
    still_have : bool = Field(description="true -> süre yenilenir, false -> bitti")

class PantryStatusUpdate(AppBaseModel):
    """W3-T21: uc durumlu hizli aksiyon (var / bilinmiyor / bitti)."""
    availability: Availability = Field(
        description="var -> sure yenilenir, bilinmiyor -> guven dusurulur, bitti -> listeden duser"
    )


class PantryManualAdd(AppBaseModel):
    """W3-T21: kullanicinin elle sectigi malzemeyi kilere ekler."""
    ingredient_id: int


class ShoppingManualAdd(AppBaseModel):
    """W3-T21: alisveris listesine elle tek oge ekleme."""
    name: str = Field(min_length=1, max_length=150)


class ShoppingTransferRequest(AppBaseModel):
    """Isaretli ogeleri kilere aktarir. item_ids bos ise TUM isaretliler."""
    item_ids: list[int] = Field(default_factory=list, max_length=100)


class ShoppingTransferResponse(AppBaseModel):
    transferred: list[str] = []
    skipped: list[str] = Field(
        default=[], description="ingredient_id'si olmayan (sozlukte eslesmeyen) ogeler"
    )


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



class DetectedIngredient(AppBaseModel):
    "görme modelinin tespit  ettiği tek bir malzeme"
    raw_name: str = Field(description="modelin dondurdugu ham ad")
    canonical_name: str | None = Field(
        default=None, description="sozlukte eslesen kanonik ad, yok ise null(gri)"
    )
    display_name: str
    confidence: float = Field(ge=0, le=1)

class PantryConfirmDetectedRequest(AppBaseModel):
    "onay ekranından secilen malzemelerin kilere yazılması W2-T10"
    canonical_name: list[str] = Field(min_length=1, max_length=40)
    source: PantrySource = PantrySource.FOTO

class ConfirmedPantryItem(AppBaseModel):
    ingredient_id: int
    canonical_name: str
    display_name: str
    availability: Availability
    confidence_expires_at: UtcDatetime | None = None
    is_new: bool

class ScannedConfirmResponse(ConfirmedPantryItem):
    product_id: int


class PantryConfirmDetectedResponse(AppBaseModel):
    confirmed: list[ConfirmedPantryItem]
    skipped_unknown: list[str] = Field(
        default=[], description="Sozlukte karsiligi olmayan, atlanan canonical_name'ler"
    )