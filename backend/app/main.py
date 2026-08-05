import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.routers import health
from app.routers.api_v1 import api_router

logging.basicConfig(
    # Uygulamada olan biten her şeyi (kim girdi, nerede hata oldu, hangi veri çekildi) terminale veya bir dosyaya yazdırmak içindir
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)

logging.getLogger("app").setLevel(logging.DEBUG if settings.DEBUG else logging.INFO)
for gurultu in ("asynvio", "passlib", "httpx", "watchfiles", "multipart"):
    logging.getLogger(gurultu).setLevel(logging.WARNING)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama acilis/kapanis yasam dongusu.

    W1-T09'da MongoDB baglantisi burada acilip kapatilacak.
    """
    logger.info("%s v%s baslatiliyor...", settings.PROJECT_NAME, settings.VERSION)
    yield
    logger.info("%s kapatiliyor...", settings.PROJECT_NAME)


def create_app() -> FastAPI:
    """Uygulama fabrikasi. Test icin ayri bir ornek uretmeyi kolaylastirir."""
    application = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        description=(
            "Kiler yonetimi, kalori takibi ve yapay zeka destekli "
            "tarif onerisi sunan mobil uygulamanin backend servisi."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # ---------- CORS ----------
    # Kimlik dogrulamada cerez degil Bearer token kullandigimiz icin
    # allow_credentials=False birakiyoruz. ("*" ile True birlikte
    # kullanilamaz; tarayici bu kombinasyonu reddeder.)
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ---------- Global hata yakalayicilar ----------
    register_exception_handlers(application)

    # ---------- Router'lar ----------
    # /health surum disidir: izleme araclari sabit bir adres bekler.
    application.include_router(health.router)
    # Is mantigina ait tum uclar surumlenmis prefix altinda toplanir.
    application.include_router(api_router, prefix=settings.API_V1_PREFIX)

    return application


app = create_app()