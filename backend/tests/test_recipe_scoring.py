"""W2-T06 birim testleri: skorlama pipeline'inin yapisi.

MongoDB'ye BAGLANMAZ. build_scoring_pipeline saf oldugu icin uretilen
dict yapisi dogrudan incelenebiliyor.
"""
import pytest

from app.core.config import settings
from app.services.recipe_scoring import (
    ScoringContext, build_scoring_pipeline,
)


def asama(pipeline, ad):
    """Pipeline icinde verilen operatoru tasiyan ilk asamayi doner."""
    for a in pipeline:
        if ad in a:
            return a[ad]
    raise AssertionError(f"'{ad}' asamasi bulunamadi")


def alan_ara(nesne, anahtar):
    """Ic ice dict/list icinde bir anahtari arar (varlik testi icin)."""
    if isinstance(nesne, dict):
        if anahtar in nesne:
            return True
        return any(alan_ara(v, anahtar) for v in nesne.values())
    if isinstance(nesne, list):
        return any(alan_ara(v, anahtar) for v in nesne)
    return False


@pytest.fixture()
def ctx():
    return ScoringContext(
        var=("domates", "sogan"),
        bilinmiyor=("un",),
        diet_tags=("vegan",),
        allergens=("gluten", "findik"),
        taste=({"dim": "cuisine", "key": "turk", "w": 0.6},),
        calorie_target=650.0,
        target_minutes=45,
    )


# ---------------------------------------------------------------- filtreler
def test_alerjen_filtresi_match_asamasinda(ctx):
    """GUVENLIK: alerjen elemesi skorlamadan ONCE olmali."""
    pipeline = build_scoring_pipeline(ctx)
    assert "$match" in pipeline[0], "match ilk asama olmali"
    assert pipeline[0]["$match"]["allergens"] == {"$nin": ["gluten", "findik"]}


def test_diyet_filtresi_all_kullanir(ctx):
    """Cok diyetli kullanicida $in yanlis sonuc verir; $all dogrusu."""
    pipeline = build_scoring_pipeline(ctx)
    assert pipeline[0]["$match"]["diet_tags"] == {"$all": ["vegan"]}


def test_alerjeni_olmayan_kullanicida_filtre_eklenmez():
    pipeline = build_scoring_pipeline(ScoringContext())
    assert "allergens" not in pipeline[0]["$match"]
    assert "diet_tags" not in pipeline[0]["$match"]


def test_pasif_tarifler_elenir(ctx):
    pipeline = build_scoring_pipeline(ctx)
    assert pipeline[0]["$match"]["is_active"] == {"$ne": False}


def test_gecersiz_exclude_id_cokertmez(ctx):
    pipeline = build_scoring_pipeline(ctx, exclude_ids=["bu-gecerli-degil"])
    assert "_id" not in pipeline[0]["$match"]


# ---------------------------------------------------------------- kesisim
def test_kiler_kesisimi_setintersection_ile(ctx):
    pipeline = build_scoring_pipeline(ctx)
    kesisim = next(
        a["$addFields"] for a in pipeline
        if "$addFields" in a and "_var" in a["$addFields"]
    )
    assert kesisim["_var"] == {"$setIntersection": ["$_zorunlu", ["domates", "sogan"]]}
    assert kesisim["_bilinmiyor"] == {"$setIntersection": ["$_zorunlu", ["un"]]}


def test_payda_tekillestirilmis(ctx):
    """setIntersection tekillestirir; payda da tekillestirilmeli."""
    pipeline = build_scoring_pipeline(ctx)
    kesisim = next(
        a["$addFields"] for a in pipeline
        if "$addFields" in a and "_toplam" in a["$addFields"]
    )
    assert kesisim["_toplam"] == {"$size": {"$setUnion": ["$_zorunlu", []]}}


# ---------------------------------------------------------------- agirliklar
def test_bilinmiyor_agirligi_ayardan_geliyor(ctx):
    pipeline = build_scoring_pipeline(ctx)
    skorlar = next(
        a["$addFields"] for a in pipeline
        if "$addFields" in a and "_s_kiler" in a["$addFields"]
    )
    carpim = skorlar["_s_kiler"]["$cond"][2]["$divide"][0]["$add"][1]["$multiply"]
    assert carpim[1] == settings.PANTRY_UNKNOWN_WEIGHT


def test_dort_agirlik_final_skorda(ctx):
    pipeline = build_scoring_pipeline(ctx)
    final = next(
        a["$addFields"]["final_score"] for a in pipeline
        if "$addFields" in a and "final_score" in a["$addFields"]
    )
    carpanlar = [t["$multiply"][0] for t in final["$round"][0]["$add"]]
    assert carpanlar == [
        settings.SCORE_W_PANTRY, settings.SCORE_W_CALORIE,
        settings.SCORE_W_TASTE, settings.SCORE_W_TIME,
    ]


def test_agirliklarin_toplami_bir():
    toplam = (settings.SCORE_W_PANTRY + settings.SCORE_W_CALORIE
              + settings.SCORE_W_TASTE + settings.SCORE_W_TIME)
    assert abs(toplam - 1.0) < 1e-9


def test_kiler_en_agirlikli_bilesen():
    """Gorev tanimi kiler agirligini 0.50 istiyor - digerlerinden buyuk."""
    assert settings.SCORE_W_PANTRY >= 0.5
    assert settings.SCORE_W_PANTRY > settings.SCORE_W_CALORIE


# ---------------------------------------------------------------- cikti
def test_siralama_ve_sayfalama(ctx):
    pipeline = build_scoring_pipeline(ctx, limit=10, skip=20)
    assert asama(pipeline, "$sort") == {"final_score": -1, "_id": 1}
    assert asama(pipeline, "$skip") == 20
    assert asama(pipeline, "$limit") == 10


def test_skor_kirilimi_yanitta(ctx):
    """Aciklanabilirlik: kabul kriteri skor kiriliminin donmesini istiyor."""
    proj = asama(pipeline := build_scoring_pipeline(ctx), "$project")
    assert set(proj["score_breakdown"]) == {
        "pantry", "calorie", "taste", "time", "weights"
    }
    for alan in ("matched_ingredients", "missing_ingredients",
                 "unknown_ingredients", "total_required", "final_score"):
        assert alan in proj, alan
    assert proj["_id"] == 0 and proj["id"] == {"$toString": "$_id"}


def test_zevk_vektoru_literal_ile_gomulur(ctx):
    """$literal olmadan 'dim'/'key' anahtarlari ifade sanilirdi."""
    pipeline = build_scoring_pipeline(ctx)
    zevk = next(
        a["$addFields"]["_zevk_ham"] for a in pipeline
        if "$addFields" in a and "_zevk_ham" in a["$addFields"]
    )
    assert zevk["$reduce"]["input"] == {"$literal": list(ctx.taste)}


def test_bos_baglamda_da_gecerli_pipeline():
    """Yeni kullanici: kiler bos, zevk yok, kisit yok."""
    pipeline = build_scoring_pipeline(ScoringContext())
    assert len(pipeline) >= 8
    assert all(isinstance(a, dict) and len(a) == 1 for a in pipeline)


# ---------------------------------------------------------------- matematik
@pytest.mark.parametrize("var, bilinmiyor, toplam, beklenen", [
    (3, 0, 3, 1.00),   # hepsi var
    (0, 0, 3, 0.00),   # hicbiri yok
    (0, 3, 3, 0.40),   # hepsi bilinmiyor -> 0.4 katsayisi
    (2, 1, 3, 0.80),   # (2*1.0 + 1*0.4) / 3
    (1, 1, 4, 0.35),   # (1*1.0 + 1*0.4) / 4
])
def test_kiler_skoru_matematigi(var, bilinmiyor, toplam, beklenen):
    """Pipeline'daki formulun Python karsiligi - beklentiyi sabitler."""
    puan = (var * 1.0 + bilinmiyor * settings.PANTRY_UNKNOWN_WEIGHT) / toplam
    assert round(puan, 2) == beklenen

def test_required_ingredients_in_filtresi():
    """W2-T09: chat'te bahsedilen malzeme sert filtre olarak giriyor."""
    ctx = ScoringContext(required_ingredients=("kirmizi_mercimek",))
    match = build_scoring_pipeline(ctx)[0]["$match"]
    assert match["ingredients.canonical_name"] == {"$in": ["kirmizi_mercimek"]}