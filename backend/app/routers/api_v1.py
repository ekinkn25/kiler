from fastapi import APIRouter, status
from app.schemas import ErrorResponse, PantryItemCreate
from app.routers import (
    auth, chat, recipes, vision, pantry, meals, onboarding, catalog, shopping, me
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(vision.router, prefix="/vision", tags=["vision"])
api_router.include_router(recipes.router, prefix="/recipes", tags=["recipes"])
api_router.include_router(chat.router, prefix="/chat", tags=["chatbot"]) 
api_router.include_router(pantry.router, prefix="/pantry", tags=["pantry"])
api_router.include_router(meals.router, prefix="/meals", tags=["calories"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
api_router.include_router(catalog.router, prefix="/catalog", tags=["catalog"])
api_router.include_router(shopping.router, prefix="/shopping", tags=["shopping"])
api_router.include_router(me.router, prefix="/me", tags=["kvkk"])

@api_router.get("/ping", tags=["system"], summary="Versiyonlu API canlilik testi")
def ping() -> dict[str, bool]:
    return {"pong": True}

@api_router.post(
    "/_schema-check/pantry",
    tags=["system"],
    summary="[GECICI] Sema dogrulama testi",
    response_model=PantryItemCreate,
    responses={status.HTTP_422_UNPROCESSABLE_CONTENT: {"model": ErrorResponse}},
)
def schema_check(payload: PantryItemCreate) -> PantryItemCreate:
    """Gonderilen govdeyi dogrular ve aynen geri doner."""
    return payload