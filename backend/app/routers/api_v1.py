from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/ping", tags=["system"], summary="Versiyonlu API canlilik testi")
def ping() -> dict[str, bool]:
    return {"pong": True}


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