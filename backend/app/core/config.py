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

    # ---------- Kiler davranisi ----------
    # Bir malzeme kilere eklendiginde kac gun boyunca 'var' sayilir.
    # Sure dolunca otomatik 'bilinmiyor'a duser ve oneri agirligi azalir.
    # Sabit kodlanmadi: gercek kullanimda 5 mi 10 mu daha iyi, denenebilsin.
    PANTRY_CONFIDENCE_DAYS: int = 7

    # 'bilinmiyor' durumundaki malzemenin oneri skorundaki agirligi.
    # 'var' = 1.0 kabul edilir.
    PANTRY_UNKNOWN_WEIGHT: float = 0.4

        # ---------- Tarif skorlama (W2-T06) ----------
    # Toplamlari 1.0 olmali. Sabit kodlanmadi: A/B denemesi yapilabilsin.
    SCORE_W_PANTRY: float = 0.50
    SCORE_W_CALORIE: float = 0.20
    SCORE_W_TASTE: float = 0.20
    SCORE_W_TIME: float = 0.10

    # Gunluk kalori hedefinin kaca bolunecegi (3 ogun varsayimi).
    SCORE_MEALS_PER_DAY: int = 3

    # Bu surenin altindaki tarifler tam puan alir; ustunde dogrusal duser
    # ve 3 katinda sifirlanir.
    SCORE_TARGET_MINUTES: int = 45

        # ---------- Gorme modeli (cok kipli LLM) ----------
    # fake | groq | openai   -- VARSAYILAN 'fake': API anahtari olmadan da
    # uygulama calisir, testler ag baglantisi istemez.
    VISION_PROVIDER: str = "fake"
    VISION_API_KEY: str = ""
    # Model kimligi saglayiciya gore degisir ve zamanla guncellenir.
    # Kullanmadan once saglayicinin guncel model listesinden DOGRULA.
    VISION_MODEL: str = ""
    VISION_TIMEOUT_SECONDS: int = 20
    VISION_MAX_RETRIES: int = 2

    # Goruntu on isleme: token maliyetini dogrudan etkiler.
    # 1600 px + %80 kalite, 3 MB'lik bir fotografi ~400 KB'a indirir.
    VISION_MAX_IMAGE_PX: int = 1600
    VISION_JPEG_QUALITY: int = 80

    # Kullanici basina gunluk fotograf limiti (maliyet korumasi)
    VISION_DAILY_LIMIT_PER_USER: int = 30

    # Sohbet asistani / RAG
    # fake | groq  -- VARSAYILAN 'fake'
    CHAT_PROVIDER: str = "fake"
    # Bos ise GROQ_MODEL kullanilir (mevcut GROQ ayarlari).
    CHAT_MODEL: str = ""
    CHAT_TIMEOUT_SECONDS: int = 20
    CHAT_MAX_RETRIES: int = 2
    CHAT_MAX_TOKENS: int = 1024
    CHAT_JSON_MODE: bool = True
    # Akil yurutme modelleri icin (bkz. VISION_REASONING_EFFORT gerekcesi).
    CHAT_REASONING_EFFORT: str = "none"

    # Prompt'a gomulecek en fazla aday tarif sayisi. Gorev tanimi 5-8 diyor.
    CHAT_MAX_CANDIDATES: int = 8
    # Ayni baglamda ayni soru tekrar sorulursa API'ye gitmez.
    CHAT_CACHE_TTL_MINUTES: int = 30
    CHAT_DAILY_LIMIT_PER_USER: int = 50


    # Bu esigin altindaki sonuclar onay ekranina hic gelmez.
    # 0.15: model "belki bir sey var" dediginde gostermek kullaniciyi yorar.
    VISION_MIN_CONFIDENCE: float = 0.15

    # Tek fotograftan donecek en fazla malzeme sayisi (UI kalabaligi korumasi)
    VISION_MAX_ITEMS: int = 25

    # Akil yurutme modelleri response_format=json_object ile calismiyor:
    # <think> blogu dogrulamayi patlatiyor. Kapatildiginda extract_json
    # ayristirir.
    VISION_JSON_MODE: bool = True
    VISION_MAX_TOKENS: int = 6000
    VISION_REASONING_EFFORT: str = "none"

    #öğün tahmini
    MEAL_GRAMS_SMALL: float = 200
    MEAL_GRAMS_MEDIUM: float = 350
    MEAL_GRAMS_LARGE: float = 500
    MEAL_TITLE_MATCH_TREASHOLD: int = 85

    #  Open Food Facts
    OFF_TIMEOUT_SECONDS: int = 5
    OFF_MAX_RETRIES: int = 2
    # Onbellekteki urun kac gun 'taze' sayilir; bu sureden eskiyse OFF'tan tekrar cekilir. Besin degerleri sik degismez, 30 gun makul.
    OFF_CACHE_DAYS: int = 30


@lru_cache
def get_settings() -> Settings:
    """Ayarlar bir kez okunur, sonraki cagrilar onbellekten doner.env diskten bir kez okunur, her istekte tekrar okunmaz."""
    return Settings()


settings = get_settings()