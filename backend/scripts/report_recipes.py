"""Yuklenen tariflerin kalite raporu.

Kullanim (backend/ klasorunde):  python -m scripts.report_recipes
"""
import asyncio

from app.db.mongo_schema import RECIPE_COLLECTION
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo


async def main() -> None:
    await connect_to_mongo()
    kol = mongo.database[RECIPE_COLLECTION]

    toplam = await kol.count_documents({})
    print(f"Toplam tarif                : {toplam}")
    print(f"Kalorisi 0 veya eksik       : {await kol.count_documents({'calories_per_serving': {'$lte': 0}})}")
    print(f"Malzemesi bos               : {await kol.count_documents({'ingredients': {'$size': 0}})}")
    print(f"Adimi bos                   : {await kol.count_documents({'steps': {'$size': 0}})}")
    print(f"Vegan etiketli              : {await kol.count_documents({'diet_tags': 'vegan'})}")
    print(f"Glutensiz etiketli          : {await kol.count_documents({'diet_tags': 'glutensiz'})}")
    print(f"30 dk altinda hazirlanabilir: {await kol.count_documents({'$expr': {'$lte': [{'$add': ['$prep_time', '$cook_time']}, 30]}})}")

    # canonical_name kapsama orani
    boru = [
        {"$unwind": "$ingredients"},
        {"$group": {
            "_id": None,
            "toplam": {"$sum": 1},
            "eslesen": {"$sum": {"$cond": [{"$ne": ["$ingredients.canonical_name", None]}, 1, 0]}},
        }},
    ]
    async for satir in kol.aggregate(boru):
        oran = satir["eslesen"] / satir["toplam"] * 100
        print(f"\nMalzeme kapsama orani       : %{oran:.1f} "
              f"({satir['eslesen']}/{satir['toplam']})  [hedef: %90+]")

    print("\nEn sik gecen 15 malzeme:")
    boru2 = [
        {"$unwind": "$ingredients"},
        {"$match": {"ingredients.canonical_name": {"$ne": None}}},
        {"$group": {"_id": "$ingredients.canonical_name", "n": {"$sum": 1}}},
        {"$sort": {"n": -1}}, {"$limit": 15},
    ]
    async for satir in kol.aggregate(boru2):
        print(f"   {satir['n']:3d}  {satir['_id']}")

    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())