"""W2-T11 dogrulama: ogun kaydi API'leri.

    python -m scripts.verify_meals

MongoDB baglantisi ve seed edilmis tarifler GEREKTIRIR.
"""
import sys
from datetime import date

from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import Ingredient, MealLog, User

ONEK = settings.API_V1_PREFIX
BUGUN = date.today().isoformat()
basarili = basarisiz = 0


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def test_kullanicisi(db) -> User:
    k = db.query(User).filter(User.email == "meal_api_test@example.com").first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="meal_api_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def hazirla_malzeme(db):
    m = db.query(Ingredient).filter_by(canonical_name="domates").first()
    if m is None:
        from app.models.enums import UnitCode, UnitType
        m = Ingredient(
            canonical_name="domates", display_name="Domates",
            default_unit_type=UnitType.MASS, default_unit=UnitCode.G,
            calories_per_100g=18, protein_per_100g=0.9, carb_per_100g=3.9, fat_per_100g=0.2,
        )
        db.add(m)
        db.commit()
    return m


def temizle(db, user):
    db.query(MealLog).filter(MealLog.user_id == user.id).delete()
    db.commit()


def main() -> None:
    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)
    malzeme = hazirla_malzeme(db)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici

    with TestClient(app) as istemci:
        print("\n1) Ilk ogun - malzeme referansiyla")
        y = istemci.post(f"{ONEK}/meals", json={
            "logged_date": BUGUN, "meal_type": "kahvalti",
            "ingredient_id": malzeme.id, "quantity_g": 200, "servings": 1,
        })
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        if y.status_code != 201:
            return
        v1 = y.json()
        kontrol("calories hesaplandi", abs(v1["calories"] - 36.0) < 0.1, f"-> {v1['calories']}")
        kontrol("logged_date istemciden geldigi gibi kaydedildi",
                v1["logged_date"] == BUGUN)

        print("\n2) Ikinci ogun - serbest giris (calories elle)")
        y = istemci.post(f"{ONEK}/meals", json={
            "logged_date": BUGUN, "meal_type": "ogle",
            "custom_name": "Ev yemegi - mercimek koftesi", "calories": 300,
            "protein_g": 10, "carb_g": 45, "fat_g": 8,
        })
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        v2 = y.json()

        print("\n3) Ucuncu ogun - Mongo'daki bir tariften")
        deste = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 1}).json()
        kontrol("Bir tarif adayi bulundu", len(deste["items"]) == 1)
        tarif = deste["items"][0]

        y = istemci.post(f"{ONEK}/meals", json={
            "logged_date": BUGUN, "meal_type": "aksam",
            "recipe_id": tarif["id"], "servings": 1,
        })
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        v3 = y.json()
        kontrol("item_name tarif basligindan geldi", v3["item_name"] == tarif["title"])
        kontrol("calories tarifle eslesiyor",
                abs(v3["calories"] - tarif["calories_per_serving"]) < 0.5)

        print("\n4) GUNLUK OZET - 3 ogun toplami  <-- kabul kriteri")
        y = istemci.get(f"{ONEK}/meals/daily", params={"date": BUGUN})
        kontrol("HTTP 200", y.status_code == 200, f"-> {y.status_code} {y.text[:300]}")
        ozet = y.json()

        beklenen_toplam = round(v1["calories"] + v2["calories"] + v3["calories"], 1)
        kontrol("TOPLAM KALORI DOGRU  <-- kabul kriteri",
                abs(ozet["calories_consumed"] - beklenen_toplam) < 0.5,
                f"-> {ozet['calories_consumed']} (beklenen {beklenen_toplam})")

        beklenen_protein = round(
            (v1["protein_g"] or 0) + (v2["protein_g"] or 0) + (v3["protein_g"] or 0), 1
        )
        kontrol("MAKRO KIRILIMI DOGRU  <-- kabul kriteri",
                abs(ozet["macros_consumed"]["protein_g"] - beklenen_protein) < 0.5,
                f"-> protein {ozet['macros_consumed']['protein_g']} (beklenen {beklenen_protein})")

        kontrol("Uc kayit da ogun tiplerine dagitilmis",
                sum(len(v) for v in ozet["meals"].values()) == 3)
        kontrol("calories_remaining hesabi dogru",
                abs(ozet["calories_remaining"] -
                    (ozet["calorie_target"] - ozet["calories_consumed"])) < 0.5)

        print(f"\n  Hedef: {ozet['calorie_target']} kcal")
        print(f"  Tuketilen: {ozet['calories_consumed']} kcal")
        print(f"  Kalan: {ozet['calories_remaining']} kcal")
        print(f"  Makrolar: {ozet['macros_consumed']}")

        print("\n5) Bir ogunu sil, ozet guncelleniyor mu")
        y = istemci.delete(f"{ONEK}/meals/{v1['id']}")
        kontrol("HTTP 204", y.status_code == 204, f"-> {y.status_code}")

        y = istemci.get(f"{ONEK}/meals/daily", params={"date": BUGUN})
        ozet2 = y.json()
        kontrol("Toplam dustu", ozet2["calories_consumed"] < ozet["calories_consumed"])
        kontrol("Iki ogun kaldi", sum(len(v) for v in ozet2["meals"].values()) == 2)

        print("\n6) Baska gune sizinti yok")
        y = istemci.get(f"{ONEK}/meals/daily", params={"date": "2020-01-01"})
        kontrol("Bos gunde toplam 0", y.json()["calories_consumed"] == 0)

        print("\n7) Hatali girdiler")
        y = istemci.post(f"{ONEK}/meals", json={"logged_date": BUGUN, "meal_type": "ogle"})
        kontrol("Referans yok -> 422", y.status_code == 422, f"-> {y.status_code}")

        y = istemci.post(f"{ONEK}/meals", json={
            "logged_date": BUGUN, "meal_type": "ogle", "custom_name": "x",
        })
        kontrol("custom_name tek basina + calories yok -> 422",
                y.status_code == 422, f"-> {y.status_code}")

        y = istemci.delete(f"{ONEK}/meals/999999")
        kontrol("Olmayan kayit -> 404", y.status_code == 404, f"-> {y.status_code}")

        print("\n8) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.get(f"{ONEK}/meals/daily")
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()