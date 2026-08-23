"""W3-T10 birim testleri: kart ucunun SAF yardimcilari.

MongoDB GEREKTIRMEZ - kimlik ayristirma ve siralama tamamen saf
fonksiyonlar oldugu icin burada dogrulanabiliyor.
"""
from app.routers.recipes import MAX_CARD_IDS, order_like_request, parse_card_ids

A = "a" * 24
B = "b" * 24
C = "c" * 24


# ---------------------------------------------------------------- ayristirma
def test_bosluklar_temizlenir():
    assert parse_card_ids(f" {A} , {B} ") == [A, B]


def test_bos_parcalar_atilir():
    assert parse_card_ids(f"{A},,{B},") == [A, B]


def test_tekrarlar_atilir_sira_korunur():
    assert parse_card_ids(f"{B},{A},{B}") == [B, A]


def test_ust_sinir_uygulanir():
    cok = ",".join(f"{i:024d}" for i in range(MAX_CARD_IDS + 10))
    assert len(parse_card_ids(cok)) == MAX_CARD_IDS


def test_tamamen_bos_metin_bos_liste_doner():
    assert parse_card_ids("  ,  ") == []


# ---------------------------------------------------------------- siralama
def test_mongo_karisik_donse_de_ISTEK_sirasi_korunur():
    # Mongo $in sonucu sirasiz gelebilir; istenen sira B, A, C.
    dokumanlar = [{"_id": A}, {"_id": C}, {"_id": B}]
    sirali = order_like_request(dokumanlar, [B, A, C])
    assert [d["_id"] for d in sirali] == [B, A, C]


def test_bulunamayan_kimlik_sessizce_dusurulur():
    dokumanlar = [{"_id": A}]
    assert order_like_request(dokumanlar, [A, B]) == [{"_id": A}]


def test_hic_dokuman_yoksa_bos_liste():
    assert order_like_request([], [A, B]) == []


def test_fazladan_donen_dokuman_yok_sayilir():
    # Istenmeyen bir kayit sonuca sizmamali.
    dokumanlar = [{"_id": A}, {"_id": C}]
    assert order_like_request(dokumanlar, [A]) == [{"_id": A}]

# ---------------------------------------------------------------- sozlesme
def test_kart_semasi_alan_adiyla_id_serilestirir():
    """Mobil `id` bekler; sema ise Mongo icin `_id` alias'i tasir.

    Rota `response_model_by_alias=False` KULLANMAK ZORUNDA - yoksa
    disariya `_id` cikar ve istemci ayristirmasi coker. Bu test o
    sozlesmeyi belgeler.
    """
    from app.schemas import RecipeCard

    ham = {
        "_id": A, "title": "Patlican Kizartmasi", "slug": "patlican",
        "calories_per_serving": 533.7, "servings": 4,
        "prep_time": 30, "cook_time": 25, "difficulty": "kolay",
    }
    kart = RecipeCard.model_validate(ham)

    assert "_id" in kart.model_dump(by_alias=True)   # Mongo bicimi
    assert "id" in kart.model_dump(by_alias=False)   # istemci bicimi
    assert kart.id == A