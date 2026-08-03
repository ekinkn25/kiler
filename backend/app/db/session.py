from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

# SQLite tek is parcacigi (thread) varsayar; FastAPI cok is parcacikli
# calistigi icin bu kontrolu kapatmamiz gerekiyor.
connect_args = ( #trafik kontrolü 
    #asenkron pipeline kurarken karşılaşan en klasik sorunlardan birin: thread çakışmasıdır, fastapi multi threaddir fakat sqllite single threadedtır
    {"check_same_thread": False} if settings.DATABASE_URL.startswith("sqlite") else {}
)

engine = create_engine( #iletişim motoru:SQLAlchemy kütüphanesinin kalbidir. Python'un yazdığı kodları, veritabanının anlayacağı SQL dillerine çeviren ana motordur.
    settings.DATABASE_URL,
    connect_args=connect_args,
    echo=settings.DEBUG,   # DEBUG modda uretilen SQL sorgularini loga basar
    future=True,
)

SessionLocal = sessionmaker(    #oturum fabrikası:engine anabağlantı hattı fakat her müşteri için bu hattı sürekli açık tutmak yorar her yeni istek geldiğinde kısa süreli bir session açılıp kapatılmalıdır, sessionmaker da bunun fabrikasıdır
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False, #python ile veriyi dbye kayıt ettikten sonra normalde sqlalchemy o veriyi python hafızasından siler bu özl false yaparak veriyi kaydettikten sonra bile kullanıcıya json olarak geri döndürülür
)


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency: her istek icin bir oturum acar, sonunda kapatir.

    Kullanimi (W1-T08'den itibaren):
        @router.get("/pantry")
        def list_items(db: Session = Depends(get_db)):
            ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()