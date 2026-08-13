"""W2-T12 dogrulama: barkod -> urun -> kiler ucu.

    python -m scripts.verify_barcode_scan

GERCEK Open Food Facts API'sine baglanir (internet GEREKTIRIR).
"""
import sys

from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import Ingredient, PantryEvent, PantryItem, Product, User
from app.models.pantry import utcnow

ONEK = settings.API_V1_PREFIX
# Nutella - Open Food Facts'te kesin kayitli, yaygin bilinen gercek urun.
GERCEK_BARKOD = "3017620422003"
SACMA_BARKOD = "00000000000000"
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
    k = db.query(User).filter(User.email == "barcode_test@example.com").first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="barcode_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def temizle(db, user):
    db.query(PantryEvent).filter(PantryEvent.user_id == user.id).delete()
    db.query(PantryItem).filter(PantryItem.user_id == user.id).delete()
    db.query(Product).filter(Product.barcode.in_([GERCEK_BARKOD, SACMA_BARKOD])).delete(
        synchronize_session=False
    )
    db.commit()


def main() -> None:
    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici

    with TestClient(app) as istemci:
        print(f"\n1) Gercek barkod tara: {GERCEK_BARKOD}  <-- kabul kriteri")
        y = istemci.post(f"{ONEK}/pantry/scan", json={"barcode": GERCEK_BARKOD})
        kontrol("HTTP 200", y.status_code == 200, f"-> {y.status_code} {y.text[:300]}")
        if y.status_code != 200:
            print("\nDevam edilemiyor. Internet baglantisini kontrol et.")
            return

        v = y.json()
        kontrol("URUN BULUNDU  <-- kabul kriteri", v["found"] is True)
        kontrol("URUN ADI DONUYOR  <-- kabul kriteri",
                bool(v["product"]["name"]), f"-> '{v['product']['name']}'")
        kontrol("KALORI DONUYOR  <-- kabul kriteri",
                v["product"]["calories_per_100g"] is not None,
                f"-> {v['product']['calories_per_100g']} kcal/100g")
        kontrol("Ilk cagri onbellekten DEGIL", v["from_cache"] is False)

        print(f"\n  Urun: {v['product']['name']} ({v['product']['brand']})")
        print(f"  {v['product']['calories_per_100g']} kcal/100g")
        print(f"  Eslesen malzeme: {v['matched_ingredient']}")

        print("\n2) Ayni barkod tekrar - ONBELLEKTEN gelmeli")
        y2 = istemci.post(f"{ONEK}/pantry/scan", json={"barcode": GERCEK_BARKOD})
        kontrol("Ikinci cagri ONBELLEKTEN", y2.json()["from_cache"] is True)

        print("\n3) Onay: urun kilere yaziliyor  <-- kabul kriteri")
        product_id = v["product"]["id"]
        eslesen_id = v["matched_ingredient"]["id"] if v["matched_ingredient"] else None
        kullanilan_ingredient_id = eslesen_id

        istek = {"product_id": product_id}
        if eslesen_id is None:
            # OFF'tan gelen urun adi sozlukte otomatik eslesmediyse
            # (cok olasi - marka adlari serbest metin) elle bir malzeme ver.
            ornek = db.query(Ingredient).filter_by(canonical_name="findik_ezmesi").first() \
                or db.query(Ingredient).first()
            istek["ingredient_id"] = ornek.id
            kullanilan_ingredient_id = ornek.id
            print(f"  (otomatik eslesme yok, elle '{ornek.canonical_name}' veriliyor)")

        y = istemci.post(f"{ONEK}/pantry/confirm-scanned", json=istek)
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")

        print("\n4) pantry_items 'var' + source='barkod' + 7 gun  <-- kabul kriteri")
        db.expire_all()
        kayit = db.query(PantryItem).filter_by(
            user_id=kullanici.id, ingredient_id=kullanilan_ingredient_id
        ).first()
        kontrol("Kayit olustu", kayit is not None)
        kontrol("availability = VAR", kayit.availability.value == "var")
        kontrol("source = BARKOD", kayit.source.value == "barkod")
        kalan = (kayit.confidence_expires_at - utcnow()).days
        kontrol("~7 gun guven suresi", 5 <= kalan <= 7, f"-> {kalan} gun")

        print("\n5) Bulunamayan barkod -> manuel giris fallback")
        y = istemci.post(f"{ONEK}/pantry/scan", json={"barcode": SACMA_BARKOD})
        kontrol("HTTP 200", y.status_code == 200)
        kontrol("found = False", y.json()["found"] is False)
        kontrol("Yol gosterici mesaj var", bool(y.json()["message"]))

        y = istemci.post(f"{ONEK}/pantry/products", json={
            "barcode": SACMA_BARKOD, "name": "Elle Eklenen Test Urunu",
            "calories_per_100g": 250,
        })
        kontrol("Manuel urun eklendi", y.status_code == 201, f"-> {y.status_code}")
        kontrol("source = user", y.json()["source"] == "user")

        manuel_urun_id = y.json()["id"]
        y = istemci.post(f"{ONEK}/pantry/confirm-scanned", json={
            "product_id": manuel_urun_id, "ingredient_id": kullanilan_ingredient_id,
        })
        kontrol("Manuel urun de onaylanabiliyor", y.status_code == 201, f"-> {y.status_code}")

        print("\n6) Hatali girdiler")
        y = istemci.post(f"{ONEK}/pantry/confirm-scanned", json={"product_id": 999999})
        kontrol("Olmayan urun -> 404", y.status_code == 404, f"-> {y.status_code}")

        print("\n7) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.post(f"{ONEK}/pantry/scan", json={"barcode": GERCEK_BARKOD})
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()