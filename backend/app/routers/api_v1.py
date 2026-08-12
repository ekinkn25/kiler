from fastapi import APIRouter, status
from app.schemas import ErrorResponse, PantryItemCreate
from app.routers import auth, vision

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(vision.router, prefix="/vision", tags=["vision"])


@api_router.get("/ping", tags=["system"], summary="Versiyonlu API canlilik testi")
def ping() -> dict[str, bool]:
    return {"pong": True}

# TODO(W2-T01): Bu gecici uc, gercek kiler endpoint'leri yazilinca SILINECEK.
@api_router.post(
    "/_schema-check/pantry",
    tags=["system"],
    summary="[GECICI] Sema dogrulama testi",
    response_model=PantryItemCreate,
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
def schema_check(payload: PantryItemCreate) -> PantryItemCreate:
    """Gonderilen govdeyi dogrular ve aynen geri doner."""
    return payload


# ------------------------------------------------------------------
# Ilerleyen gorevlerde buraya eklenecek:
#
# from app.routers import auth, pantry, products, recipes, calories, shopping, chat
#
# api_router.include_router(auth.router,     prefix="/auth",     tags=["auth"])      # W1-T08
# api_router.include_router(pantry.router,   prefix="/pantry",   tags=["pantry"])    # W2-T01
# api_router.include_router(recipes.router,  prefix="/recipes",  tags=["recipes"])   # W3-T01
# api_router.include_router(calories.router, prefix="/meals",    tags=["calories"])  # W2-T12
# api_router.include_router(shopping.router, prefix="/shopping", tags=["shopping"])  # W2-T15
# api_router.include_router(chat.router,     prefix="/chat",     tags=["chatbot"])   # W3-T12
# ------------------------------------------------------------------