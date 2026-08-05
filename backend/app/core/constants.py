"""Iki veritabaninda da kullanilan sabit kod listeleri.

TEK DOGRULUK KAYNAGI: MongoDB $jsonSchema dogrulayicisi ve SQLite
sozluk tablolarinin seed'i bu listeden beslenir. Yeni bir etiket
eklenecekse yalnizca burasi degistirilir.
"""

# (kod, gorunen_ad)
DIET_TAGS: list[tuple[str, str]] = [
    ("vegan", "Vegan"),
    ("vejetaryen", "Vejetaryen"),
    ("glutensiz", "Glutensiz"),
    ("laktozsuz", "Laktozsuz"),
    ("ketojenik", "Ketojenik"),
    ("dusuk_karbonhidrat", "Düşük Karbonhidrat"),
]

ALLERGENS: list[tuple[str, str]] = [
    ("gluten", "Gluten"),
    ("laktoz", "Laktoz"),
    ("findik", "Fındık"),
    ("yer_fistigi", "Yer Fıstığı"),
    ("yumurta", "Yumurta"),
    ("soya", "Soya"),
    ("deniz_urunu", "Deniz Ürünü"),
    ("susam", "Susam"),
]

CATEGORIES: list[tuple[str, str]] = [
    ("bakliyat", "Bakliyat"),
    ("sut_urunleri", "Süt Ürünleri"),
    ("et_tavuk", "Et ve Tavuk"),
    ("manav", "Manav"),
    ("kuru_gida", "Kuru Gıda"),
    ("baharat", "Baharat"),
    ("icecek", "İçecek"),
    ("dondurulmus", "Dondurulmuş"),
    ("diger", "Diğer"),
]

DIFFICULTIES: tuple[str, ...] = ("kolay", "orta", "zor")

CUISINES: tuple[str, ...] = (
    "turk", "italyan", "uzakdogu", "akdeniz", "meksika", "hint", "diger",
)

DIET_TAG_CODES = [code for code, _ in DIET_TAGS]
ALLERGEN_CODES = [code for code, _ in ALLERGENS]
CATEGORY_CODES = [code for code, _ in CATEGORIES]