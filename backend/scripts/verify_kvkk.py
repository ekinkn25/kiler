"""W4-T14 dogrulama: veri disa aktarma ve hesap silme (KVKK).

    python -m scripts.verify_kvkk

Ne yapar:
  1) Test kullanicisi acar ve user_id tasiyan HER tabloya en az bir satir yazar.
  2) GET /me/export cagirir; semadaki her kullanici tablosunun export'ta
     karsiligi var mi ve DOLU mu diye bakar.
  3) Yanlis parola ile silmeyi dener -> 401 beklenir.
  4) Dogru parola ile siler.
  5) SEMAYI TARAYARAK o user_id ile kayit kalmis mi diye her tabloyu kontrol
     eder; ayrica sahipsiz chat_messages kalmis mi diye bakar.

Betik kendi test kullanicisini kurar ve siler; baska veriye DOKUNMAZ.
"""
from __future__ import annotations

import sys
from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.config import settings
from app.core.deps import DbSession, get_current_active_user
from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import (
    Allergen, ChatConversation, ChatMessage, DietTag, Ingredient, MealLog,
    PantryEvent, PantryItem, RecipeFavorite, RecipeFeedback, ShoppingListItem,
    User, UserProfile, VisionRequest, VisionRequestType, WeightLog,
)
from app.models.enums import (
    ChatRole, FeedbackAction, Gender, LogSource, MealType, PantryEventType,
    PantrySource, ShoppingSource, TasteDimension, UnitType,
)
from app.models.recipe import SwipeSession, UserTasteWeight

ONEK = settings.API_V1_PREFIX
EPOSTA = "kvkk_test@example.com"
PAROLA = "KvkkTest1234!"

# Sahte MongoDB ObjectId'leri (24 karakter hex). Gercek tarif olmasi gerekmiyor:
# recipe_id SQLite tarafinda duz metindir, FK degildir.
TARIF_1 = "a" * 24
TARIF_2 = "b" * 24

# Tablo -> export'taki bolum adi.
# EKSIKSIZLIK KONTROLU BURADAN GECER: semada user_id tasiyan bir tablo bulunup
# bu haritada yoksa betik HATA verir. Yeni tablo ekleyip export'a yazmayi
# unutmak boylece sessizce gecmez.
TABLO_BOLUM = {
    "user_profiles": "profil",
    "user_diet_tags": "diyet_etiketleri",
    "user_allergens": "alerjenler",
    "pantry_items": "kiler",
    "pantry_events": "kiler_gecmisi",
    "shopping_list_items": "alisveris_listesi",
    "meal_logs": "ogun_kayitlari",
    "weight_logs": "kilo_kayitlari",
    "swipe_sessions": "swipe_oturumlari",
    "recipe_feedback": "tarif_geri_bildirimleri",
    "recipe_favorites": "tarif_favorileri",
    "user_taste_weights": "ogrenilen_zevk_agirliklari",
    "chat_conversations": "sohbetler",
    "vision_requests": "gorme_modeli_istekleri",
}

basarili = basarisiz = 0


def kontrol(ad: str, kosul: bool, ek: str = "") -> None:
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def user_id_tasiyan_tablolar(db) -> list[str]:
    """Semayi OKUYARAK bulur; elle liste tutmuyoruz.

    Yeni bir kullanici tablosu eklendiginde bu betik onu KENDILIGINDEN
    kontrol eder. 'Silmeyi unuttugumuz tablo' riski boylece kapanir.
    """
    tablolar = db.execute(text(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' AND name <> 'alembic_version'"
    )).scalars().all()
    return sorted(
        t for t in tablolar
        if any(r[1] == "user_id" for r in db.execute(text(f"PRAGMA table_info({t})")))
    )


def eski_kullaniciyi_sil(db) -> None:
    """Onceki kosudan kalan test kullanicisini temizler."""
    eski = db.scalar(select(User).where(User.email == EPOSTA))
    if eski is not None:
        db.delete(eski)
        db.commit()


def test_verisi_kur(db) -> User:
    """Her kullanici tablosuna en az bir satir yazar.

    NEDEN HEPSI: export 'tum tablolari iceriyor' kriteri ancak her tablo DOLU
    iken anlamli olcuebilir. Bos tablo, export'ta eksik bolumu gizler.
    """
    kullanici = User(
        email=EPOSTA,
        hashed_password=hash_password(PAROLA),
        full_name="KVKK Test",
        onboarding_completed=True,
    )
    db.add(kullanici)
    db.flush()
    uid = kullanici.id

    # --- profil, diyet, alerjen ---
    db.add(UserProfile(
        user_id=uid, birth_year=1998, gender=Gender.BELIRTILMEDI,
        height_cm=175, weight_kg=70, daily_calorie_target=2000,
    ))
    etiket = db.scalar(select(DietTag).limit(1))
    alerjen = db.scalar(select(Allergen).limit(1))
    if etiket is not None:
        kullanici.diet_tags.append(etiket)
    if alerjen is not None:
        kullanici.allergens.append(alerjen)

    # --- kiler, kiler gecmisi, alisveris ---
    malzemeler = list(db.scalars(select(Ingredient).order_by(Ingredient.id).limit(3)))
    if not malzemeler:
        sys.exit("Sozluk bos. Once: python -m scripts.seed_reference_data")

    kiler = PantryItem(user_id=uid, ingredient_id=malzemeler[0].id)
    kiler.confirm(PantrySource.MANUEL)
    db.add(kiler)
    db.flush()

    db.add(PantryEvent(
        user_id=uid, ingredient_id=malzemeler[0].id, pantry_item_id=kiler.id,
        event_type=PantryEventType.EKLENDI,
        quantity_base_delta=0.0, unit_type=UnitType.MASS,
        event_note="KVKK dogrulama kaydi.",
    ))
    db.add(ShoppingListItem(
        user_id=uid, ingredient_id=malzemeler[1].id, source=ShoppingSource.MANUEL,
    ))

    # --- ogun ve kilo ---
    db.add(MealLog(
        user_id=uid, logged_date=date.today(), meal_type=MealType.OGLE,
        source=LogSource.MANUEL, item_name="KVKK test ogunu",
        servings=1, quantity_g=200, calories=350,
    ))
    db.add(WeightLog(user_id=uid, logged_date=date.today(), weight_kg=70.5))

    # --- swipe, geri bildirim, favori, zevk ---
    oturum = SwipeSession(user_id=uid)
    db.add(oturum)
    db.flush()
    db.add(RecipeFeedback(
        user_id=uid, recipe_id=TARIF_1, session_id=oturum.id,
        action=FeedbackAction.GORDU,
    ))
    db.add(RecipeFavorite(user_id=uid, recipe_id=TARIF_2))
    db.add(UserTasteWeight(
        user_id=uid, dimension=TasteDimension.CUISINE, taste_key="turk", weight=0.5,
    ))

    # --- sohbet + mesaj (mesajda user_id YOK, sohbete bagli) ---
    sohbet = ChatConversation(user_id=uid, title="KVKK test sohbeti")
    db.add(sohbet)
    db.flush()
    db.add(ChatMessage(
        conversation_id=sohbet.id, role=ChatRole.USER,
        content="Bu bir dogrulama mesajidir.",
        image_url="c" * 64,   # gercekte SHA-256 ozeti; fotograf saklanmiyor
    ))

    # --- gorme modeli istegi ---
    db.add(VisionRequest(
        user_id=uid, request_type=VisionRequestType.MALZEME,
        image_hash="d" * 64, provider="fake", success=True,
    ))

    db.commit()
    db.refresh(kullanici)
    return kullanici

def _oturumdaki_kullanici(db: DbSession) -> User:
    """Kimlik dogrulamasini taklit eder.

    SABIT NESNE DONDURMUYORUZ: gercek get_current_active_user kullaniciyi
    ISTEGIN KENDI oturumundan yukler. Betigin oturumuna bagli bir nesne
    dondurursek DELETE ucundaki db.delete(user) su hatayi verir:
    'Object is already attached to session 1 (this is 5)'.
    """
    return db.scalar(select(User).where(User.email == EPOSTA))


def main() -> None:
    db = SessionLocal()
    eski_kullaniciyi_sil(db)
    kullanici = test_verisi_kur(db)
    uid = kullanici.id
    tablolar = user_id_tasiyan_tablolar(db)
    print(f"\nTest kullanicisi id={uid} | semada user_id tasiyan tablo: {len(tablolar)}")

    app.dependency_overrides[get_current_active_user] = _oturumdaki_kullanici

    db.close()

    with TestClient(app) as istemci:
        # ---------------------------------------------------------------
        print("\n1) Export ucu")
        y = istemci.get(f"{ONEK}/me/export")
        kontrol("HTTP 200", y.status_code == 200, f"-> {y.status_code} {y.text[:150]}")
        if y.status_code != 200:
            sys.exit(1)

        kontrol(
            "Content-Disposition ile dosya olarak iniyor",
            "attachment" in y.headers.get("content-disposition", ""),
        )
        veri = y.json()

        # ---------------------------------------------------------------
        print("\n2) Eksiksizlik  <-- KABUL KRITERI")
        haritada_yok = [t for t in tablolar if t not in TABLO_BOLUM]
        kontrol(
            "Semadaki her tablonun export'ta karsiligi tanimli",
            not haritada_yok,
            f"-> haritaya eklenmemis: {haritada_yok}" if haritada_yok else "",
        )
        for tablo in tablolar:
            bolum = TABLO_BOLUM.get(tablo)
            if bolum is None:
                continue
            icerik = veri.get(bolum)
            kontrol(f"{tablo:<22} -> '{bolum}' dolu", bool(icerik))

        # Sohbet mesajlari sohbetin ICINDE olmali, ayri liste degil.
        mesajli = any(s.get("mesajlar") for s in veri.get("sohbetler", []))
        kontrol("chat_messages sohbetin icine gomulu", mesajli)

        # ---------------------------------------------------------------
        print("\n3) Guvenlik")
        kontrol(
            "Parola ozeti export'ta YOK",
            "hashed_password" not in veri.get("hesap", {}),
        )
        kontrol("E-posta export'ta VAR", bool(veri.get("hesap", {}).get("email")))

        y = istemci.request(
            "DELETE", f"{ONEK}/me",
            json={"password": "yanlis-parola", "confirm": "HESABIMI SIL"},
        )
        kontrol("Yanlis parola ile silme reddedildi (401)",
                y.status_code == 401, f"-> {y.status_code}")

        y = istemci.request(
            "DELETE", f"{ONEK}/me",
            json={"password": PAROLA, "confirm": "yanlis metin"},
        )
        kontrol("Yanlis 'confirm' reddedildi (422)",
                y.status_code == 422, f"-> {y.status_code}")

        # ---------------------------------------------------------------
        print("\n4) Silme")
        y = istemci.request(
            "DELETE", f"{ONEK}/me",
            json={"password": PAROLA, "confirm": "HESABIMI SIL"},
        )
        kontrol("HTTP 200", y.status_code == 200, f"-> {y.status_code} {y.text[:150]}")
        if y.status_code == 200:
            print(f"  Silinen satirlar: {y.json().get('deleted_rows')}")
        # W4-T13 ara katmani: passive_deletes calisiyorsa bu sayi TEK HANELI olmali.
        sorgu = y.headers.get("x-query-count")
        kontrol("Silme sorgusu sayisi satir sayisindan bagimsiz (passive_deletes)",
                sorgu is not None and int(sorgu) < 30, f"-> {sorgu} sorgu")

    # ---------------------------------------------------------------
    # TAZE oturum: silen oturumun kimlik haritasi (identity map) sonucu
    # gizlemesin, veritabanina dogrudan soralim.
    db.close()
    db2 = SessionLocal()
    print("\n5) Silme sonrasi kalinti taramasi  <-- KABUL KRITERI")
    kalan = {}
    for t in tablolar:
        n = db2.execute(
            text(f"SELECT COUNT(*) FROM {t} WHERE user_id = :u"), {"u": uid}
        ).scalar()
        if n:
            kalan[t] = n
    kontrol(
        f"{len(tablolar)} tabloda kalinti YOK",
        not kalan, f"-> kalan: {kalan}" if kalan else "",
    )

    # chat_messages'ta user_id YOK; sohbet uzerinden baglanir.
    # Sohbetler silindiyse sahipsiz mesaj da kalmamali.
    yetim = db2.execute(text(
        "SELECT COUNT(*) FROM chat_messages WHERE conversation_id NOT IN "
        "(SELECT id FROM chat_conversations)"
    )).scalar()
    kontrol("Sahipsiz chat_messages yok", yetim == 0, f"-> {yetim} satir")

    kalan_kullanici = db2.scalar(select(User).where(User.id == uid))
    kontrol("users satiri silindi", kalan_kullanici is None)
    db2.close()

    print(f"\n{'=' * 60}")
    print(f"TAMAM: {basarili}   HATA: {basarisiz}")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    main()