from fastapi import APIRouter
from sqlalchemy import text

from app.core.config import settings
from app.schemas.common import HealthResponse
from app.core.deps import DbSession
from app.db.mongodb import mongo

router = APIRouter(tags=["system"])


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Servis saglik kontrolu",
    description="Sunucunun ve her iki veritabaninin durumunu bildirir.",
)
def health_check(db: DbSession) -> HealthResponse:
    try:
        db.execute(text("SELECT 1"))
        sqlite_durum = "ok"
    except Exception:
        sqlite_durum = "error"

    return HealthResponse(
        status="ok" if sqlite_durum == "ok" else "degraded",
        service=settings.PROJECT_NAME,
        version=settings.VERSION,
        databases={
            "sqlite": sqlite_durum,
            "mongodb": "ok" if mongo.is_connected else "unavailable",
        },
    )