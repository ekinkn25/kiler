"""W2-T10 dogrulama: chatbot foto destegi + kiler onay akisi.

    python -m scripts.verify_chat_pantry_flow

MongoDB baglantisi ve seed edilmis tarifler GEREKTIRIR (fake LLM+gorme).
"""
import sys
from datetime import timedelta
from pathlib import Path

from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import ChatConversation, ChatMessage, PantryEvent, PantryItem, User
from app.models.pantry import utcnow
from app.services.chat import reset_chat_provider
from app.services.ingredient_matcher import clear_lookup_cache
from app.services.vision import reset_vision_provider

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
    import io
    from PIL import Image
    tampon = io.BytesIO()
    Image.new("RGB", (1000, 750), (210, 180, 140)).save(tampon, format="JPEG")
    return "buzdolabi.jpg", tampon.getvalue(), "image/jpeg"


def test_kullanicisi(db) -> User:
    k = db.query(User).filter(User.email == "chat_pantry_test@example.com").first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="chat_pantry_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def temizle(db, user):
    konusma_id = db.query(ChatConversation.id).filter(ChatConversation.user_id == user.id)
    db.query(ChatMessage).filter(ChatMessage.conversation_id.in_(konusma_id)).delete(
        synchronize_session=False
    )
    db.query(ChatConversation).filter(ChatConversation.user_id == user.id).delete()
    db.query(PantryEvent).filter(PantryEvent.user_id == user.id).delete()
    db.query(PantryItem).filter(PantryItem.user_id == user.id).delete()
    db.commit()


def main() -> None:
    settings.CHAT_PROVIDER = "fake"
    settings.VISION_PROVIDER = "fake"
    reset_chat_provider()
    reset_vision_provider()
    clear_lookup_cache()

    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici

    with TestClient(app) as istemci:
        print("\n1) Fotografli sohbet mesaji  <-- kabul kriteri (malzeme listesi donuyor)")
        ad, icerik, tip = test_fotografi()
        y = istemci.post(
            f"{ONEK}/chat",
            data={"message": "Buzdolabimda ne var bi bakar misin?"},
            files={"file": (ad, icerik, tip)},
        )
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        if y.status_code != 201:
            print("\nDevam edilemiyor.")
            return

        v = y.json()
        kontrol("detected_ingredients doluyor  <-- kabul kriteri",
                len(v["detected_ingredients"]) >= 1, f"-> {len(v['detected_ingredients'])} malzeme")
        kontrol("Her malzemede canonical_name/confidence var",
                all({"raw_name", "canonical_name", "display_name", "confidence"} <= set(m)
                    for m in v["detected_ingredients"]))
        kontrol("mesaj/RAG cevabi da doluyor", bool(v["mesaj"]))

        print("\n  Tespit edilenler:")
        for m in v["detected_ingredients"]:
            print(f"    {m['raw_name']:<20} -> {m['canonical_name']} ({m['confidence']})")

        eslesenler = [m["canonical_name"] for m in v["detected_ingredients"] if m["canonical_name"]]
        kontrol("En az bir malzeme sozlukle eslesti", len(eslesenler) >= 1)

        print("\n2) Kilere HENUZ YAZILMADI  <-- gorev tanimindaki 'ONAY BEKLER'")
        db.expire_all()
        kontrol("pantry_items HALA BOS",
                db.query(PantryItem).filter(PantryItem.user_id == kullanici.id).count() == 0)

        print("\n3) chat_messages'a image_url ve detected_ingredients yazildi")
        konusma_id = v["conversation_id"]
        kullanici_mesaji = (
            db.query(ChatMessage)
            .filter(ChatMessage.conversation_id == konusma_id, ChatMessage.role == "user")
            .first()
        )
        kontrol("image_url (SHA-256 ozeti) kaydedildi",
                kullanici_mesaji.image_url is not None and len(kullanici_mesaji.image_url) == 64)
        kontrol("Foto SAKLANMIYOR - sadece ozet (64 hex karakter)",
                all(c in "0123456789abcdef" for c in kullanici_mesaji.image_url))
        kontrol("detected_ingredients JSON olarak kaydedildi",
                kullanici_mesaji.detected_ingredients is not None)

        print("\n4) Onay: secilen malzemeler kilere yaziliyor  <-- kabul kriteri")
        secilenler = eslesenler[:2] if len(eslesenler) >= 2 else eslesenler
        y = istemci.post(f"{ONEK}/pantry/confirm-detected", json={
            "canonical_name": secilenler, "source": "foto",
        })
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        onay = y.json()
        kontrol("confirmed listesi secilenlerle eslesiyor",
                len(onay["confirmed"]) == len(secilenler))

        print("\n5) pantry_items 'var' + 7 gunluk sure ile yazildi  <-- kabul kriteri")
        db.expire_all()
        kayitlar = db.query(PantryItem).filter(PantryItem.user_id == kullanici.id).all()
        kontrol("Dogru sayida kayit olustu", len(kayitlar) == len(secilenler))
        kontrol("Hepsi availability=VAR", all(k.availability.value == "var" for k in kayitlar))
        kontrol("Hepsi source=FOTO", all(k.source.value == "foto" for k in kayitlar))

        for k in kayitlar:
            kalan = (k.confidence_expires_at - utcnow()).days
            kontrol(f"'{k.ingredient.canonical_name}' ~7 gun guven suresi",
                    5 <= kalan <= 7, f"-> {kalan} gun")

        print("\n6) PantryEvent gunlugu de yazildi")
        olaylar = db.query(PantryEvent).filter(PantryEvent.user_id == kullanici.id).all()
        kontrol("Her onay icin bir olay kaydedildi", len(olaylar) == len(secilenler))
        kontrol("Olay tipi EKLENDI", all(o.event_type.value == "eklendi" for o in olaylar))

        print("\n7) Bilinmeyen canonical_name atlaniyor, coker degil")
        y = istemci.post(f"{ONEK}/pantry/confirm-detected", json={
            "canonical_name": ["boyle_bir_malzeme_yok_xyz"], "source": "foto",
        })
        kontrol("HTTP 201 (kismi basari, cokme yok)", y.status_code == 201, f"-> {y.status_code}")
        kontrol("skipped_unknown'da raporlaniyor",
                "boyle_bir_malzeme_yok_xyz" in y.json()["skipped_unknown"])

        print("\n8) Fotosuz sohbet mesaji hala calisiyor (geriye uyumluluk)")
        y = istemci.post(f"{ONEK}/chat", data={"message": "Hafif bir sey onerir misin"})
        kontrol("HTTP 201 (multipart ZORUNLU degil)", y.status_code == 201, f"-> {y.status_code}")
        kontrol("detected_ingredients bos liste", y.json()["detected_ingredients"] == [])

        print("\n9) Hatali girdiler")
        y = istemci.post(f"{ONEK}/chat", data={"message": "selam"},
                         files={"file": ("x.pdf", b"%PDF-1.4", "application/pdf")})
        kontrol("PDF -> 415", y.status_code == 415, f"-> {y.status_code}")

        y = istemci.post(f"{ONEK}/pantry/confirm-detected", json={"canonical_name": []})
        kontrol("Bos liste -> 422", y.status_code == 422, f"-> {y.status_code}")

        print("\n10) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.post(f"{ONEK}/pantry/confirm-detected",
                         json={"canonical_name": ["domates"]})
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()