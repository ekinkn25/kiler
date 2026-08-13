"""W2-T09 birim testleri: niyet cikarma, prompt/aday dogrulama.

MongoDB ve LLM GEREKTIRMEZ. extract_intent ve parse_and_validate saf
fonksiyonlardir.
"""
import pytest

from app.services.chat.base import ADAYLAR_BASI, ADAYLAR_SONU
from app.services.chat_rag import build_prompt, extract_intent, parse_and_validate
from app.services.ingredient_matcher import build_lookup


@pytest.fixture(scope="module")
def lookup():
    ingredients = [
        ("kirmizi_mercimek", "Kırmızı Mercimek"),
        ("domates", "Domates"),
        ("makarna", "Makarna"),
    ]
    aliases = [("mercimek", "kirmizi_mercimek")]
    return build_lookup(ingredients, aliases)


# ---------------------------------------------------------------- kalori
@pytest.mark.parametrize("mesaj, beklenen", [
    ("Hafif bir sey onerir misin", 0.7),
    ("Az kalorili bir yemek istiyorum", 0.7),
    ("Doyurucu bir sey lazim", 1.3),
    ("Ne yesem bilmiyorum", None),
])
def test_kalori_orani(lookup, mesaj, beklenen):
    assert extract_intent(mesaj, lookup).calorie_ratio == beklenen


# ---------------------------------------------------------------- sure
@pytest.mark.parametrize("mesaj, beklenen", [
    ("30 dakikada yapabilecegim bir sey", 30),
    ("20 dk'da hazir olsun", 20),
    ("1 saat surebilir", 60),
    ("yarim saatte biter mi", 30),
    ("hizlica bir sey", 20),
    ("ne zaman istersen", None),
])
def test_sure_cikarimi(lookup, mesaj, beklenen):
    assert extract_intent(mesaj, lookup).max_total_minutes == beklenen


# ---------------------------------------------------------------- malzeme
def test_ornek_senaryo_kabul_kriteri(lookup):
    """Gorev tanimindaki ORNEK CUMLE."""
    intent = extract_intent(
        "Hafif, mercimekli, 30 dakikada yapabilecegim bir sey", lookup
    )
    assert intent.calorie_ratio == 0.7
    assert intent.max_total_minutes == 30
    assert "kirmizi_mercimek" in intent.mentioned_ingredients


def test_alias_da_yakalanir(lookup):
    intent = extract_intent("mercimekli corba istiyorum", lookup)
    assert "kirmizi_mercimek" in intent.mentioned_ingredients


def test_fuzzy_kullanilmiyor_yanlis_pozitif_yok(lookup):
    """'domates' gibi bariz olmayan rastgele kelimeler yakalanmamali."""
    intent = extract_intent("yarin okula gidecegim", lookup)
    assert intent.mentioned_ingredients == ()


def test_malzeme_yoksa_bos_tuple(lookup):
    assert extract_intent("napsam bilmiyorum", lookup).mentioned_ingredients == ()


# ---------------------------------------------------------------- prompt
def test_prompt_isaretleyicileri_iceriyor(lookup):
    intent = extract_intent("hafif bir sey", lookup)
    adaylar = [{"id": "a" * 24, "title": "Mercimek Çorbası",
               "calories_per_serving": 200, "prep_time": 10, "cook_time": 20,
               "matched_ingredients": ["kirmizi_mercimek"], "missing_ingredients": []}]
    _, user_prompt = build_prompt(intent, adaylar)
    assert ADAYLAR_BASI in user_prompt and ADAYLAR_SONU in user_prompt
    assert "a" * 24 in user_prompt


def test_sistem_prompt_uydurmayi_yasakliyor(lookup):
    intent = extract_intent("x", lookup)
    system_prompt, _ = build_prompt(intent, [])
    metin = system_prompt.lower()
    assert "uydurma" in metin or "olmayan" in metin


# ---------------------------------------------------------------- dogrulama (UYDURMAYA KARSI)
ADAYLAR = [
    {"id": "a" * 24, "title": "Mercimek Çorbası"},
    {"id": "b" * 24, "title": "Domates Çorbası"},
]


def test_gecerli_id_kabul_edilir():
    mesaj, idler = parse_and_validate(
        {"mesaj": "Iste!", "onerilen_tarif_idleri": ["a" * 24]}, ADAYLAR
    )
    assert idler == ["a" * 24] and mesaj == "Iste!"


def test_UYDURMA_ID_ELENIR():
    """KABUL KRITERININ KILIDI: adaylar disindaki id asla disari cikmamali."""
    mesaj, idler = parse_and_validate(
        {"mesaj": "Iste!", "onerilen_tarif_idleri": ["z" * 24, "a" * 24]}, ADAYLAR
    )
    assert idler == ["a" * 24]
    assert "z" * 24 not in idler


def test_tum_idler_uydurmaysa_otomatik_siralamaya_duser():
    mesaj, idler = parse_and_validate(
        {"mesaj": "Iste!", "onerilen_tarif_idleri": ["z" * 24]}, ADAYLAR
    )
    assert idler == [a["id"] for a in ADAYLAR[:3]]


def test_id_hic_donmezse_otomatik_siralama():
    _, idler = parse_and_validate({"mesaj": "..."}, ADAYLAR)
    assert idler == [a["id"] for a in ADAYLAR]


def test_aday_yoksa_bos_liste_doner():
    _, idler = parse_and_validate({"mesaj": "..."}, [])
    assert idler == []


def test_farkli_anahtar_isimleri_toleransli():
    mesaj, idler = parse_and_validate(
        {"message": "Hi", "recommended_recipe_ids": ["a" * 24]}, ADAYLAR
    )
    assert mesaj == "Hi" and idler == ["a" * 24]


def test_uzun_mesaj_kirpilir():
    mesaj, _ = parse_and_validate({"mesaj": "x" * 2000}, [])
    assert len(mesaj) == 1000