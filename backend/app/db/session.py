from collections.abc import Generator

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
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

@event.listens_for(Engine, "connect") # burada kullanılan yapı decorator(süsleyici): bu satırla sqlalchemy'e şunu emrediyoruz arka planda ne zaman yeni bir veri tabanı motoru(engine) bağlanıtıs kurulursa, araya gir ve bağlantı havuza dönmeden hemen bu fonksiyonu çalıştır
def _set_sqlite_pragma(dbapi_connection, connection_record) -> None: 
    """SQLite bağlantılarında foreign key zorlaması ve WAL modunu açar
    SQLite'da fk zorlaması varsayılan olarak kapalıdır. Bu ayar olmadan ON DELETE CASCADE çalışmaz
    Kullanıcı silindiğinde ilişkili kayıtlar yetim kalır ayrıca kvkk veri imhasını karşılamaz"""

    #postreSQL'e geçilirse bu blok atılmalı
    if "sqlite" not in engine.url.drivername:
        return
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.execute("PRAGMA journal_mode=WAL")
#WAL: write ahead logging
#Geleneksel Model (Rollback Journal): Biri veritabanına küçücük bir veri yazarken, SQLite tüm veritabanı dosyasını kilitler. O sırada okuma yapmak isteyen herkes bekler. FastAPI gibi asenkron ve çoklu istek alan yapılarda bu anında darboğaz (bottleneck) yaratır ve meşhur "database is locked" hatasını alırsın.
#WAL Modu: Veritabanını kilitlemek yerine, yazılacak verileri önce geçici bir -wal uzantılı dosyaya kaydeder. Bu harika mimari sayesinde aynı anda birçok okuyucu (reader) ve bir yazar (writer) birbirini beklemeden çalışabilir. Performans dramatik şekilde artar.

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