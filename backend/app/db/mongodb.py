"""MongoDB bağlantı yönetimi
bağlantı uyg açılınca bir kez kurulur ve kapanışta bırakılır her istekre yeni bağlantı açmak atlasın ücretsiz katman bağlantı limitini hızla tüketir
AsyncIOMotorClient, MongoDB'nin resmi Python sürücüsü olan pymongo'nun asenkron (asyncio uyumlu) sarmalayıcısı Motor'dan geliyor. FastAPI async çalıştığı için senkron pymongo kullanırsan her sorgu event loop'u bloklar; Motor bunu engelliyor.
SQL'deki table -> burada collection 
row -> document
column -> field
CREATE TABLE -> şema yok yazınca oluşur 
mongo dbde veri tabanı ve koleksiyon önceden oluşturulmaz, sunucuta bir şey gitmez sadece bu iismli dbye referans nesnesi alırız
gerçek oluşum ilk insert ile olur
"""

import logging
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase # sunucuta bağlantı ve o sunucuudaki tek bir veri tabnaı
from pymongo.errors import PyMongoError #motor kendi hata sınıflarını üretemiyorpymangonunkileri fırlatır

from app.core.config import settings
from app.core.exceptions import ExternalServiceError

logger = logging.getLogger(__name__)

class MongoState:
    """uygulama ömrü boyunca yaşayan bağlantı durumu"""
    client: AsyncIOMotorClient | None = None
    database: AsyncIOMotorDatabase | None = None
    is_connected: bool = False

mongo = MongoState()

async def connect_to_mongo() -> None:
    """Acilista cagrilir. Baglanti kurulamazsa uygulama YINE DE baslar.

    Gerekce: SQLite tabanli ozellikler (auth, kiler, kalori) MongoDB'den
    bagimsizdir. Tarif servisi coktu diye tum uygulamanin acilmamasi
    dayaniksiz bir tasarim olurdu. Mongo'ya bagimli uclar 502 doner.
    """
    if not settings.MONGODB_URI:
        logger.warning("MONGODB_URI tanimli degil; tarif ozellikleri devre disi.")
        return

    try:
        mongo.client = AsyncIOMotorClient(
            settings.MONGODB_URI,
            serverSelectionTimeoutMS=5000,   # varsayilan 30 sn; acilisi bekletmesin: uygun unucu bulmak için en fazla 5 sn bekle
            connectTimeoutMS=5000,           #tcp soket kurulumu için ayrı zaman aşımı
            maxPoolSize=10,                  # M0 katmani icin fazlasi gereksiz: havuzda en fazla 10 eşzamanlı soket
            minPoolSize=1,                   #boştayken bile 1 soket açık kalsın
            retryWrites=True,                #yazma işlemi geçici ağ hatasıyla düşerse sürücü bir kez otomatik tekrar dener
            appname="kalori-sayaci-api",     # Atlas panelinde kim baglandi gorunur
        )
        await mongo.client.admin.command("ping")
        mongo.database = mongo.client[settings.MONGODB_DB_NAME]
        mongo.is_connected = True
        logger.info(
            "MongoDB baglantisi kuruldu (veritabani: %s)", settings.MONGODB_DB_NAME
        )
    except PyMongoError as exc:
        mongo.is_connected = False
        logger.error("MongoDB baglanti hatasi: %s", exc)
        """Küçük bir eksik: Ping başarısız olursa mongo.client atanmış durumda kalıyor ama kapatılmıyor — arka planda sunucuyu aramaya 
        devam eden bir soket sızıntısı olur. except bloğuna mongo.client.close(); mongo.client = None eklemek daha temiz olur."""


async def close_mongo_connection() -> None:
    """Kapanista cagrilir; acik soketleri duzgunce birakir.Havuzdaki tüm soketleri ırak await yok çünkü motorda close() senkron bir metottur"""
    if mongo.client is not None:
        mongo.client.close()
        mongo.is_connected = False
        logger.info("MongoDB baglantisi kapatildi.")


def get_database() -> AsyncIOMotorDatabase:
    """FastAPI dependency: tarif uclarinin kullanacagi veritabani nesnesi. Datığım noktası"""
    if not mongo.is_connected or mongo.database is None:
        raise ExternalServiceError("Tarif veritabanina su anda ulasilamiyor.")
    return mongo.database

"""7. Kodun zayıf noktası (ileride karşınıza çıkacak)

is_connected sadece açılışta bir kez ayarlanıyor. Yani:

Açılışta bağlantı başarısızsa → uygulama ömrü boyunca tarif uçları 502. Mongo sonradan ayağa kalksa bile kendini toparlamaz.
Açılışta başarılıysa ama Mongo sonradan çökerse → is_connected hâlâ True, get_database nesneyi verir, patlama asıl sorgu sırasında ServerSelectionTimeoutError olarak gelir.

Öğrenme aşamasında bu tamamen kabul edilebilir. İlerde isterseniz /health ucunda periyodik ping atıp bayrağı güncelleyebilir, ya da get_database yerine sorguları saran bir yardımcı fonksiyonda PyMongoError'ı yakalayıp 502'ye çevirebilirsiniz."""