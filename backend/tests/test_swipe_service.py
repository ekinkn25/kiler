"""W2-T07 birim testleri: oturum filtreleme ve eleme kurallari.

MongoDB GEREKTIRMEZ. Eleme kumesi ve oturum filtreleri tamamen
SQLite tarafinda uretildigi icin burada dogrulanabiliyor.
"""
from datetime import timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.exceptions import PermissionDeniedError
from app.db.base import Base
from app.models import User
from app.models.enums import FeedbackAction, FeedbackReason
from app.models.recipe import RecipeFeedback, SwipeSession, utcnow
from app.services.recipe_scoring import ScoringContext, build_scoring_pipeline
from app.services.swipe_service import (
    COK_UZUN_ESIK_DK, COK_UZUN_TABAN_DK, build_exclusions, cok_uzun_esigi,
    get_or_create_session, mark_shown,
)

# Gecerli ObjectId bicimi: 24 hex karakter
T1 = "a" * 24
T2 = "b" * 24
T3 = "c" * 24
T4 = "d" * 24


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="swipe@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def session(db, user):
    o = SwipeSession(user_id=user.id)
    db.add(o)
    db.commit()
    db.refresh(o)
    return o


def geri_bildirim(db, user, recipe_id, action, reason=None, session_id=None, gun_once=0):
    kayit = RecipeFeedback(
        user_id=user.id, recipe_id=recipe_id, session_id=session_id,
        action=action, reason=reason,
    )
    db.add(kayit)
    db.commit()
    if gun_once:
        kayit.created_at = utcnow() - timedelta(days=gun_once)
        db.commit()
    return kayit


# ---------------------------------------------------------------- oturum
def test_session_id_yoksa_yeni_oturum_acilir(db, user):
    o = get_or_create_session(db, user, None)
    assert o.id is not None and o.user_id == user.id and o.shown_count == 0


def test_baskasinin_oturumu_reddedilir(db, user, session):
    baskasi = User(email="baska@example.com", hashed_password="x")
    db.add(baskasi)
    db.commit()
    with pytest.raises(PermissionDeniedError):
        get_or_create_session(db, baskasi, session.id)


# ---------------------------------------------------------------- (a)
def test_gorulen_tarifler_ayni_oturumda_elenir(db, user, session):
    mark_shown(db, user, session, [{"id": T1}, {"id": T2}])
    elenen = build_exclusions(db, user, session)
    assert set(elenen) == {T1, T2}
    assert session.shown_count == 2


def test_baska_oturumda_gorulen_elenmez(db, user, session):
    mark_shown(db, user, session, [{"id": T1}])
    yeni = get_or_create_session(db, user, None)
    assert T1 not in build_exclusions(db, user, yeni)


# ---------------------------------------------------------------- (b)
def test_sevmedim_kalici_elenir(db, user, session):
    geri_bildirim(db, user, T1, FeedbackAction.BEGENMEDIM,
                  FeedbackReason.SEVMEDIM, gun_once=400)
    yeni = get_or_create_session(db, user, None)
    assert T1 in build_exclusions(db, user, yeni), "400 gun sonra bile elenmeli"


def test_sadece_begenmedim_kalici_elemez(db, user, session):
    """reason yoksa kalici eleme YOK - bilincli ayrim."""
    geri_bildirim(db, user, T1, FeedbackAction.BEGENMEDIM)
    yeni = get_or_create_session(db, user, None)
    assert T1 not in build_exclusions(db, user, yeni)


# ---------------------------------------------------------------- (d)
def test_malzeme_yok_yedi_gun_elenir(db, user, session):
    geri_bildirim(db, user, T1, FeedbackAction.BEGENMEDIM,
                  FeedbackReason.MALZEME_YOK, gun_once=3)
    yeni = get_or_create_session(db, user, None)
    assert T1 in build_exclusions(db, user, yeni)


def test_malzeme_yok_sekiz_gun_sonra_geri_gelir(db, user, session):
    geri_bildirim(db, user, T2, FeedbackAction.BEGENMEDIM,
                  FeedbackReason.MALZEME_YOK, gun_once=8)
    yeni = get_or_create_session(db, user, None)
    assert T2 not in build_exclusions(db, user, yeni)


def test_baska_kullanicinin_gecmisi_sizmaz(db, user, session):
    baskasi = User(email="baska2@example.com", hashed_password="x")
    db.add(baskasi)
    db.commit()
    geri_bildirim(db, baskasi, T3, FeedbackAction.BEGENMEDIM, FeedbackReason.SEVMEDIM)
    assert T3 not in build_exclusions(db, user, session)


# ---------------------------------------------------------------- (c)
def test_cok_uzun_esigi_otuza_dusurur(session):
    assert session.filters.get("max_total_time") is None
    session.tighten_time_limit(COK_UZUN_ESIK_DK)
    assert session.filters["max_total_time"] == 30


def test_esik_yalnizca_DARALIR(session):
    session.tighten_time_limit(30)
    session.tighten_time_limit(45)   # gevsetmeye calis
    assert session.filters["max_total_time"] == 30


def test_esik_daha_da_daralabilir(session):
    session.tighten_time_limit(30)
    session.tighten_time_limit(15)
    assert session.filters["max_total_time"] == 15

def test_cok_uzun_esigi_karttan_kisa_olur():
    # 25 dk'lik karta 'cok uzun' -> %20 kisalir
    assert cok_uzun_esigi(25) == 20


def test_cok_uzun_esigi_uzun_kartta_KADEMELI_daralir():
    # 110 dk'lik kart 30'a CAKMAZ; kullanicinin sikayeti olmayan
    # 45 dk'lik tarifler hayatta kalir.
    assert cok_uzun_esigi(110) == 88
    assert cok_uzun_esigi(88) == 70


def test_cok_uzun_esigi_bir_noktada_yakinsar():
    esik = 110
    for _ in range(20):
        esik = cok_uzun_esigi(esik)
    assert esik == COK_UZUN_TABAN_DK

def test_cok_uzun_esigi_tabanin_altina_inmez():
    # 12 dk'lik karta 'cok uzun' denirse deste kurumasin
    assert cok_uzun_esigi(12) == COK_UZUN_TABAN_DK


def test_cok_uzun_suresi_bilinmeyen_kartta_sabit_kurala_duser():
    assert cok_uzun_esigi(0) == COK_UZUN_ESIK_DK


def test_filtre_kalici_json_olarak_saklanir(db, session):
    session.tighten_time_limit(30)
    db.commit()
    db.expire_all()
    assert db.get(SwipeSession, session.id).filters == {"max_total_time": 30}


# ---------------------------------------------------------------- pipeline
def test_sure_tavani_pipeline_e_expr_olarak_giriyor():
    ctx = ScoringContext(max_total_minutes=30)
    match = build_scoring_pipeline(ctx)[0]["$match"]
    assert match["$expr"] == {"$lte": [
        {"$add": [{"$ifNull": ["$prep_time", 0]}, {"$ifNull": ["$cook_time", 0]}]},
        30.0,
    ]}


def test_sure_tavani_yoksa_expr_eklenmez():
    assert "$expr" not in build_scoring_pipeline(ScoringContext())[0]["$match"]


def test_elenen_tarifler_nin_olarak_giriyor():
    ctx = ScoringContext()
    match = build_scoring_pipeline(ctx, exclude_ids=[T1, T2])[0]["$match"]
    assert len(match["_id"]["$nin"]) == 2


# ---------------------------------------------------------------- istek semasi
def test_swipe_semasi_kurallari():
    from pydantic import ValidationError
    from app.schemas import SwipeRequest

    # reason yalnizca begenmedim ile
    with pytest.raises(ValidationError):
        SwipeRequest(action=FeedbackAction.BEGENDIM, reason=FeedbackReason.SEVMEDIM)

    # missing_ingredient_id yalnizca malzeme_yok ile
    with pytest.raises(ValidationError):
        SwipeRequest(action=FeedbackAction.BEGENMEDIM,
                     reason=FeedbackReason.SEVMEDIM, missing_ingredient_id=1)

    # gecerli kombinasyonlar
    assert SwipeRequest(action=FeedbackAction.BEGENDIM).reason is None
    assert SwipeRequest(action=FeedbackAction.BEGENMEDIM,
                        reason=FeedbackReason.COK_UZUN).reason


# ---------------------------------------------------------------- malzeme elemesi
def test_olmayan_malzeme_pipeline_dan_eleniyor():
    ctx = ScoringContext(excluded_ingredients=("limon",))
    match = build_scoring_pipeline(ctx)[0]["$match"]
    assert match["$nor"] == [{
        "ingredients": {
            "$elemMatch": {
                "canonical_name": {"$in": ["limon"]},
                "optional": {"$ne": True},
            }
        }
    }]


def test_olmayan_malzeme_yoksa_nor_eklenmez():
    assert "$nor" not in build_scoring_pipeline(ScoringContext())[0]["$match"]


def test_malzemem_yok_oturuma_ve_kilere_yaziliyor(db, user, session):
    from sqlalchemy import select

    from app.models import Ingredient, PantryItem
    from app.models.enums import Availability
    from app.services.swipe_service import _malzemeyi_yok_isaretle

    limon = Ingredient(canonical_name="limon", display_name="Limon")
    db.add(limon)
    db.commit()
    db.add(PantryItem(
        user_id=user.id, ingredient_id=limon.id, availability=Availability.VAR,
    ))
    db.commit()

    ad = _malzemeyi_yok_isaretle(db, user, limon.id, session)
    db.commit()

    assert ad == "Limon"
    # (1) oturum filtresine yazildi
    assert session.filters["missing_ingredients"] == ["limon"]
    # (2) kilerdeki YANLIS 'var' inanci duzeltildi
    kayit = db.scalar(select(PantryItem).where(PantryItem.ingredient_id == limon.id))
    assert kayit.availability is Availability.BITTI


def test_ayni_malzeme_ikinci_kez_eklenmiyor(db, user, session):
    from app.models import Ingredient
    from app.services.swipe_service import _malzemeyi_yok_isaretle

    limon = Ingredient(canonical_name="limon", display_name="Limon")
    db.add(limon)
    db.commit()

    _malzemeyi_yok_isaretle(db, user, limon.id, session)
    _malzemeyi_yok_isaretle(db, user, limon.id, session)
    assert session.filters["missing_ingredients"] == ["limon"]


def test_bilinmeyen_malzeme_kimligi_cokmeye_sebep_olmuyor(db, user, session):
    from app.services.swipe_service import _malzemeyi_yok_isaretle

    assert _malzemeyi_yok_isaretle(db, user, 999999, session) is None
    assert "missing_ingredients" not in session.filters