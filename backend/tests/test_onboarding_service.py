"""W3-T02B birim testleri: onboarding ucu is mantigi."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import Allergen, DietTag, RecipeFeedback, User, UserTasteWeight
from app.models.enums import FeedbackAction, TasteDimension
from app.schemas.user import OnboardingRequest, UserProfileCreate
from app.services import onboarding_service


class _FakeCollection:
    def __init__(self, belgeler: dict):
        self._belgeler = belgeler

    async def find_one(self, filtre, projection=None):
        return self._belgeler.get(str(filtre["_id"]))


class _FakeMongo:
    def __init__(self, belgeler: dict):
        self._koleksiyon = _FakeCollection(belgeler)

    def __getitem__(self, ad):
        return self._koleksiyon


R1 = "a" * 24
R2 = "b" * 24


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="onboarding@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def diyet_ve_alerjen(db):
    db.add(DietTag(code="vegan", display_name="Vegan"))
    db.add(Allergen(code="findik", display_name="Findik"))
    db.commit()


@pytest.fixture()
def mongo_db():
    return _FakeMongo({
        R1: {"_id": R1, "cuisine": "italyan", "difficulty": "kolay",
             "diet_tags": ["vegan"],
             "ingredients": [{"canonical_name": "domates", "optional": False}]},
    })


@pytest.mark.asyncio
async def test_profil_hesaplaniyor_ve_onboarding_tamamlaniyor(db, user, mongo_db):
    istek = OnboardingRequest(
        profile=UserProfileCreate(
            birth_year=1998, gender="erkek", height_cm=178, weight_kg=75,
            activity_level="orta", goal="koruma", household_size=1,
        ),
    )
    guncel = await onboarding_service.complete_onboarding(db, mongo_db, user, istek)
    assert guncel.onboarding_completed is True
    assert guncel.profile.daily_calorie_target != 2000


@pytest.mark.asyncio
async def test_atlanan_profil_varsayilan_2000_kcal_verir(db, user, mongo_db):
    istek = OnboardingRequest(profile=UserProfileCreate())
    guncel = await onboarding_service.complete_onboarding(db, mongo_db, user, istek)
    assert guncel.profile.daily_calorie_target == 2000
    assert guncel.profile.bmr is None


@pytest.mark.asyncio
async def test_diyet_ve_alerjen_kodlari_baglaniyor(db, user, mongo_db, diyet_ve_alerjen):
    istek = OnboardingRequest(
        profile=UserProfileCreate(),
        diet_tag_codes=["vegan"], allergen_codes=["findik"],
    )
    guncel = await onboarding_service.complete_onboarding(db, mongo_db, user, istek)
    assert [t.code for t in guncel.diet_tags] == ["vegan"]
    assert [a.code for a in guncel.allergens] == ["findik"]


@pytest.mark.asyncio
async def test_begenilen_tarif_feedback_ve_taste_weight_uretir(db, user, mongo_db):
    istek = OnboardingRequest(profile=UserProfileCreate(), liked_recipe_ids=[R1])
    await onboarding_service.complete_onboarding(db, mongo_db, user, istek)

    feedback = db.query(RecipeFeedback).filter_by(user_id=user.id).one()
    assert feedback.recipe_id == R1
    assert feedback.action == FeedbackAction.BEGENDIM

    agirliklar = {(w.dimension, w.taste_key) for w in db.query(UserTasteWeight).all()}
    assert (TasteDimension.CUISINE, "italyan") in agirliklar
    assert (TasteDimension.INGREDIENT, "domates") in agirliklar


@pytest.mark.asyncio
async def test_gecersiz_veya_bulunamayan_tarif_id_sessizce_atlanir(db, user, mongo_db):
    istek = OnboardingRequest(profile=UserProfileCreate(), liked_recipe_ids=["gecersiz", R2])
    guncel = await onboarding_service.complete_onboarding(db, mongo_db, user, istek)
    assert guncel.onboarding_completed is True
    assert db.query(RecipeFeedback).count() == 0