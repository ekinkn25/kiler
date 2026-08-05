"""data/recipes_seed.json dosyasini MongoDB'ye yukler.

Kullanim (backend/ klasorunde):  python -m scripts.seed_recipes

IDEMPOTENT: slug'a gore upsert yapar, tekrar calistirilabilir.
"""
import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path

from pymongo import ReplaceOne
from pymongo.errors import BulkWriteError

from app.db.mongo_schema import RECIPE_COLLECTION
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo

VERI = Path(__file__).resolve().parents[2] / "data" / "recipes_seed.json"


async def main() -> None:
    tarifler = json.loads(VERI.read_text("utf-8"))
    print(f"Dosyada {len(tarifler)} tarif var.")

    await connect_to_mongo()
    if not mongo.is_connected:
        print("MongoDB baglantisi yok.")
        return

    kol = mongo.database[RECIPE_COLLECTION]
    simdi = datetime.now(timezone.utc)

    islemler = []
    for t in tarifler:
        t["created_at"] = simdi
        t["updated_at"] = simdi
        islemler.append(ReplaceOne({"slug": t["slug"]}, t, upsert=True))

    try:
        sonuc = await kol.bulk_write(islemler, ordered=False)
        print(f"Eklenen : {sonuc.upserted_count}")
        print(f"Guncel  : {sonuc.modified_count}")
    except BulkWriteError as exc:
        print(f"\n{len(exc.details['writeErrors'])} dokuman REDDEDILDI:\n")
        for hata in exc.details["writeErrors"][:10]:
            slug = hata.get("op", {}).get("q", {}).get("slug", "?")
            detay = hata.get("errInfo", {}).get("details", {})
            print(f"  - {slug}: {json.dumps(detay, ensure_ascii=False)[:300]}")
        print("\n(MongoDB $jsonSchema dogrulayicisi devrede - bu iyi bir sey.)")

    toplam = await kol.count_documents({})
    print(f"\nKoleksiyondaki toplam tarif: {toplam}")

    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())