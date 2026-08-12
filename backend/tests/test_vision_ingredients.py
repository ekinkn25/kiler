"""W2-T04 birim testleri: ayristirma ve eslestirme mantigi."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import Ingredient, IngredientAlias, UnmatchedIngredient
from app.services.ingredient_matcher import (
    clear_lookup_cache, match_ingredients, match_one
)
from app.services.vision_ingredients import _guveni_normalize_et, _ham_listeyi_cikar


@pytest.fixture()
def db():
    """Her test icin bellekte tertemiz bir veritabani."""
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()

    domates = Ingredient(canonical_name="domates", display_name="Domates")
    mercimek = Ingredient(canonical_name="kirmizi_mercimek", display_name="Kırmızı Mercimek")
    yogurt = Ingredient(canonical_name="yogurt", display_name="Yoğurt")
    oturum.add_all([domates, mercimek, yogurt])
    oturum.flush()
    oturum.add_all([
        IngredientAlias(ingredient_id=mercimek.id, alias="k mercimek", source="test"),
        IngredientAlias(ingredient_id=yogurt.id, alias="suzme yogurt", source="test"),
    ])
    oturum.commit()

    clear_lookup_cache()
    yield oturum
    clear_lookup_cache()
    oturum.close()


# ---------------------------------------------------------------- ayristirma
@pytest.mark.parametrize("veri, beklenen_sayi", [
    ({"items": [{"name": "domates", "confidence": 0.9}]}, 1),
    ({"ingredients": [{"ad": "yumurta", "guven": 0.8}]}, 1),
    ({"malzemeler": ["sut", "peynir"]}, 2),
    ({"items": []}, 0),
    ({"beklenmedik_anahtar": [{"name": "un", "confidence": 1}]}, 1),
])
def test_farkli_anahtar_isimleri(veri, beklenen_sayi):
    assert len(_ham_listeyi_cikar(veri)) == beklenen_sayi


def test_tekrar_eden_ad_en_yuksek_guvenle_teklenir():
    veri = {"items": [
        {"name": "domates", "confidence": 0.4},
        {"name": "Domates", "confidence": 0.9},
    ]}
    sonuc = _ham_listeyi_cikar(veri)
    assert len(sonuc) == 1
    assert sonuc[0][1] == 0.9


@pytest.mark.parametrize("girdi, beklenen", [
    (0.85, 0.85), (95, 0.95), (1, 1.0), (-3, 0.0), ("abc", 0.5), (None, 0.5),
])
def test_guven_normalizasyonu(girdi, beklenen):
    assert _guveni_normalize_et(girdi) == beklenen


# ---------------------------------------------------------------- eslestirme
@pytest.mark.parametrize("ham, beklenen_canonical, beklenen_yontem", [
    ("domates", "domates", "canonical"),
    ("DOMATES", "domates", "canonical"),
    ("Kırmızı Mercimek", "kirmizi_mercimek", "canonical"),
    ("k mercimek", "kirmizi_mercimek", "alias"),          # alias
    ("domatesler", "domates", "canonical_ek"),
    ("taze domates", "domates", "fuzzy"),
    ("domats", "domates", "fuzzy"),                        # yazim hatasi
    ("yoğurt", "yogurt", "canonical"),                         # TR karakter
])
def test_eslesme_yontemleri(db, ham, beklenen_canonical, beklenen_yontem):
    sonuc = match_one(db, ham)
    assert sonuc.canonical_name == beklenen_canonical
    assert sonuc.matched_by == beklenen_yontem


def test_eslesmeyen_null_doner_ve_kaydedilir(db):
    sonuc = match_one(db, "zencefil kökü", source="vision")
    db.commit()

    assert sonuc.canonical_name is None
    assert sonuc.display_name == "Zencefil kökü"   # ham metin korunuyor
    kayit = db.query(UnmatchedIngredient).one()
    assert kayit.normalized_text == "zencefil koku"
    assert kayit.occurrence_count == 1
    assert kayit.source == "vision"


def test_ayni_eslesmeyen_iki_kez_eklenmez(db):
    match_one(db, "zencefil", source="vision")
    db.commit()
    match_one(db, "ZENCEFIL", source="vision")
    db.commit()

    kayit = db.query(UnmatchedIngredient).one()
    assert kayit.occurrence_count == 2


def test_bulanik_eslesmede_guven_dusurulur(db):
    kesin = match_one(db, "domates")
    bulanik = match_one(db, "domats")
    assert bulanik.confidence < kesin.confidence


def test_toplu_eslestirme(db):
    girdi = [("domates", 0.9), ("k mercimek", 0.7), ("uzayli meyvesi", 0.3)]
    sonuclar = match_ingredients(db, girdi, source="vision")

    assert len(sonuclar) == 3
    assert sum(1 for s in sonuclar if s.canonical_name) == 2
    assert sonuclar[2].canonical_name is None