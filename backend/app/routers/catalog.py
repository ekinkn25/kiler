"""Sozluk (lookup) uclari: onboarding'in diyet/alerjen cip listesi bunlardan beslenir."""
from fastapi import APIRouter, Query

from app.core.deps import DbSession, ActiveUser
from app.models import Allergen, DietTag, Ingredient
from app.schemas import AllergenRead, DietTagRead, IngredientRead

router = APIRouter()


@router.get("/diet-tags", response_model=list[DietTagRead], summary="Tum diyet etiketleri")
def list_diet_tags(db: DbSession) -> list[DietTagRead]:
    kayitlar = db.query(DietTag).order_by(DietTag.display_name).all()
    return [DietTagRead.model_validate(k) for k in kayitlar]


@router.get("/allergens", response_model=list[AllergenRead], summary="Tum alerjenler")
def list_allergens(db: DbSession) -> list[AllergenRead]:
    kayitlar = db.query(Allergen).order_by(Allergen.display_name).all()
    return [AllergenRead.model_validate(k) for k in kayitlar]


@router.get(
    "/ingredients",
    response_model=list[IngredientRead],
    summary="Malzeme sozlugu (canonical_name ile filtrelenebilir)",
    description=(
        "W3-T07 KOPRUSU: swipe kartinin `missing_ingredients` alani "
        "canonical_name (metin) doner, ama `POST /recipes/{id}/swipe` "
        "govdesi `missing_ingredient_id` (int) ister. Bu uc ikisini baglar.\n\n"
        "`names` virgulle ayrilmis canonical_name listesidir; gonderilmezse "
        "sozlugun ilk `limit` kaydi doner."
    ),
)
def list_ingredients(
    db: DbSession,
    names: str | None = Query(
        default=None,
        description="Virgulle ayrilmis canonical_name listesi. Orn: kirmizi_mercimek,sogan",
    ),
    limit: int = Query(default=50, ge=1, le=200),
) -> list[IngredientRead]:
    sorgu = db.query(Ingredient)

    if names is not None:
        istenen = [p.strip() for p in names.split(",") if p.strip()]
        # 'names=' bos gelirse TUM sozlugu donmek yanlis olur: istemci
        # bir filtre GONDERDI, sadece icini dolduramadi.
        if not istenen:
            return []
        sorgu = sorgu.filter(Ingredient.canonical_name.in_(istenen))

    kayitlar = sorgu.order_by(Ingredient.display_name).limit(limit).all()
    return [IngredientRead.model_validate(k) for k in kayitlar]

@router.get(
    "/ingredients/search",
    response_model=list[IngredientRead],
    summary="Malzeme arama (elle ekleme icin)",
    description=(
        "Yazilan metne gore malzeme onerir (W3-T21). Kiler ve alisveris "
        "listesine elle ekleme akislari bunu besler."
    ),
)
def search_ingredients(
    db: DbSession,
    current_user: ActiveUser,
    q: str = Query(min_length=1, max_length=60, description="Arama metni"),
    limit: int = Query(default=10, ge=1, le=30),
) -> list[IngredientRead]:
    kalip = f"%{q.strip()}%"
    kayitlar = (
        db.query(Ingredient)
        .filter(Ingredient.display_name.ilike(kalip))
        .order_by(Ingredient.display_name)
        .limit(limit)
        .all()
    )
    return [IngredientRead.model_validate(k) for k in kayitlar]