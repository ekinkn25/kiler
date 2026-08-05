from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/ klasorunun mutlak yolu (config.py -> core -> app -> backend)
BASE_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    """Tum uygulama ayarlari. Degerler .env dosyasindan okunur."""

    model_config = SettingsConfigDict(
        env_file=BASE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # ---------- Uygulama ----------
    PROJECT_NAME: str = "Kalori Sayaci API"
    VERSION: str = "0.1.0"
    API_V1_PREFIX: str = "/api/v1" #mobil uygulama veya web sitesinin) bizimle konuşurken kullanacağı kapı numarasıdır
    DEBUG: bool = True #"Geliştirici Modu" açık, canlıya çıkarken bunu false yapmalıyız
    SQL_ECHO: bool = False

    # ---------- Guvenlik ---------- : sisteme giriş yapan kullanıcılara dijital token verilir bu token SECRET_KEY sadece senin bildiğin bir şifreyle mühürlenir
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ---------- Veritabanlari ----------
    DATABASE_URL: str = f"sqlite:///{BASE_DIR / 'kalori.db'}"
    MONGODB_URI: str = ""
    MONGODB_DB_NAME: str = "kalori"

    # ---------- Dis servisler ----------: uygulamanın dünyadaki diğer uyglarla konuşmasını sağlar 
    OPENFOODFACTS_BASE_URL: str = "https://world.openfoodfacts.org"
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.1-8b-instant"

    # ---------- CORS ----------: hangi yabancı web siteleri benim mutfağımdan veri isteyebilir, şuan herkese açık 
    # Mobil uygulamalar CORS uygulamaz; bu ayar Swagger UI ve
    # Flutter Web ile gelistirme yaparken gerekli olur.
    CORS_ORIGINS: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    """Ayarlar bir kez okunur, sonraki cagrilar onbellekten doner.env diskten bir kez okunur, her istekte tekrar okunmaz."""
    return Settings()


settings = get_settings()