"""Tum tariflere kategori bazli gorsel URL'i atar (demo icin).

Kaynak: loremflickr - anahtar-kelimeye gore Flickr CC fotografi doner,
API anahtari GEREKTIRMEZ. Her tarife slug'dan turetilen sabit bir 'lock'
verilir; boylece ayni tarif her seferinde AYNI gorseli alir (onbelleklenebilir).

Kullanim (backend/ klasorunde):
    .venv\\Scripts\\python.exe scripts\\set_recipe_images.py
"""
import hashlib

import pymongo

MONGO_URI = "mongodb://127.0.0.1:27017"
DB_NAME = "kalori"


def _kategori(title: str) -> str:
    """Baslik anahtar kelimesinden loremflickr sorgu terimi."""
    t = title.lower()
    if "çorba" in t or "corba" in t:
        return "soup,bowl"
    if "köfte" in t or "kofte" in t:
        return "meatballs"
    if "tavuk" in t:
        return "chicken,dish"
    if any(w in t for w in ["börek", "borek", "poğaça", "pogaca", "açma", "acma", "simit", "tost", "pide"]):
        return "pastry,bread"
    if "pilav" in t:
        return "rice,pilaf"
    if "makarna" in t:
        return "pasta"
    if "mantı" in t or "manti" in t:
        return "dumplings"
    if any(w in t for w in ["karnıyarık", "karniyarik", "imambayıldı", "imambayildi", "patlıcan", "patlican", "musakka"]):
        return "eggplant,cooked"
    if any(w in t for w in ["menemen", "yumurta", "omlet", "sucuklu"]):
        return "breakfast,eggs"
    if any(w in t for w in ["fasulye", "nohut", "barbunya", "bezelye", "mercimekli"]):
        return "beans,stew"
    if any(w in t for w in ["zeytinyağlı", "zeytinyagli", "ıspanak", "ispanak", "kabak", "pırasa", "pirasa", "enginar", "türlü", "turlu", "sebze"]):
        return "vegetables,cooked"
    if "kısır" in t or "kisir" in t or "salata" in t:
        return "salad"
    if any(w in t for w in ["tatlı", "tatli", "baklava", "sütlaç", "sutlac", "kek", "kurabiye", "helva"]):
        return "dessert,turkish"
    return "turkish,food"


def _url(title: str, slug: str) -> str:
    kw = _kategori(title)
    lock = int(hashlib.md5(slug.encode()).hexdigest(), 16) % 100000
    return f"https://loremflickr.com/800/600/{kw}?lock={lock}"


def main() -> None:
    client = pymongo.MongoClient(MONGO_URI)
    kol = client[DB_NAME]["recipes"]

    n = 0
    for r in kol.find({}, {"title": 1, "slug": 1}):
        kol.update_one(
            {"_id": r["_id"]},
            {"$set": {"image_url": _url(r["title"], r["slug"])}},
        )
        n += 1
    print(f"{n} tarife gorsel atandi.")

    # Ornek dogrulama
    ornek = kol.find_one({}, {"title": 1, "image_url": 1})
    print("Ornek:", ornek["title"], "->", ornek["image_url"])
    client.close()


if __name__ == "__main__":
    main()