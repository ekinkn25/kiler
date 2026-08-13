"""W2-T08 dogrulama: fotograftan ogun ve kalori tahmini.

    python -m scripts.verify_meal_estimation
    python -m scripts.verify_meal_estimation --gercek

Ag baglantisi GEREKTIRMEZ (sahte saglayici). Kalori cozumlemesi icin
MongoDB ve seed edilmis tarifler gerekir.
"""
import io
import sys
from pathlib import Path

from fastapi.testclient import TestClient
from PIL import Image

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import User, VisionRequest
from app.services.meal_estimation import clear_title_cache
from app.services.vision import reset_vision_provider

GERCEK = "--gercek" in sys.argv
ONEK = settings.API_V1_PREFIX
basarili = basarisiz = 0


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def test_fotografi():
    yol = Path(__file__).resolve().parents[2] / "data" / "test_fotograf.jpg"
    if yol.exists():
        return yol.name, yol.read_bytes(), "image/jpeg"
    tampon = io.BytesIO()
    Image.new("RGB", (1000, 750), (210, 180, 140)).save(tampon, format="JPEG")
    return "tabak.jpg", tampon.getvalue(), "image/jpeg"


def test_kullanicisi(db) -> User:
    k = db.query(User).first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="ogun_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def main() -> None:
    if not GERCEK:
        settings.VISION_PROVIDER = "fake"
    reset_vision_provider()
    clear_title_cache()
    print(f"\nAktif saglayici: {settings.VISION_PROVIDER}")

    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici
    onceki = db.query(VisionRequest).count()

    # Mongo baglantisi gerektigi icin 'with' sart (lifespan calissin).
    with TestClient(app) as istemci:
        print("\n1) Mutlu yol - tabak fotografi")
        ad, icerik, tip = test_fotografi()
        y = istemci.post(f"{ONEK}/vision/meal", files={"file": (ad, icerik, tip)})
        kontrol("HTTP 200", y.status_code == 200,
                f"-> {y.status_code} {y.text[:200]}")
        if y.status_code != 200:
            print("\nDevam edilemiyor.")
            return

        v = y.json()
        kontrol("YEMEK ADI DONUYOR  <-- kabul kriteri",
                bool(v["dish_name"]), f"-> '{v['dish_name']}'")
        kontrol("PORSIYON DONUYOR  <-- kabul kriteri",
                v["portion"] in ("kucuk", "orta", "buyuk"), f"-> {v['portion']}")
        kontrol("Gram tahmini makul",
                10 <= v["estimated_grams"] <= 3000, f"-> {v['estimated_grams']} g")
        kontrol("GUVEN SKORU YANITTA  <-- kabul kriteri",
                0 <= v["confidence"] <= 1, f"-> {v['confidence']}")
        kontrol("Olcek referansi bayragi var", "scale_reference_found" in v,
                f"-> {v['scale_reference_found']}")

        print("\n2) Kalori cozumleme")
        if v["calories"] is None:
            print(f"  (kalori kaynagi bulunamadi: '{v['dish_name']}')")
            kontrol("Elle giris bayragi ayarlanmis", v["needs_manual_entry"] is True)
            kontrol("Kaynak 'none'", v["match_source"] == "none")
        else:
            kontrol("KALORI TAHMINI DONUYOR  <-- kabul kriteri",
                    v["calories"] > 0, f"-> {v['calories']} kcal")
            kontrol("Kaynak belirtilmis",
                    v["match_source"] in ("recipe", "ingredient", "product"),
                    f"-> {v['match_source']} ({v['matched_name']})")
            kontrol("Kalori guveni ayri raporlaniyor",
                    0 < v["calorie_confidence"] <= 1, f"-> {v['calorie_confidence']}")
            kontrol("Makrolar donuyor", v["macros"] is not None)
            kontrol("Kalori makul araliktan",
                    50 <= v["calories"] <= 2500, f"-> {v['calories']} kcal")
            yogunluk = v["calories"] / v["estimated_grams"] * 100
            kontrol("100 g basina enerji makul (30-600 kcal)",
                    30 <= yogunluk <= 600, f"-> {yogunluk:.0f} kcal/100g")

        print("\n3) ONAY ZORUNLULUGU  <-- gorev tanimindaki 'ONEMLI'")
        kontrol("is_estimate = true", v["is_estimate"] is True)
        kontrol("requires_confirmation = true", v["requires_confirmation"] is True)
        kontrol("Ogun gunluge YAZILMADI",
                db.query(__import__("app.models", fromlist=["MealLog"]).MealLog)
                  .filter_by(user_id=kullanici.id).count() == 0)

        print("\n4) Porsiyon secenekleri")
        secenekler = v["portion_options"]
        kontrol("Uc secenek donuyor", len(secenekler) == 3)
        gramlar = [s["grams"] for s in secenekler]
        kontrol("Gramlar artan sirali", gramlar == sorted(gramlar), f"-> {gramlar}")
        if v["calories"]:
            kaloriler = [s["calories"] for s in secenekler]
            kontrol("Kaloriler gramla orantili artiyor",
                    kaloriler == sorted(kaloriler), f"-> {kaloriler}")

        print("\n5) Kayit ve gizlilik")
        db.expire_all()
        kontrol("vision_requests'e kayit atildi",
                db.query(VisionRequest).count() == onceki + 1)
        son = db.query(VisionRequest).order_by(VisionRequest.id.desc()).first()
        kontrol("request_type = ogun", son.request_type.value == "ogun",
                f"-> {son.request_type.value}")
        kontrol("Foto SAKLANMIYOR, yalnizca ozet", len(son.image_hash) == 64)
        kontrol("Ozet yanitta da var", v["image_hash"] == son.image_hash)

        print("\n6) Hatali girdiler")
        y = istemci.post(f"{ONEK}/vision/meal",
                         files={"file": ("x.pdf", b"%PDF-1.4", "application/pdf")})
        kontrol("PDF -> 415", y.status_code == 415, f"-> {y.status_code}")
        y = istemci.post(f"{ONEK}/vision/meal",
                         files={"file": ("bos.jpg", b"", "image/jpeg")})
        kontrol("Bos dosya -> 400", y.status_code == 400, f"-> {y.status_code}")
        y = istemci.post(f"{ONEK}/vision/meal")
        kontrol("Dosyasiz -> 422", y.status_code == 422, f"-> {y.status_code}")

        print("\n7) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.post(f"{ONEK}/vision/meal", files={"file": (ad, icerik, tip)})
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

        print(f"\n  Ozet: {v['dish_name']} | {v['portion']} | "
              f"{v['estimated_grams']} g | {v['calories']} kcal")
        print(f"  Kaynak: {v['match_source']} -> {v['matched_name']} "
              f"(skor {v['match_score']})")
        print(f"  Guven: model={v['confidence']} kalori={v['calorie_confidence']}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()