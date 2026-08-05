"""Birim donusum servisi testleri (W1-T12).

Calistirma (backend/ klasorunde):  pytest
"""
import pytest

from app.services.unit_service import (
    UnitConversionError,
    cooked_to_raw,
    from_base,
    normalize_text,
    raw_to_cooked,
    to_base,
    to_canonical_form,
    to_grams,
)


# ---------------------------------------------------------------- kutle
@pytest.mark.parametrize(
    "miktar,birim,beklenen",
    [
        (5, "kg", 5000),      # "5 kg mercimek aldim"
        (500, "g", 500),
        (0.5, "kg", 500),
        (0, "g", 0),
        (1.25, "kg", 1250),
    ],
)
def test_kutle_gram_donusumu(miktar, birim, beklenen):
    assert to_grams(miktar, birim) == pytest.approx(beklenen)


# ---------------------------------------------------------------- hacim
@pytest.mark.parametrize(
    "miktar,birim,beklenen_ml",
    [
        (1, "su_bardagi", 200),
        (2, "su_bardagi", 400),
        (1, "yemek_kasigi", 15),
        (1, "tatli_kasigi", 10),
        (1, "cay_kasigi", 5),
        (1, "l", 1000),
        (250, "ml", 250),
    ],
)
def test_hacim_gram_donusumu_su_yogunlugu(miktar, birim, beklenen_ml):
    """Yogunluk verilmezse su kabul edilir: 1 ml = 1 g."""
    assert to_grams(miktar, birim) == pytest.approx(beklenen_ml)


def test_hacim_yogunluk_ile():
    """1 su bardagi zeytinyagi = 200 ml x 0.92 = 184 g"""
    assert to_grams(1, "su_bardagi", ml_to_gram=0.92) == pytest.approx(184)


def test_hacim_yogunluk_bal():
    """1 yemek kasigi bal = 15 ml x 1.42 = 21.3 g"""
    assert to_grams(1, "yemek_kasigi", ml_to_gram=1.42) == pytest.approx(21.3)


# ---------------------------------------------------------------- adet
def test_adet_gram_donusumu():
    """2 sogan = 2 x 150 g = 300 g"""
    assert to_grams(2, "adet", grams_per_piece=150) == pytest.approx(300)


def test_dilim_gram_donusumu():
    """4 dilim ekmek = 4 x 30 g = 120 g"""
    assert to_grams(4, "dilim", grams_per_piece=30) == pytest.approx(120)


def test_demet_gram_donusumu():
    """0.5 demet maydanoz = 30 g"""
    assert to_grams(0.5, "demet", grams_per_piece=60) == pytest.approx(30)


def test_adet_gpp_yoksa_hata():
    with pytest.raises(UnitConversionError, match="grams_per_piece"):
        to_grams(2, "adet")


# ---------------------------------------------------------------- hatali girdiler
def test_bilinmeyen_birim_hata():
    with pytest.raises(UnitConversionError, match="Bilinmeyen birim"):
        to_grams(1, "ton")


def test_negatif_miktar_hata():
    with pytest.raises(UnitConversionError, match="negatif"):
        to_grams(-5, "kg")


@pytest.mark.parametrize("miktar,birim", [(None, "g"), (5, None), (None, None)])
def test_bos_deger_sifir_doner(miktar, birim):
    """Olcusuz malzeme (tuz, karabiber) kaloriye katilmaz."""
    assert to_grams(miktar, birim) == 0.0


# ---------------------------------------------------------------- temel birim / gosterim
def test_to_base_kutle():
    assert to_base(5, "kg", "mass") == pytest.approx(5000)


def test_to_base_hacim():
    assert to_base(1.5, "l", "volume") == pytest.approx(1500)


def test_to_base_adet():
    assert to_base(3, "adet", "count") == pytest.approx(3)


def test_from_base_gosterim():
    """5000 g -> kullaniciya 5 kg olarak gosterilir."""
    assert from_base(5000, "kg") == pytest.approx(5)


def test_from_base_adet():
    """450 g sogan -> 3 adet"""
    assert from_base(450, "adet", grams_per_piece=150) == pytest.approx(3)


def test_gidis_donus_kaybi_yok():
    """to_base -> from_base turu deger kaybetmemeli."""
    assert from_base(to_base(2.5, "kg", "mass"), "kg") == pytest.approx(2.5)


# ---------------------------------------------------------------- pisme faktoru
def test_pismis_cig_donusumu():
    """150 g pilav, yield=2.9 -> ~51.7 g cig pirinc"""
    assert cooked_to_raw(150, 2.9) == pytest.approx(51.72, rel=1e-3)


def test_cig_pismis_donusumu():
    """100 g cig pirinc -> 290 g pilav"""
    assert raw_to_cooked(100, 2.9) == pytest.approx(290)


def test_yield_yoksa_degismez():
    assert cooked_to_raw(150, None) == 150
    assert raw_to_cooked(150, 0) == 150


# ---------------------------------------------------------------- metin normalizasyonu
@pytest.mark.parametrize(
    "girdi,beklenen",
    [
        ("Kırmızı Mercimek", "kirmizi mercimek"),
        ("KIRMIZI MERCİMEK", "kirmizi mercimek"),
        ("  Kırmızı   Mercimek  ", "kirmizi mercimek"),
        ("Kırmızı Mercimek (1 KG)", "kirmizi mercimek 1 kg"),
        ("Yeşil Biber / Çarliston", "yesil biber carliston"),
        ("Ispanak", "ispanak"),
        ("ISPANAK", "ispanak"),
        ("Şeftali", "seftali"),
        ("", ""),
    ],
)
def test_metin_normalizasyonu(girdi, beklenen):
    assert normalize_text(girdi) == beklenen


def test_buyuk_kucuk_harf_ayni_sonuc():
    """Turkce I/i belirsizligi tek yone katlanmali."""
    assert normalize_text("IRMIK") == normalize_text("ırmık") == normalize_text("Irmik")


def test_canonical_forma_cevirme():
    assert to_canonical_form("Kırmızı Mercimek") == "kirmizi_mercimek"
    assert to_canonical_form("Nar Ekşisi") == "nar_eksisi"