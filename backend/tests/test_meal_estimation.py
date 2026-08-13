"""W2-T08 birim testleri: ogun yaniti ayristirma ve porsiyon mantigi.

Ag ve veritabani GEREKTIRMEZ.
"""
import pytest

from app.core.config import settings
from app.core.exceptions import AppError
from app.models.enums import PortionSize
from app.services.meal_estimation import (
    MEAL_PROMPT, parse_meal_response, porsiyon_gramlari,
)


# ---------------------------------------------------------------- prompt
def test_prompt_items_kelimesi_icermiyor():
    """FakeVisionProvider '\"items\"' gorurse malzeme yaniti doner ve
    ogun akisi coker. Bu testi SILME."""
    assert '"items"' not in MEAL_PROMPT


def test_prompt_olcek_referansini_istiyor():
    metin = MEAL_PROMPT.lower()
    assert "olcek referansi" in metin
    assert "catal" in metin
    for deger in ("kucuk", "orta", "buyuk"):
        assert deger in metin


# ---------------------------------------------------------------- ayristirma
def test_tam_yanit():
    t = parse_meal_response({
        "dish_name": "mercimek çorbası", "portion": "orta",
        "estimated_grams": 250, "confidence": 0.78,
        "scale_reference_found": True, "notes": "Kaşık görüldü.",
    })
    assert t.dish_name == "mercimek çorbası"
    assert t.portion is PortionSize.ORTA
    assert t.estimated_grams == 250
    assert t.confidence == 0.78
    assert t.scale_reference_found is True


@pytest.mark.parametrize("anahtar", ["dish_name", "yemek_adi", "name", "food"])
def test_farkli_ad_anahtarlari(anahtar):
    assert parse_meal_response({anahtar: "pilav"}).dish_name == "pilav"


@pytest.mark.parametrize("girdi, beklenen", [
    ("kucuk", PortionSize.KUCUK), ("küçük", PortionSize.KUCUK),
    ("SMALL", PortionSize.KUCUK), ("orta", PortionSize.ORTA),
    ("Medium", PortionSize.ORTA), ("buyuk", PortionSize.BUYUK),
    ("büyük", PortionSize.BUYUK), ("large", PortionSize.BUYUK),
])
def test_porsiyon_etiketleri(girdi, beklenen):
    assert parse_meal_response({"name": "x", "portion": girdi}).portion is beklenen


def test_yemek_adi_yoksa_hata():
    with pytest.raises(AppError):
        parse_meal_response({"portion": "orta", "estimated_grams": 300})


def test_bos_yanit_hata():
    with pytest.raises(AppError):
        parse_meal_response({})


# ---------------------------------------------------------------- gram
def test_gram_yoksa_porsiyondan_turetilir():
    t = parse_meal_response({"name": "pilav", "portion": "buyuk"})
    assert t.estimated_grams == settings.MEAL_GRAMS_LARGE


def test_porsiyon_yoksa_gramdan_turetilir():
    assert parse_meal_response(
        {"name": "pilav", "estimated_grams": 150}).portion is PortionSize.KUCUK
    assert parse_meal_response(
        {"name": "pilav", "estimated_grams": 480}).portion is PortionSize.BUYUK


def test_ikisi_de_yoksa_orta_varsayilir():
    t = parse_meal_response({"name": "pilav"})
    assert t.portion is PortionSize.ORTA
    assert t.estimated_grams == settings.MEAL_GRAMS_MEDIUM


@pytest.mark.parametrize("sacma", [0, 5, 9999, -100, "cok", None])
def test_sacma_gram_yok_sayilir(sacma):
    """3 kg'lik tabak yok; model halusinasyonu porsiyona dusmeli."""
    t = parse_meal_response(
        {"name": "pilav", "portion": "orta", "estimated_grams": sacma}
    )
    assert t.estimated_grams == settings.MEAL_GRAMS_MEDIUM


def test_porsiyon_gramlari_artan_sirali():
    g = porsiyon_gramlari()
    assert g[PortionSize.KUCUK] < g[PortionSize.ORTA] < g[PortionSize.BUYUK]


# ---------------------------------------------------------------- guven
@pytest.mark.parametrize("girdi, beklenen", [
    (0.78, 0.78), (95, 0.95), (2, 1.0), (-1, 0.0), ("yok", 0.5), (None, 0.5),
])
def test_guven_normalizasyonu(girdi, beklenen):
    assert parse_meal_response(
        {"name": "x", "confidence": girdi}).confidence == beklenen


def test_notlar_kirpilir():
    t = parse_meal_response({"name": "x", "notes": "a" * 500})
    assert len(t.notes) == 300