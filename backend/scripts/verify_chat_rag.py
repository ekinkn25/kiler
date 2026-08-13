"""dogrulama: chatbot RAG ucu.

    python -m scripts.verify_chat_rag

MongoDB baglantisi ve seed edilmis tarifler GEREKTIRIR (fake LLM saglayici).
"""
import sys

from bson import ObjectId
from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import ChatConversation, ChatMessage, LlmCache, User
from app.services.chat import reset_chat_provider
from app.services.ingredient_matcher import clear_lookup_cache

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


def test_kullanicisi(db) -> User:
    k = db.query(User).filter(User.email == "chat_test@example.com").first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="chat_test@example.com", hashed_password=hash_password("T1234!"))
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
    db.query(LlmCache).delete()
    db.commit()


def main() -> None:
    settings.CHAT_PROVIDER = "fake"
    reset_chat_provider()
    clear_lookup_cache()

    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)
    app.dependency_overrides[get_current_active_user] = lambda: kullanici

    with TestClient(app) as istemci:
        print("\n1) Kabul kriterindeki ornek cumle")
        mesaj = "Hafif, mercimekli, 30 dakikada yapabilecegim bir sey"
        y = istemci.post(f"{ONEK}/chat", json={"message": mesaj})
        kontrol("HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:300]}")
        if y.status_code != 201:
            print("\nDevam edilemiyor. Tarifler seed edilmis mi? python -m scripts.seed_recipes")
            return

        v = y.json()
        kontrol("GECERLI JSON SOZLESMESI  <-- kabul kriteri",
                {"mesaj", "onerilen_tarif_idleri", "uygulanan_filtreler",
                 "conversation_id"} <= set(v))
        kontrol("mesaj bos degil", bool(v["mesaj"]), f"-> '{v['mesaj']}'")
        kontrol("uygulanan_filtreler doldu",
                len(v["uygulanan_filtreler"]) >= 1, f"-> {v['uygulanan_filtreler']}")

        print(f"\n  Yanit: {v['mesaj']}")
        print(f"  Filtreler: {v['uygulanan_filtreler']}")
        print(f"  Onerilen: {v['onerilen_tarif_idleri']}")

        print("\n2) UYDURMA TARIF YOK  <-- kabul kriteri (yapisal kontrol)")
        kontrol("Tum onerilen idler gecerli ObjectId bicimi",
                all(ObjectId.is_valid(t) for t in v["onerilen_tarif_idleri"]))
        print("  (Asil koruma parse_and_validate() icinde saglanir; "
              "bkz. tests/test_chat_rag.py::test_UYDURMA_ID_ELENIR)")

        print("\n3) Veritabani yan etkileri")
        db.expire_all()
        konusma = db.query(ChatConversation).filter_by(id=v["conversation_id"]).first()
        kontrol("Konusma olusturuldu", konusma is not None)
        mesajlar = db.query(ChatMessage).filter_by(conversation_id=konusma.id).all()
        kontrol("Kullanici + asistan mesaji kaydedildi", len(mesajlar) == 2,
                f"-> {len(mesajlar)} mesaj")
        asistan = next(m for m in mesajlar if m.role.value == "assistant")
        kontrol("suggested_recipe_ids kaydedildi", asistan.suggested_recipe_ids is not None)
        kontrol("Ilk cagri onbellekten DEGIL", asistan.from_cache is False)

        print("\n4) Onbellek - ayni soru tekrar")
        y2 = istemci.post(f"{ONEK}/chat", json={
            "message": mesaj, "conversation_id": v["conversation_id"],
        })
        v2 = y2.json()
        kontrol("Ikinci cagri ONBELLEKTEN", v2["from_cache"] is True)
        kontrol("Onbellekli yanit AYNI",
                v2["onerilen_tarif_idleri"] == v["onerilen_tarif_idleri"])

        print("\n5) Var olmayan konusma")
        y = istemci.post(f"{ONEK}/chat", json={"message": "selam", "conversation_id": 999999})
        kontrol("Olmayan konusma -> 404", y.status_code == 404, f"-> {y.status_code}")

        print("\n6) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.post(f"{ONEK}/chat", json={"message": "selam"})
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()