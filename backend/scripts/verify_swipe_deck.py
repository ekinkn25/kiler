"""W2-T07 dogrulama: swipe destesi ve oturum filtreleme.

    python -m scripts.verify_swipe_deck

MongoDB baglantisi ve seed edilmis tarifler GEREKTIRIR.
"""
import sys

from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.deps import get_current_active_user
from app.db.session import SessionLocal
from app.main import app
from app.models import User
from app.models.recipe import RecipeFeedback, SwipeSession

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
    k = db.query(User).filter(User.email == "swipe_test@example.com").first()
    if k is None:
        from app.core.security import hash_password
        k = User(email="swipe_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    return k


def temizle(db, user):
    db.query(RecipeFeedback).filter(RecipeFeedback.user_id == user.id).delete()
    db.query(SwipeSession).filter(SwipeSession.user_id == user.id).delete()
    db.commit()


def main() -> None:
    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    temizle(db, kullanici)

    app.dependency_overrides[get_current_active_user] = lambda: kullanici
    # 'with' KULLANIYORUZ: bu uc Mongo'ya baglanmak zorunda, lifespan sart.
    with TestClient(app) as istemci:
        print("\n1) Ilk deste")
        y = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 10})
        kontrol("HTTP 200", y.status_code == 200, f"-> {y.status_code} {y.text[:200]}")
        if y.status_code != 200:
            print("Devam edilemiyor. Tarifler seed edilmis mi? "
                  "python -m scripts.seed_recipes")
            return

        d1 = y.json()
        oturum = d1["session_id"]
        kontrol("Oturum kimligi donuyor", isinstance(oturum, int))
        kontrol("10 KART DONUYOR  <-- kabul kriteri",
                d1["returned"] == 10, f"-> {d1['returned']} kart")
        kontrol("Kartlar skora gore azalan sirali",
                all(d1["items"][i]["final_score"] >= d1["items"][i + 1]["final_score"]
                    for i in range(len(d1["items"]) - 1)))
        kontrol("Skor kirilimi kartlarda var",
                all("score_breakdown" in k for k in d1["items"]))

        ilk = [k["id"] for k in d1["items"]]
        print(f"\n  Ilk deste: {[k['title'][:18] for k in d1['items'][:5]]} ...")

        print("\n2) Ayni oturumda ikinci istek  <-- kabul kriteri")
        d2 = istemci.get(f"{ONEK}/recipes/deck",
                         params={"session_id": oturum, "limit": 10}).json()
        ikinci = [k["id"] for k in d2["items"]]
        kontrol("TEKRAR EDEN TARIF YOK  <-- kabul kriteri",
                not (set(ilk) & set(ikinci)),
                f"-> {len(set(ilk) & set(ikinci))} tekrar")
        kontrol("Oturum ayni kaldi", d2["session_id"] == oturum)
        kontrol("Eleme sayaci artti", d2["excluded_count"] >= 10)

        print("\n3) 'sevmedim' kalici eleme  <-- kabul kriteri")
        hedef = ikinci[0]
        y = istemci.post(f"{ONEK}/recipes/{hedef}/swipe", json={
            "action": "begenmedim", "reason": "sevmedim", "session_id": oturum,
        })
        kontrol("Swipe HTTP 201", y.status_code == 201, f"-> {y.status_code} {y.text[:200]}")
        kontrol("Etki aciklamasi donuyor", "effect" in y.json())

        # YENI oturum: 'gorulen' elemesi devre disi, sadece kalici eleme kalir
        temiz = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 30}).json()
        kontrol("SEVMEDIM DENEN TARIF BIR DAHA DONMUYOR  <-- kabul kriteri",
                hedef not in [k["id"] for k in temiz["items"]])

        print("\n4) 'cok_uzun' oturum esigini daraltiyor")
        oturum2 = temiz["session_id"]
        hedef2 = temiz["items"][0]["id"]
        y = istemci.post(f"{ONEK}/recipes/{hedef2}/swipe", json={
            "action": "begenmedim", "reason": "cok_uzun", "session_id": oturum2,
        }).json()
        kontrol("Oturum filtresi 30 dk oldu",
                y["session_filters"].get("max_total_time") == 30,
                f"-> {y['session_filters']}")

        d3 = istemci.get(f"{ONEK}/recipes/deck",
                         params={"session_id": oturum2, "limit": 10}).json()
        kontrol("Filtre yanitta yansiyor",
                d3["session_filters"].get("max_total_time") == 30)
        if d3["items"]:
            sureler = [(k.get("prep_time") or 0) + (k.get("cook_time") or 0)
                       for k in d3["items"]]
            kontrol("TUM KARTLAR 30 DK VE ALTI",
                    all(s <= 30 for s in sureler), f"-> en uzun {max(sureler)} dk")
        else:
            print("  (30 dk altinda tarif kalmadi - exhausted=True bekleniyor)")
            kontrol("Deste tukendi bayragi", d3["exhausted"] is True)

        print("\n5) Hatali istekler")
        y = istemci.post(f"{ONEK}/recipes/{hedef}/swipe",
                         json={"action": "begendim", "reason": "sevmedim"})
        kontrol("reason yalnizca begenmedim ile -> 422", y.status_code == 422,
                f"-> {y.status_code}")

        y = istemci.post(f"{ONEK}/recipes/gecersizkimlik/swipe",
                         json={"action": "begendim"})
        kontrol("Gecersiz tarif kimligi -> 404", y.status_code == 404, f"-> {y.status_code}")

        y = istemci.get(f"{ONEK}/recipes/deck", params={"session_id": 999999})
        kontrol("Olmayan oturum -> 404", y.status_code == 404, f"-> {y.status_code}")

        y = istemci.get(f"{ONEK}/recipes/deck", params={"limit": 999})
        kontrol("limit tavani -> 422", y.status_code == 422, f"-> {y.status_code}")

        print("\n6) Kimlik dogrulama")
        app.dependency_overrides.clear()
        y = istemci.get(f"{ONEK}/recipes/deck")
        kontrol("Token'siz -> 401", y.status_code == 401, f"-> {y.status_code}")

    db.close()
    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()