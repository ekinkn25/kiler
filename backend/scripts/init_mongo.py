"""recipes koleksiyonunu, dogrulayicisini ve indekslerini olusturur/gunceller.

Kullanim (backend/ klasorunde):  python -m scripts.init_mongo

Bu betik IDEMPOTENT'tir: kac kez calistirilirsa calistirilsin ayni sonucu
verir. MongoDB tarafinda Alembic'in karsiligi gibi dusun.
"""
import asyncio

from pymongo.errors import CollectionInvalid, OperationFailure

from app.db.mongo_schema import RECIPE_COLLECTION, RECIPE_INDEXES, RECIPE_VALIDATOR
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo


async def main() -> None:
    await connect_to_mongo()
    if not mongo.is_connected:
        print("MongoDB baglantisi kurulamadi. Once verify_mongo betigini calistir.")
        return

    db = mongo.database
    mevcut = await db.list_collection_names()

    # ---------- 1) Koleksiyon + dogrulayici ----------
    if RECIPE_COLLECTION not in mevcut:
        try:
            await db.create_collection(
                RECIPE_COLLECTION,
                validator=RECIPE_VALIDATOR,
                validationLevel="strict",   # ekleme VE guncellemelerde uygulanir
                validationAction="error",   # uyari degil, RED
            )
            print(f"[OLUSTURULDU] '{RECIPE_COLLECTION}' koleksiyonu + dogrulayici")
        except CollectionInvalid:
            print(f"[VAR] '{RECIPE_COLLECTION}' zaten mevcut")
    else:
        await db.command(
            "collMod",
            RECIPE_COLLECTION,
            validator=RECIPE_VALIDATOR,
            validationLevel="strict",
            validationAction="error",
        )
        print(f"[GUNCELLENDI] '{RECIPE_COLLECTION}' dogrulayicisi yenilendi")

    # ---------- 2) Indeksler ----------
    try:
        olusturulan = await db[RECIPE_COLLECTION].create_indexes(RECIPE_INDEXES)
        print(f"[INDEKS] {len(olusturulan)} indeks uygulandi")
    except OperationFailure as exc:
        # Turkce metin indeksi desteklenmezse dilsiz surume dus
        if "language" in str(exc).lower():
            print("[UYARI] 'turkish' metin dili desteklenmiyor; 'none' ile deneniyor.")
            from pymongo import TEXT, IndexModel

            yedek = RECIPE_INDEXES[:-1] + [
                IndexModel([("title", TEXT)], name="ix_title_text", default_language="none")
            ]
            await db[RECIPE_COLLECTION].create_indexes(yedek)
            print(f"[INDEKS] {len(yedek)} indeks uygulandi (metin dili: none)")
        else:
            raise

    # ---------- 3) Ozet ----------
    print("\nMevcut indeksler:")
    async for ix in db[RECIPE_COLLECTION].list_indexes():
        anahtarlar = ", ".join(f"{k}:{v}" for k, v in ix["key"].items())
        etiket = " [UNIQUE]" if ix.get("unique") else ""
        print(f"   - {ix['name']}: ({anahtarlar}){etiket}")

    sayi = await db[RECIPE_COLLECTION].count_documents({})
    print(f"\nKoleksiyondaki tarif sayisi: {sayi}")

    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())