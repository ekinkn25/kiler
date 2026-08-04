"""W1-T07 dogrulama: sema kurallari gercekten calisiyor mu?

Kullanim (backend/ klasorunde):  python -m scripts.verify_schemas
Sunucu calismasi gerekmez; saf Pydantic dogrulamasi test edilir.
"""
from pydantic import ValidationError

from app.schemas import (
    IngredientCreate,
    PantryItemCreate,
    RegisterRequest,
    UserRead,
)

basarili = 0
basarisiz = 0


def gecerli_olmali(ad: str, fn) -> None:
    """Bu cagri BASARILI olmali."""
    global basarili, basarisiz
    try:
        fn()
        print(f"  [TAMAM] {ad}")
        basarili += 1
    except ValidationError as exc:
        print(f"  [HATA ] {ad} -> beklenmedik dogrulama hatasi:\n{exc}")
        basarisiz += 1


def reddedilmeli(ad: str, fn, beklenen_alan: str) -> None:
    """Bu cagri ValidationError FIRLATMALI."""
    global basarili, basarisiz
    try:
        fn()
        print(f"  [HATA ] {ad} -> reddedilmesi gerekirken kabul edildi!")
        basarisiz += 1
    except ValidationError as exc:
        alanlar = {".".join(str(p) for p in e["loc"]) for e in exc.errors()}
        if beklenen_alan in " ".join(alanlar) or beklenen_alan == "*":
            print(f"  [TAMAM] {ad}  ({', '.join(sorted(alanlar))})")
            basarili += 1
        else:
            print(f"  [HATA ] {ad} -> yanlis alanda hata: {alanlar}")
            basarisiz += 1


print("\n1) Gecerli veriler kabul ediliyor mu?")
gecerli_olmali(
    "PantryItemCreate: 5 kg mercimek",
    lambda: PantryItemCreate(ingredient_id=1, quantity=5, unit="kg", min_threshold=0.5),
)
gecerli_olmali(
    "PantryItemCreate: sozlukte olmayan urun (custom_name)",
    lambda: PantryItemCreate(custom_name="Anneannemin tarhanasi", quantity=2, unit="paket"),
)
gecerli_olmali(
    "IngredientCreate: gecerli canonical_name",
    lambda: IngredientCreate(canonical_name="kirmizi_mercimek", display_name="Kirmizi Mercimek"),
)
gecerli_olmali(
    "RegisterRequest: gecerli kayit",
    lambda: RegisterRequest(email="Ekin@Ornek.COM", password="GucluSifre123"),
)

print("\n2) Hatali veriler reddediliyor mu?")
reddedilmeli(
    "Negatif miktar",
    lambda: PantryItemCreate(ingredient_id=1, quantity=-5, unit="kg"),
    "quantity",
)
reddedilmeli(
    "Sifir miktar",
    lambda: PantryItemCreate(ingredient_id=1, quantity=0, unit="kg"),
    "quantity",
)
reddedilmeli(
    "Enum disi birim (ton)",
    lambda: PantryItemCreate(ingredient_id=1, quantity=5, unit="ton"),
    "unit",
)
reddedilmeli(
    "Ne ingredient_id ne custom_name",
    lambda: PantryItemCreate(quantity=5, unit="kg"),
    "*",
)
reddedilmeli(
    "canonical_name'de Turkce karakter",
    lambda: IngredientCreate(
        canonical_name="k\u0131rm\u0131z\u0131_mercimek", display_name="Kirmizi Mercimek"
    ),
    "canonical_name",
)
reddedilmeli(
    "canonical_name'de bosluk ve buyuk harf",
    lambda: IngredientCreate(canonical_name="Kirmizi Mercimek", display_name="X"),
    "canonical_name",
)
reddedilmeli(
    "Gecersiz e-posta",
    lambda: RegisterRequest(email="bu-bir-eposta-degil", password="GucluSifre123"),
    "email",
)
reddedilmeli(
    "Kisa sifre (8 karakterden az)",
    lambda: RegisterRequest(email="a@b.com", password="kisa1"),
    "password",
)
reddedilmeli(
    "Sadece rakamdan olusan sifre",
    lambda: RegisterRequest(email="a@b.com", password="123456789"),
    "password",
)

print("\n3) Donusumler ve guvenlik")
kayit = RegisterRequest(email="Ekin@Ornek.COM", password="GucluSifre123")
if kayit.email == "ekin@ornek.com":
    print("  [TAMAM] E-posta kucuk harfe normalize ediliyor")
    basarili += 1
else:
    print(f"  [HATA ] E-posta normalize edilmedi: {kayit.email}")
    basarisiz += 1

if "hashed_password" not in UserRead.model_fields:
    print("  [TAMAM] UserRead icinde hashed_password YOK")
    basarili += 1
else:
    print("  [HATA ] GUVENLIK: UserRead sifre hash'ini disari siziyor!")
    basarisiz += 1

if UserRead.model_config.get("from_attributes") is True:
    print("  [TAMAM] from_attributes=True (ORM nesnesinden sema uretilebilir)")
    basarili += 1
else:
    print("  [HATA ] from_attributes ayarli degil")