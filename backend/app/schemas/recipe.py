"""Tarif etkilesimi ve tarif dokumani semalari.

Tarifin kendisi MongoDB'de tutulur; buradaki modeller hem API sozlesmesini
hem seed betiginin uretecegi dokuman seklini tanimlar.
"""
from datetime import datetime
from enum import Enum

from bson import ObjectId
from pydantic import Field, field_validator

from app.core.constants import CUISINES, DIFFICULTIES
from app.models.enums import FeedbackAction, UnitCode
from app.schemas.common import AppBaseModel, UtcDatetime

from pydantic import Field, field_validator, model_validator
from app.models.enums import FeedbackAction, FeedbackReason, UnitCode


# ==================================================================
# Malzeme durum gosterimi (W4-T01)
# ==================================================================
class IngredientStatus(str, Enum):
    """Tarif detayindaki uc renkli durum."""

    AVAILABLE = "available"   # YESIL   - kilerde yeterli miktar var
    MISSING = "missing"       # KIRMIZI - kilerde yok veya yetersiz
    UNKNOWN = "unknown"       # GRI     - sozlukte karsiligi yok


class RecipeIngredientStatus(AppBaseModel):
    canonical_name: str | None = None
    display_name: str
    required_quantity: float | None = None
    required_unit: str | None = None
    available_quantity: float | None = None
    status: IngredientStatus


# ==================================================================
# Tarif dokumani (MongoDB)
# ==================================================================
class RecipeIngredient(AppBaseModel):
    name: str = Field(min_length=1, max_length=120, examples=["Kırmızı Mercimek"])
    canonical_name: str | None = Field(
        default=None,
        pattern=r"^[a-z0-9_]+$",
        examples=["kirmizi_mercimek"],
        description="SQLite ingredients tablosuyla birleştirme anahtarı. null ise GRİ gösterilir.",
    )
    quantity: float | None = Field(default=None, ge=0, examples=[200])
    unit: UnitCode | None = Field(default=None, examples=["g"])
    optional: bool = False
    note: str | None = Field(default=None, max_length=120, examples=["ince kıyılmış"])


class RecipeMacros(AppBaseModel):
    protein_g: float = Field(default=0, ge=0)
    carb_g: float = Field(default=0, ge=0)
    fat_g: float = Field(default=0, ge=0)
    fiber_g: float = Field(default=0, ge=0)


class RecipeBase(AppBaseModel):
    title: str = Field(min_length=2, max_length=200)
    slug: str = Field(pattern=r"^[a-z0-9-]+$", max_length=220)
    description: str | None = Field(default=None, max_length=1000)
    image_url: str | None = Field(default=None, max_length=500)

    ingredients: list[RecipeIngredient] = Field(min_length=1)
    steps: list[str] = Field(min_length=1)

    servings: int = Field(ge=1, le=20)
    prep_time: int = Field(default=0, ge=0, le=600, description="Dakika")
    cook_time: int = Field(default=0, ge=0, le=600, description="Dakika")
    difficulty: str = Field(default="orta")

    calories_per_serving: float = Field(ge=0, le=5000)
    macros: RecipeMacros = RecipeMacros()

    diet_tags: list[str] = []
    allergens: list[str] = []
    cuisine: str = "turk"

    source: str | None = Field(default=None, max_length=100)
    source_url: str | None = Field(default=None, max_length=500)
    is_active: bool = True

    @field_validator("difficulty")
    @classmethod
    def valid_difficulty(cls, v: str) -> str:
        if v not in DIFFICULTIES:
            raise ValueError(f"difficulty su degerlerden biri olmali: {DIFFICULTIES}")
        return v

    @field_validator("cuisine")
    @classmethod
    def valid_cuisine(cls, v: str) -> str:
        if v not in CUISINES:
            raise ValueError(f"cuisine su degerlerden biri olmali: {CUISINES}")
        return v

    @property
    def total_time(self) -> int:
        return self.prep_time + self.cook_time


class RecipeCreate(RecipeBase):
    """W1-T11 seed betiginin uretecegi dokuman sekli."""


class RecipeRead(RecipeBase):
    """Tarif detay ekrani (W3-T08)."""

    id: str = Field(alias="_id")

    @field_validator("id", mode="before")
    @classmethod
    def objectid_to_str(cls, v) -> str:
        return str(v) if isinstance(v, ObjectId) else str(v)


class RecipeCard(AppBaseModel):
    """Tarif listesi karti (W3-T07). Payload'i kucuk tutmak icin sade."""

    id: str = Field(alias="_id")
    title: str
    slug: str
    image_url: str | None = None
    calories_per_serving: float
    servings: int
    prep_time: int
    cook_time: int
    difficulty: str
    diet_tags: list[str] = []
    match_ratio: float | None = Field(
        default=None, ge=0, le=1,
        description="Kiler eşleşme oranı (W3-T03 aggregation'ından gelir)",
    )

    @field_validator("id", mode="before")
    @classmethod
    def objectid_to_str(cls, v) -> str:
        return str(v)


# ==================================================================
# Tarif geri bildirimi (SQLite)
# ==================================================================
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
    created_at: UtcDatetime


class RecipeCookRequest(AppBaseModel):
    """W4-T03: 'Bu Tarifi Yaptim' istegi."""

    servings: float = Field(default=1, gt=0, le=20)
    log_meal: bool = Field(default=True, description="Kalori gunlugune de yazilsin mi?")
    meal_type: str | None = None

# ==================================================================
# Skorlanmis tarif karti (W2-T06)
# ==================================================================
class ScoreWeights(AppBaseModel):
    pantry: float
    calorie: float
    taste: float
    time: float


class ScoreBreakdown(AppBaseModel):
    """Skorun bilesenleri. ACIKLANABILIRLIK icin yanitta doner:
    'bu tarif ust sirada cunku kilerinin %80'i uyuyor' denebilsin."""
    pantry: float = Field(ge=0, le=1)
    calorie: float = Field(ge=0, le=1)
    taste: float = Field(ge=0, le=1)
    time: float = Field(ge=0, le=1)
    weights: ScoreWeights


class ScoredRecipeCard(AppBaseModel):
    id: str
    title: str
    slug: str
    image_url: str | None = None
    calories_per_serving: float
    servings: int
    prep_time: int | None = None
    cook_time: int | None = None
    difficulty: str | None = None
    cuisine: str | None = None
    diet_tags: list[str] = []
    allergens: list[str] = []

    final_score: float = Field(ge=0, le=1)
    score_breakdown: ScoreBreakdown

    matched_ingredients: list[str] = []
    unknown_ingredients: list[str] = []
    missing_ingredients: list[str] = []
    total_required: int = 0

# ==================================================================
# Swipe destesi 
# ==================================================================
class DeckResponse(AppBaseModel):
    session_id: int
    items: list[ScoredRecipeCard]
    returned: int
    requested: int
    exhausted: bool = Field(
        description="Istenen sayida kart uretilemedi; istemci 'filtreleri gevset' der."
    )
    session_filters: dict = Field(
        default_factory=dict,
        description="Oturum boyunca daralan filtreler, orn. {'max_total_time': 30}",
    )
    excluded_count: int = 0


class SwipeRequest(AppBaseModel):
    """Tek bir kart üzerindeki geri bildirim.

    DİKKAT: 'sevmedim' bir action DEGIL, reason'dir. Kalıcı eleme için
    action='begenmedim' + reason='sevmedim' gönderilmeli. Yalnızca
    'begenmedim' gönderilirse tarif kalıcı olarak elenmez.
    """
    action: FeedbackAction
    reason: FeedbackReason | None = None
    session_id: int | None = None
    missing_ingredient_id: int | None = None
    missing_ingredient_ids: list[int] = Field(
        default_factory=list,
        max_length=20,
        description=(
            "W3-T09 coklu secim. Tekil `missing_ingredient_id` geriye uyum "
            "icin duruyor; ikisi de gonderilirse liste esas alinir."
        ),
    )
    rating: int | None = Field(default=None, ge=1, le=5)
    servings_cooked: float | None = Field(default=None, gt=0, le=20)
    comment: str | None = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def kisitlar(self):
        """Veritabanindaki CHECK kisitlarinin API karsiligi.

        Bu dogrulama olmasaydi ayni hatalar IntegrityError olarak 500
        donerdi; buradan 422 ve anlasilir mesaj cikiyor.
        """
        if self.reason is not None and self.action != FeedbackAction.BEGENMEDIM:
            raise ValueError("reason yalnizca action='begenmedim' ile gonderilebilir.")
        
        eksik_verildi = (self.missing_ingredient_id is not None or bool(self.missing_ingredient_ids))
        if eksik_verildi and self.reason != FeedbackReason.MALZEME_YOK:
            raise ValueError(
                "missing_ingredient_id yalnizca reason='malzeme_yok' ile gonderilebilir."
            )
        return self


class SwipeResponse(AppBaseModel):
    feedback_id: int
    session_id: int | None = None
    recipe_id: str
    action: FeedbackAction
    reason: FeedbackReason | None = None
    session_filters: dict = Field(default_factory=dict)
    effect: str = Field(description="Geri bildirimin sonucunun insan okunur ozeti.")