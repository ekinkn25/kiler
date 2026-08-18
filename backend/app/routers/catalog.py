"""Sozluk (lookup) uclari: onboarding'in diyet/alerjen cip listesi bunlardan beslenir."""
from fastapi import APIRouter

from app.core.deps import DbSession
from app.models import Allergen, DietTag
from app.schemas import AllergenRead, DietTagRead

router = APIRouter()


@router.get("/diet-tags", response_model=list[DietTagRead], summary="Tum diyet etiketleri")
def list_diet_tags(db: DbSession) -> list[DietTagRead]:
    kayitlar = db.query(DietTag).order_by(DietTag.display_name).all()
    return [DietTagRead.model_validate(k) for k in kayitlar]


@router.get("/allergens", response_model=list[AllergenRead], summary="Tum alerjenler")
def list_allergens(db: DbSession) -> list[AllergenRead]:
    kayitlar = db.query(Allergen).order_by(Allergen.display_name).all()
    return [AllergenRead.model_validate(k) for k in kayitlar]