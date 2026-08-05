"""W1-T10 dogrulama: dogrulayici gercekten reddediyor mu, indeksler var mi?

Kullanim (backend/ klasorunde):  python -m scripts.verify_mongo_schema
Test dokumanlari islem sonunda temizlenir.
"""
import asyncio
from datetime import datetime, timezone

from pymongo.errors import WriteError

from app.db.mongo_schema import RECIPE_COLLECTION
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


GECERLI_TARIF = {
    "title": "Test Mercimek Corbasi",
    "slug": "test-mercimek-corbasi",
    "description": "Dogrulama testi icin gecici tarif.",
    "image_url": None,
    "ingredients": [
        {"name": "Kirmizi Mercimek", "canonical_name": "kirmizi_mercimek",
         "quantity": 200, "unit": "g", "optional": False, "note": None},
        {"name": "Sogan", "canonical_name": "sogan",
         "quantity": 1, "unit": "adet", "optional": False, "note": "ince kiyilmis"},
        {"name": "Tuz", "canonical_name": "tuz",
         "quantity": None, "unit": None, "optional": True, "note": None},
    ],
    "steps": ["Mercimegi yikayin.", "Sogani kavurun.", "Su ekleyip 25 dakika pisirin."],
    "servings": 4,
    "prep_time": 10,
    "cook_time": 25,
    "difficulty": "kolay",
    "calories_per_serving": 180.5,
    "macros": {"protein_g": 9.0, "carb_g": 28.0, "fat_g": 3.5, "fiber_g": 6.0},
    "diet_tags": ["vegan", "glutensiz"],
    "allergens": [],
    "cuisine": "turk",
    "source": "manuel",
    "source_url": None,
    "is_active": True,
    "created_at": datetime.now(timezone.utc),
    "updated_at": datetime.now(timezone.utc),
}


async def reddedilmeli(koleksiyon, ad: str, dokuman: dict) -> None:
    global basarili, basarisiz
    try:
        sonuc = await koleksiyon.insert_one(dokuman)
        await koleksiyon.delete_one({"_id": sonuc.inserted_id})
        print(f"  [HATA ] {ad} -> reddedilmesi gerekirken KABUL EDILDI")
        basarisiz += 1
    except WriteError:
        print(f"  [TAMAM] {ad}")
        basarili += 1


async def main() -> None:
    await connect_to_mongo()
    if not mongo.is_connected:
        print("MongoDB baglantisi yok.")
        return

    db = mongo.database
    kol = db[RECIPE_COLLECTION]

    print("\n1) Koleksiyon ve dogrulayici")
    koleksiyonlar = await db.list_collection_names()
    kontrol("'recipes' koleksiyonu var", RECIPE_COLLECTION in koleksiyonlar)

    bilgi = await db.command("listCollections", filter={"name": RECIPE_COLLECTION})
    secenekler = bilgi["cursor"]["firstBatch"][0]["options"]
    kontrol("Dogrulayici tanimli", "validator" in secenekler)
    kontrol("validationLevel = strict", secenekler.get("validationLevel") == "strict")
    kontrol("validationAction = error", secenekler.get("validationAction") == "error")

    print("\n2) Indeksler")
    indeksler = {}
    async for ix in kol.list_indexes():
        indeksler[ix["name"]] = ix
    for ad in ("uq_slug", "ix_ingredient_canonical", "ix_diet_tags",
               "ix_allergens", "ix_calories", "ix_diet_calories", "ix_title_text"):
        kontrol(f"Indeks '{ad}' mevcut", ad in indeksler)
    kontrol("slug indeksi UNIQUE", indeksler.get("uq_slug", {}).get("unique") is True)

    print("\n3) Gecerli dokuman kabul ediliyor mu?")
    await kol.delete_many({"slug": {"$regex": "^test-"}})
    try:
        sonuc = await kol.insert_one(dict(GECERLI_TARIF))
        kontrol("Gecerli tarif eklendi", sonuc.inserted_id is not None)
        eklenen_id = sonuc.inserted_id
    except WriteError as exc:
        kontrol("Gecerli tarif eklendi", False, f"-> {exc}")
        eklenen_id = None

    print("\n4) Hatali dokumanlar reddediliyor mu?")
    import copy

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-1"; del d["title"]
    await reddedilmeli(kol, "Zorunlu alan eksik (title)", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-2"; d["calories_per_serving"] = "180 kcal"
    await reddedilmeli(kol, "Yanlis tip (kalori metin)", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-3"; d["ingredients"] = []
    await reddedilmeli(kol, "Bos malzeme dizisi", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-4"; d["diet_tags"] = ["paleo"]
    await reddedilmeli(kol, "Tanimsiz diyet etiketi (paleo)", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-5"
    d["ingredients"][0]["unit"] = "ton"
    await reddedilmeli(kol, "Tanimsiz birim (ton)", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-6"
    d["ingredients"][0]["canonical_name"] = "kirmizi mercimek"
    await reddedilmeli(kol, "canonical_name'de bosluk", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "Test-Buyuk-Harf"
    await reddedilmeli(kol, "slug'da buyuk harf", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-7"; d["calorie_per_serving"] = 180
    await reddedilmeli(kol, "Tanimsiz alan (yazim hatasi)", d)

    d = copy.deepcopy(GECERLI_TARIF); d["slug"] = "test-8"; d["servings"] = 0
    await reddedilmeli(kol, "servings = 0", d)

    print("\n5) Tekillik ve indeks kullanimi")
    if eklenen_id:
        try:
            await kol.insert_one(dict(GECERLI_TARIF))
            kontrol("Ayni slug iki kez eklenemiyor", False, "-> mukerrer kabul edildi")
        except Exception:
            kontrol("Ayni slug iki kez eklenemiyor", True)

        plan = await kol.find({"diet_tags": "vegan"}).explain()
        asama = str(plan.get("queryPlanner", {}).get("winningPlan", {}))
        kontrol("diet_tags sorgusu INDEKS kullaniyor", "IXSCAN" in asama,
                "(COLLSCAN goruluyorsa indeks devrede degil)")

        await kol.delete_one({"_id": eklenen_id})

    await kol.delete_many({"slug": {"$regex": "^test-"}})
    await close_mongo_connection()

    print(f"\n{'-' * 55}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")


if __name__ == "__main__":
    asyncio.run(main())