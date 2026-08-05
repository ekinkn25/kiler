"""W1-T09 dogrulama: Atlas baglantisi, yetkiler ve gecikme olcumu.

Kullanim (backend/ klasorunde):  python -m scripts.verify_mongo
"""
import asyncio
import time

from pymongo.errors import PyMongoError

from app.core.config import settings
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo

basarili = 0
basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


async def main() -> None:
    print("\n1) Yapilandirma")
    kontrol("MONGODB_URI tanimli", bool(settings.MONGODB_URI))
    kontrol(
        "URI'de sablon metni kalmamis",
        "<db_password>" not in settings.MONGODB_URI and "<password>" not in settings.MONGODB_URI,
        "(<db_password> yerine gercek sifre yazilmali)",
    )
    kontrol("Veritabani adi tanimli", bool(settings.MONGODB_DB_NAME),
            f"-> {settings.MONGODB_DB_NAME}")

    if not settings.MONGODB_URI:
        print("\nMONGODB_URI bos; testler durduruldu.")
        return

    print("\n2) Baglanti")
    t0 = time.perf_counter()
    await connect_to_mongo()
    sure_ms = (time.perf_counter() - t0) * 1000
    kontrol("Baglanti kuruldu", mongo.is_connected, f"({sure_ms:.0f} ms)")

    if not mongo.is_connected:
        print("\nBaglanti kurulamadi. Kontrol listesi:")
        print("  - Atlas > Network Access: mevcut IP adresin ekli mi?")
        print("  - Kullanici adi/sifre dogru mu? (sifrede ozel karakter var mi?)")
        print("  - dnspython kurulu mu? (pip install 'pymongo[srv]')")
        print("  - Aginda 27017 portu engelli olabilir; mobil hotspot ile dene.")
        return

    print("\n3) Sunucu bilgisi")
    try:
        bilgi = await mongo.client.server_info()
        kontrol("Sunucu surumu okundu", True, f"-> MongoDB {bilgi.get('version')}")
    except PyMongoError as exc:
        kontrol("Sunucu surumu okundu", False, str(exc))

    print("\n4) Yazma / okuma / silme yetkisi")
    koleksiyon = mongo.database["_baglanti_testi"]
    try:
        sonuc = await koleksiyon.insert_one({"test": True, "kaynak": "verify_mongo"})
        kontrol("Yazma yetkisi (insert)", sonuc.inserted_id is not None)

        dokuman = await koleksiyon.find_one({"_id": sonuc.inserted_id})
        kontrol("Okuma yetkisi (find)", dokuman is not None)

        silinen = await koleksiyon.delete_one({"_id": sonuc.inserted_id})
        kontrol("Silme yetkisi (delete)", silinen.deleted_count == 1)

        await mongo.database.drop_collection("_baglanti_testi")
    except PyMongoError as exc:
        kontrol("Yazma/okuma/silme", False, f"-> {exc}")
        print("     Ipucu: Atlas > Database Access > kullanicinin rolu")
        print("            'Read and write to any database' olmali.")

    print("\n5) Gecikme olcumu (5 ping ortalamasi)")
    sureler = []
    for _ in range(5):
        t = time.perf_counter()
        await mongo.client.admin.command("ping")
        sureler.append((time.perf_counter() - t) * 1000)
    ortalama = sum(sureler) / len(sureler)
    kontrol("Ortalama ping < 300 ms", ortalama < 300, f"-> {ortalama:.0f} ms")

    await close_mongo_connection()

    print(f"\n{'-' * 50}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")


if __name__ == "__main__":
    asyncio.run(main())