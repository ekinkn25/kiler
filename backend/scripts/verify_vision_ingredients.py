"""W2-T04 dogrulama: fotograftan malzeme cikarma ucu.

Kullanim (backend/ klasorunde):
    python -m scripts.verify_vision_ingredients

Ag baglantisi GEREKTIRMEZ - VISION_PROVIDER gecici olarak 'fake' yapilir.
Gercek modeli denemek icin: python -m scripts.verify_vision_ingredients --gercek
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
from app.models import UnmatchedIngredient, User, VisionRequest
from app.services.ingredient_matcher import clear_lookup_cache
from app.services.vision import reset_vision_provider

GERCEK = "--gercek" in sys.argv
basarili = basarisiz = 0


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def test_fotografi() -> tuple[str, bytes, str]:
    """Varsa data/test_fotograf.jpg, yoksa uretilmis duz bir goruntu."""
    yol = Path(__file__).resolve().parents[2] / "data" / "test_fotograf.jpg"
    if yol.exists():
        print(f"  (gercek test fotografi kullaniliyor: {yol.name})")
        return yol.name, yol.read_bytes(), "image/jpeg"
    tampon = io.BytesIO()
    Image.new("RGB", (1200, 900), (200, 190, 170)).save(tampon, format="JPEG")
    return "sahte.jpg", tampon.getvalue(), "image/jpeg"


def test_kullanicisi(db) -> User:
    kullanici = db.query(User).first()
    if kullanici is None:
        from app.core.security import hash_password
        kullanici = User(email="vision_test@example.com",
                         hashed_password=hash_password("Test1234!"))
        db.add(kullanici)
        db.commit()
        db.refresh(kullanici)
    return kullanici


def main() -> None:
    if not GERCEK:
        settings.VISION_PROVIDER = "fake"
    reset_vision_provider()
    clear_lookup_cache()
    print(f"\nAktif saglayici: {settings.VISION_PROVIDER}")

    db = SessionLocal()
    kullanici = test_kullanicisi(db)

    # Kimlik dogrulamayi atliyoruz: bu betik ucun IS MANTIGINI dogruluyor,
    # W1-T08'de zaten test edilmis token akisini degil.
    app.dependency_overrides[get_current_active_user] = lambda: kullanici
    # TestClient'i 'with' OLMADAN kuruyoruz: lifespan calismaz, Mongo baglantisi
    # gerekmez. Bu uc Mongo kullanmiyor.
    istemci = TestClient(app)

    onceki_cagri = db.query(VisionRequest).count()
    onceki_eslesmeyen = db.query(UnmatchedIngredient).count()

    print("\n1) Mutlu yol - buzdolabi fotografi")
    ad, icerik, tip = test_fotografi()
    yanit = istemci.post(
        f"{settings.API_V1_PREFIX}/vision/ingredients",
        files={"file": (ad, icerik, tip)},
    )
    kontrol("HTTP 200", yanit.status_code == 200, f"-> {yanit.status_code} {yanit.text[:200]}")
    if yanit.status_code != 200:
        print("\nDevam edilemiyor.")
        return

    veri = yanit.json()
    kontrol("Yanit bir dizi", isinstance(veri, list))
    kontrol("EN AZ 5 MALZEME DONUYOR  <-- kabul kriteri",
            len(veri) >= 5, f"-> {len(veri)} malzeme")
    kontrol("Tum alanlar mevcut",
            all({"raw_name", "canonical_name", "display_name", "confidence"} <= set(m)
                for m in veri))
    kontrol("confidence 0-1 araliginda",
            all(0 <= m["confidence"] <= 1 for m in veri))
    kontrol("Guvene gore azalan siralanmis",
            all(veri[i]["confidence"] >= veri[i + 1]["confidence"]
                for i in range(len(veri) - 1)))

    eslesen = [m for m in veri if m["canonical_name"]]
    eslesmeyen = [m for m in veri if m["canonical_name"] is None]
    kontrol("EN AZ 1 MALZEME ESLESTI  <-- kabul kriteri",
            len(eslesen) >= 1, f"-> {len(eslesen)} eslesti")
    kontrol("Eslesenlerin canonical_name'i sozluk bicimi (kucuk harf, TR yok)",
            all(m["canonical_name"] == m["canonical_name"].lower()
                and m["canonical_name"].replace("_", "").isalnum() for m in eslesen))
    kontrol("Eslesmeyenlerin canonical_name'i null",
            all(m["canonical_name"] is None for m in eslesmeyen))
    kontrol("Eslesmeyenlerin de display_name'i dolu",
            all(m["display_name"] for m in eslesmeyen))

    print("\n  Donen liste:")
    print(f"  {'ham ad':<22} {'canonical':<22} {'gosterim':<22} guven")
    print(f"  {'-'*22} {'-'*22} {'-'*22} -----")
    for m in veri:
        print(f"  {m['raw_name'][:21]:<22} {str(m['canonical_name'])[:21]:<22} "
              f"{m['display_name'][:21]:<22} {m['confidence']}")

    print("\n2) Veritabani yan etkileri")
    db.expire_all()
    kontrol("vision_requests'e kayit atildi",
            db.query(VisionRequest).count() == onceki_cagri + 1)
    son = db.query(VisionRequest).order_by(VisionRequest.id.desc()).first()
    kontrol("request_type = malzeme", son.request_type.value == "malzeme")
    kontrol("matched_count dolduruldu", son.matched_count == len(eslesen),
            f"-> {son.matched_count}")
    kontrol("unmatched_count dolduruldu", son.unmatched_count == len(eslesmeyen),
            f"-> {son.unmatched_count}")
    kontrol("image_hash 64 karakter (foto SAKLANMIYOR)", len(son.image_hash) == 64)
    kontrol("success = True", son.success is True)
    if eslesmeyen:
        # Satir SAYISINA bakmiyoruz: betik ikinci kez calistiginda kayit
        # zaten vardir ve dogru davranis yeni satir acmak degil sayaci
        # artirmaktir. Kaydin VARLIGINI dogruluyoruz.
        from app.services.unit_service import normalize_text
        beklenen = {normalize_text(m["raw_name"]) for m in eslesmeyen}
        mevcut = {
            u.normalized_text for u in db.query(UnmatchedIngredient)
            .filter(UnmatchedIngredient.normalized_text.in_(beklenen)).all()
        }
        kontrol("Eslesmeyenler unmatched_ingredients'a yazildi",
                beklenen <= mevcut, f"-> {sorted(beklenen)}")

    print("\n3) Ayni fotograf tekrar - occurrence_count artiyor mu")
    onceki_sayac = {
        u.normalized_text: u.occurrence_count for u in db.query(UnmatchedIngredient).all()
    }
    istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients",
                 files={"file": (ad, icerik, tip)})
    db.expire_all()
    artan = any(
        u.occurrence_count > onceki_sayac.get(u.normalized_text, 0)
        for u in db.query(UnmatchedIngredient).all()
    )
    kontrol("Tekrar eden eslesmeyen 2 kez EKLENMEDI, sayaci artti",
            artan or not eslesmeyen)

    print("\n4) Hatali girdiler")
    y = istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients",
                     files={"file": ("belge.pdf", b"%PDF-1.4", "application/pdf")})
    kontrol("PDF -> 415", y.status_code == 415, f"-> {y.status_code}")

    y = istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients",
                     files={"file": ("bos.jpg", b"", "image/jpeg")})
    kontrol("Bos dosya -> 400", y.status_code == 400, f"-> {y.status_code}")

    y = istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients")
    kontrol("Dosyasiz istek -> 422", y.status_code == 422, f"-> {y.status_code}")

    y = istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients",
                     files={"file": ("bozuk.jpg", b"bu bir jpeg degil", "image/jpeg")})
    kontrol("Bozuk goruntu -> 4xx/5xx, sunucu COKMUYOR",
            y.status_code >= 400, f"-> {y.status_code}")

    print("\n5) Kimlik dogrulama")
    app.dependency_overrides.clear()
    y = istemci.post(f"{settings.API_V1_PREFIX}/vision/ingredients",
                     files={"file": (ad, icerik, tip)})
    kontrol("Token'siz istek -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 56}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()