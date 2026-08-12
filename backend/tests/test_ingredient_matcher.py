"""W2-T05 birim testleri: uc asamali eslestirme ve bulanik arama.

Tamami SAF: veritabani, ag, fixture kurulumu yok. Milisaniyede kosar.
"""
import pytest

from app.services.ingredient_matcher import (
    FUZZY_ESIK, MatchResult, build_lookup, match_name, match_names,
)

# ------------------------------------------------------------------ sozluk
INGREDIENTS = [
    ("domates",         "Domates"),
    ("domates_salcasi", "Domates Salçası"),
    ("kirmizi_mercimek", "Kırmızı Mercimek"),
    ("yogurt",          "Yoğurt"),
    ("kasar_peyniri",   "Kaşar Peyniri"),
    ("zeytinyagi",      "Zeytinyağı"),
    ("tavuk_gogsu",     "Tavuk Göğsü"),
    ("salatalik",       "Salatalık"),
    ("sut",             "Süt"),
    ("un",              "Un"),
]

ALIASES = [
    ("k mercimek",   "kirmizi_mercimek"),
    ("mercimek kirmizi", "kirmizi_mercimek"),
    ("süzme yoğurt", "yogurt"),
    ("salça",        "domates_salcasi"),
    ("zeytin yağı",  "zeytinyagi"),
    ("tavuk eti",    "tavuk_gogsu"),
]


@pytest.fixture(scope="module")
def lookup():
    return build_lookup(INGREDIENTS, ALIASES)


# ------------------------------------------------------------------ altin set
# (girdi, beklenen_canonical) - None = eslesmemesi gerekiyor
VAKALAR = [
    # --- 1. asama: canonical_name / display_name tam eslesme
    ("domates",             "domates"),
    ("Domates",             "domates"),
    ("DOMATES",             "domates"),
    ("  domates  ",         "domates"),
    ("Kırmızı Mercimek",    "kirmizi_mercimek"),
    ("kirmizi mercimek",    "kirmizi_mercimek"),
    ("kırmızı_mercimek",    "kirmizi_mercimek"),
    ("yoğurt",              "yogurt"),
    ("YOĞURT",              "yogurt"),
    ("yogurt",              "yogurt"),
    ("Domates Salçası",     "domates_salcasi"),
    ("tavuk göğsü",         "tavuk_gogsu"),
    ("zeytinyağı",          "zeytinyagi"),
    ("süt",                 "sut"),
    ("sut",                 "sut"),
    ("un",                  "un"),

    # --- 2. asama: alias tam eslesme
    ("k mercimek",          "kirmizi_mercimek"),
    ("K. MERCİMEK",         "kirmizi_mercimek"),
    ("süzme yoğurt",        "yogurt"),
    ("salça",               "domates_salcasi"),
    ("zeytin yağı",         "zeytinyagi"),
    ("tavuk eti",           "tavuk_gogsu"),

    # --- cogul eki
    ("domatesler",          "domates"),
    ("salatalıklar",        "salatalik"),
    ("kırmızı mercimekler", "kirmizi_mercimek"),

    # --- 3. asama: bulanik
    ("salkım domates",      "domates"),      # kabul kriteri
    ("taze domates",        "domates"),
    ("1 kg domates",        "domates"),
    ("domats",              "domates"),      # yazim hatasi
    ("kaşar",               "kasar_peyniri"),
    ("kasar peynir",        "kasar_peyniri"),

    # --- eslesmemesi gerekenler
    ("ejder meyvesi",       None),
    ("deterjan",            None),
    ("qwertyuiop",          None),
    ("",                    None),
]


@pytest.mark.parametrize("girdi, beklenen", VAKALAR)
def test_vakalar(lookup, girdi, beklenen):
    assert match_name(girdi, lookup).canonical_name == beklenen


def test_dogruluk_orani_en_az_yuzde_90(lookup):
    """Kabul kriteri: test setinde dogruluk %90 uzeri."""
    dogru = sum(
        1 for girdi, beklenen in VAKALAR
        if match_name(girdi, lookup).canonical_name == beklenen
    )
    oran = dogru / len(VAKALAR)
    assert oran >= 0.90, f"Dogruluk %{oran:.0%} ({dogru}/{len(VAKALAR)})"


# ------------------------------------------------------------------ asamalar
@pytest.mark.parametrize("girdi, beklenen_asama", [
    ("domates",             "canonical"),
    ("Kırmızı Mercimek",    "canonical"),   # display_name uzerinden
    ("k mercimek",          "alias"),
    ("salça",               "alias"),
    ("domatesler",          "canonical_ek"),
    ("salkım domates",      "fuzzy"),
    ("domats",              "fuzzy"),
    ("qwertyuiop",          "none"),
])
def test_hangi_asamada_eslesti(lookup, girdi, beklenen_asama):
    assert match_name(girdi, lookup).matched_by == beklenen_asama


# ------------------------------------------------------------------ tuzaklar
def test_token_set_ratio_tuzagi(lookup):
    """'domates' hem 'domates' hem 'domates salcasi' ile 100 puan alir.

    Ikincil olcut (token_sort_ratio) olmasaydi sonuc liste sirasina
    kalirdi. Dogru olanin sectigimizi burada sabitliyoruz.
    """
    assert match_name("domates", lookup).canonical_name == "domates"
    assert match_name("taze domates", lookup).canonical_name == "domates"
    # Tersi de dogru olmali: salca sorulunca domates donmemeli
    assert match_name("domates salçası", lookup).canonical_name == "domates_salcasi"


def test_kisa_girdi_bulanik_eslesmez(lookup):
    """3 harften kisa girdide her sey her seye benzer."""
    assert match_name("ab", lookup).canonical_name is None


def test_bulanik_eslesmede_guven_dusurulur(lookup):
    kesin = match_name("domates", lookup, confidence=1.0)
    bulanik = match_name("domats", lookup, confidence=1.0)
    assert bulanik.matched_by == "fuzzy"
    assert bulanik.confidence < kesin.confidence


def test_esik_altinda_eslesme_yok(lookup):
    sonuc = match_name("deterjan", lookup)
    assert sonuc.canonical_name is None
    assert sonuc.score == 0.0


def test_eslesenlerin_skoru_esigin_uzerinde(lookup):
    for girdi, beklenen in VAKALAR:
        if beklenen is None:
            continue
        sonuc = match_name(girdi, lookup)
        assert sonuc.score >= FUZZY_ESIK, f"{girdi} -> {sonuc.score}"


# ------------------------------------------------------------------ saflik
def test_fonksiyon_saf_ayni_girdi_ayni_cikti(lookup):
    a = match_name("salkım domates", lookup)
    b = match_name("salkım domates", lookup)
    assert a == b
    assert isinstance(a, MatchResult)


def test_eslesmeyende_display_name_ham_metni_korur(lookup):
    sonuc = match_name("ejder meyvesi", lookup)
    assert sonuc.canonical_name is None
    assert sonuc.display_name == "Ejder meyvesi"


def test_toplu_eslestirme_sirayi_korur(lookup):
    girdi = [("domates", 0.9), ("qwertyuiop", 0.3), ("salça", 0.7)]
    sonuclar = match_names(girdi, lookup)
    assert [s.canonical_name for s in sonuclar] == ["domates", None, "domates_salcasi"]
    assert [s.raw_name for s in sonuclar] == ["domates", "qwertyuiop", "salça"]


def test_bilinmeyen_malzemeye_isaret_eden_alias_yutulur():
    """Bozuk seed verisi sozlugu cokertmemeli."""
    lookup = build_lookup([("domates", "Domates")], [("xyz", "olmayan_malzeme")])
    assert match_name("xyz", lookup).canonical_name is None
    assert match_name("domates", lookup).canonical_name == "domates"