"""Kullanici, profil ve onboarding semalari."""
"""contract katmanındayız: model kısmında veritabanı tabloları tasarlamıştı burada ise veri tabanında o ham verileri api üzerinden frontendde hangi formatta, hangi kısıtlamalarla, ve hangi güvenlik duvarlarından geçerek aktraılacağını tanımlıyoruz.
DRY: dont repeat yourself
Field: Bir alana varsayılan değer, sınır (min/max), açıklama ve OpenAPI örneği iliştirmek için.
computed_field: pydantic v2 özelliği dbde olmayan ama json çıktısında görünen türetilmiş alanlar üretir
"""
from datetime import datetime

from pydantic import EmailStr, Field, computed_field

from app.models.enums import ActivityLevel, Gender, Goal
from app.schemas.common import AppBaseModel


# ------------------------------------------------------------------ lookup schemas
class DietTagRead(AppBaseModel):
    id: int
    code: str
    display_name: str


class AllergenRead(AppBaseModel):
    id: int
    code: str
    display_name: str


# ------------------------------------------------------------------ profil
class UserProfileBase(AppBaseModel):
    birth_year: int | None = Field(default=None, ge=1900, le=2026)
    gender: Gender | None = None
    height_cm: float | None = Field(default=None, gt=50, lt=260)
    weight_kg: float | None = Field(default=None, gt=20, lt=400)
    activity_level: ActivityLevel = ActivityLevel.ORTA
    goal: Goal = Goal.KORUMA
    household_size: int = Field(default=1, ge=1, le=20) #hane halkı sayısı


class UserProfileCreate(UserProfileBase):
    pass


class UserProfileUpdate(AppBaseModel):
    """PATCH semantigi: tum alanlar opsiyonel, sadece gonderilenler guncellenir."""

    birth_year: int | None = Field(default=None, ge=1900, le=2026)
    gender: Gender | None = None
    height_cm: float | None = Field(default=None, gt=50, lt=260)
    weight_kg: float | None = Field(default=None, gt=20, lt=400)
    activity_level: ActivityLevel | None = None
    goal: Goal | None = None
    household_size: int | None = Field(default=None, ge=1, le=20)


class UserProfileRead(UserProfileBase):
    """dbden çekilen verinin frontende nasıl döneceğini belirler"""
    id: int
    bmr: float | None = None #bazal metabolizma rate(hız)
    tdee: float | None = None #Total Daily Energy Expenditure): BMR × aktivite çarpanı. ActivityLevel enum'ının varlık sebebi bu.
    daily_calorie_target: float
    protein_target_g: float | None = None
    carb_target_g: float | None = None
    fat_target_g: float | None = None

    @computed_field
    @property
    def age(self) -> int | None:
        """Yas, dogum yilindan anlik hesaplanir; veritabaninda saklanmaz."""
        if self.birth_year is None:
            return None
        return datetime.now().year - self.birth_year


# ------------------------------------------------------------------ kullanici
class UserRead(AppBaseModel):
    """DIKKAT: hashed_password ASLA burada yer almaz."""
    """Kullanıcı tablosunda (models.User) şifre hash'leri bulunur. Ancak API'den dışarıya veri dönerken UserRead şemasını kullandığın için, şifre verisi bu sözleşmede (schema) yer almaz ve kazara dışarı sızması imkansız hale gelir."""

    id: int
    email: EmailStr
    full_name: str | None = None
    is_active: bool
    onboarding_completed: bool
    created_at: datetime

    profile: UserProfileRead | None = None
    diet_tags: list[DietTagRead] = []
    allergens: list[AllergenRead] = []


class UserUpdate(AppBaseModel):
    full_name: str | None = Field(default=None, max_length=120)


# ------------------------------------------------------------------ onboarding
class OnboardingRequest(AppBaseModel):
    """W1-T19'daki 4 adimli anketin tek seferde gonderilen ciktisi."""
    """
        aggregator: birleştirici model: mobil geliştirici her ekran için backende ayrı ayrı istek atmak istemez kullanıcı tüm anketleri doldurunca en son devasa json paketini tek seferde backende gönderir
    """

    profile: UserProfileCreate
    diet_tag_codes: list[str] = Field(
        default=[], examples=[["vegan", "glutensiz"]],
        description="diet_tags.code degerleri",
    )
    allergen_codes: list[str] = Field(
        default=[], examples=[["findik", "laktoz"]],
        description="allergens.code degerleri",
    )
    liked_recipe_ids: list[str] = Field(
        default=[], max_length=20,
        description="Begenilen 5 yemegin MongoDB _id degerleri",
    )