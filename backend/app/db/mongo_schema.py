"""recipes koleksiyonunun $jsonSchema dogrulayicisi ve indeks tanimlari.

SQLite tarafindaki CHECK kisitlarinin doküman dünyasindaki karsiligi.
"""
from pymongo import ASCENDING, TEXT, IndexModel

from app.core.constants import ALLERGEN_CODES, CUISINES, DIET_TAG_CODES, DIFFICULTIES
from app.models.enums import UnitCode

# Birim listesi Python enum'undan uretilir; elle yazilirsa iki taraf ayrisir.
UNIT_CODES = [u.value for u in UnitCode]

RECIPE_COLLECTION = "recipes"

RECIPE_VALIDATOR = {
    "$jsonSchema": {
        "bsonType": "object",
        "title": "Tarif dokumani dogrulayicisi",
        "required": [
            "title", "slug", "ingredients", "steps",
            "servings", "calories_per_serving",
        ],
        # Tanimsiz alan reddedilir: 'calorie_per_serving' gibi yazim
        # hatalari sessizce kaydedilmek yerine hemen hata verir.
        "additionalProperties": False,
        "properties": {
            "_id": {},

            "title": {
                "bsonType": "string",
                "minLength": 2,
                "maxLength": 200,
                "description": "Tarif adi. Zorunlu.",
            },
            "slug": {
                "bsonType": "string",
                "pattern": "^[a-z0-9-]+$",
                "maxLength": 220,
                "description": "URL dostu kimlik. Yalnizca kucuk harf, rakam, tire.",
            },
            "description": {"bsonType": ["string", "null"], "maxLength": 1000},
            "image_url": {"bsonType": ["string", "null"], "maxLength": 500},

            "ingredients": {
                "bsonType": "array",
                "minItems": 1,
                "description": "Malzeme listesi. En az bir malzeme zorunlu.",
                "items": {
                    "bsonType": "object",
                    "required": ["name"],
                    "additionalProperties": False,
                    "properties": {
                        "name": {
                            "bsonType": "string",
                            "minLength": 1,
                            "maxLength": 120,
                            "description": "Kullaniciya gosterilen ad: 'Kirmizi Mercimek'",
                        },
                        "canonical_name": {
                            "bsonType": ["string", "null"],
                            "pattern": "^[a-z0-9_]+$",
                            "description": (
                                "SQLite ingredients tablosuyla BIRLESTIRME ANAHTARI. "
                                "null olabilir -> arayuzde GRI gosterilir."
                            ),
                        },
                        "quantity": {
                            "bsonType": ["double", "int", "null"],
                            "minimum": 0,
                            "description": "null olabilir ('tuz, karabiber')",
                        },
                        "unit": {"enum": UNIT_CODES + [None]},
                        "optional": {"bsonType": "bool"},
                        "note": {"bsonType": ["string", "null"], "maxLength": 120},
                    },
                },
            },

            "steps": {
                "bsonType": "array",
                "minItems": 1,
                "items": {"bsonType": "string", "minLength": 3, "maxLength": 1000},
                "description": "Numaralandirilmamis yapilis adimlari.",
            },

            "servings": {
                "bsonType": "int",
                "minimum": 1,
                "maximum": 20,
                "description": "Porsiyon olcekleme carpaninin paydasi.",
            },
            "prep_time": {"bsonType": "int", "minimum": 0, "maximum": 600},
            "cook_time": {"bsonType": "int", "minimum": 0, "maximum": 600},
            "difficulty": {"enum": list(DIFFICULTIES)},

            "calories_per_serving": {
                "bsonType": ["double", "int"],
                "minimum": 0,
                "maximum": 5000,
                "description": "Malzemelerden HESAPLANIR, veri setinden alinmaz.",
            },
            "macros": {
                "bsonType": "object",
                "additionalProperties": False,
                "properties": {
                    "protein_g": {"bsonType": ["double", "int"], "minimum": 0},
                    "carb_g": {"bsonType": ["double", "int"], "minimum": 0},
                    "fat_g": {"bsonType": ["double", "int"], "minimum": 0},
                    "fiber_g": {"bsonType": ["double", "int"], "minimum": 0},
                },
            },

            "diet_tags": {
                "bsonType": "array",
                "uniqueItems": True,
                "items": {"enum": DIET_TAG_CODES},
            },
            "allergens": {
                "bsonType": "array",
                "uniqueItems": True,
                "items": {"enum": ALLERGEN_CODES},
                "description": "GUVENLIK KRITIK: W3-T04 $nin filtresi bunu kullanir.",
            },
            "cuisine": {"enum": list(CUISINES)},

            # Kaynak bilgisi: telif ve veri kalitesi takibi icin
            "source": {"bsonType": ["string", "null"], "maxLength": 100},
            "source_url": {"bsonType": ["string", "null"], "maxLength": 500},

            "is_active": {"bsonType": "bool"},
            "created_at": {"bsonType": ["date", "null"]},
            "updated_at": {"bsonType": ["date", "null"]},
        },
    }
}

RECIPE_INDEXES = [
    # Tekillik: ayni tarif iki kez seed edilemez
    IndexModel([("slug", ASCENDING)], name="uq_slug", unique=True),

    # W3-T03: kiler eslestirmesinin omurgasi (dizi ici alan -> multikey)
    IndexModel([("ingredients.canonical_name", ASCENDING)], name="ix_ingredient_canonical"),

    # W3-T04: diyet ve alerjen filtreleri
    IndexModel([("diet_tags", ASCENDING)], name="ix_diet_tags"),
    IndexModel([("allergens", ASCENDING)], name="ix_allergens"),

    # W3-T04: kalan kaloriye gore suzme
    IndexModel([("calories_per_serving", ASCENDING)], name="ix_calories"),

    # En sik kullanilan filtre kombinasyonu: "vegan VE 500 kcal alti"
    IndexModel(
        [("diet_tags", ASCENDING), ("calories_per_serving", ASCENDING)],
        name="ix_diet_calories",
    ),

    # W3-T01: baslikta metin aramasi (Turkce govdeleme destekli)
    IndexModel([("title", TEXT)], name="ix_title_text", default_language="turkish"),
]