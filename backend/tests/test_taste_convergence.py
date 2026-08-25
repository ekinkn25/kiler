"""W4-T04 birim testleri: sonumlu ortalamanin yakinsama davranisi.

Bu dosya scripts/verify_taste_engine.py ile bulunan davranislari
REGRESYONA KARSI KILITLER. Script gercek veriyle olcer ve MongoDB ister;
buradaki testler ayni kurallari deterministik ve baglantisiz dogrular.

Bulgular: docs/w4-t04-ogrenen-profil-dogrulama.md
"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import User
from app.models.enums import TasteDimension
from app.models.recipe import UserTasteWeight
from app.services import taste_service
from app.services.taste_service import (
    STRENGTH_BEGENDIM, STRENGTH_SEVMEDIM, STRENGTH_YAPTIM, TASTE_ALPHA,
    apply_taste_event,
)

BOYUT = TasteDimension.CUISINE
ANAHTAR = "turk"


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="convergence@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


def sinyal_gonder(db, user, deger, adet=1, strength=1.0):
    for _ in range(adet):
        apply_taste_event(db, user.id, BOYUT, ANAHTAR, deger, strength=strength)
    return db.query(UserTasteWeight).one()


# ---------------------------------------------------------------- aralik
def test_agirlik_araligi_hicbir_kombinasyonda_tasmaz(db, user):
    """CheckConstraint('weight BETWEEN -1 AND 1') kod tarafinda garanti.

    Konveks birlesim kullanildigi icin sinyal ve agirlik [-1,1] icindeyken
    sonuc da oyle kalir. Guc sinyale carpilsaydi bu kirilirdi.
    """
    for guc in (1.0, 3.0, 10.0):
        for deger in (1.0, -1.0):
            satir = sinyal_gonder(db, user, deger, adet=20, strength=guc)
            assert -1.0 <= satir.weight <= 1.0, (guc, deger, satir.weight)


def test_yuksek_guc_alphayi_bire_kirpar(db, user):
    """strength=10 ile alpha 1.0'i gecmez; agirlik sinyali asamaz."""
    satir = sinyal_gonder(db, user, 1.0, adet=5, strength=10.0)
    assert satir.weight == pytest.approx(1.0)


# ---------------------------------------------------------------- soguk baslangic
def test_ilk_sinyal_agirligi_dogrudan_esitler(db, user):
    """Soguk baslangic duzeltmesi: ilk olayda alpha 1/n = 1.

    Bu olmasaydi tek kart begenen kullanicida agirlik 0.20'de kalir,
    zevk vektoru neredeyse hic konusmazdi.
    """
    satir = sinyal_gonder(db, user, 1.0)
    assert satir.weight == pytest.approx(1.0)
    assert satir.event_count == 1


def test_erken_olaylarda_ornek_ortalamasi_gibi_davranir(db, user):
    """1/n > TASTE_ALPHA oldugu surece guncelleme ornek ortalamasidir."""
    apply_taste_event(db, user.id, BOYUT, ANAHTAR, 1.0)
    apply_taste_event(db, user.id, BOYUT, ANAHTAR, -1.0)
    satir = db.query(UserTasteWeight).one()
    # 2. olayda alpha = max(0.20, 1/2) = 0.5 -> 1.0 + 0.5*(-1-1) = 0.0
    assert satir.weight == pytest.approx(0.0)


def test_kararli_durumda_alpha_sabitlenir(db, user):
    """1/n TASTE_ALPHA'nin altina dustukten sonra adim buyuklugu sabit."""
    esik = int(1 / TASTE_ALPHA)  # bu olaydan sonra 1/n < alpha
    sinyal_gonder(db, user, 0.0, adet=esik + 2)
    onceki = db.query(UserTasteWeight).one().weight

    apply_taste_event(db, user.id, BOYUT, ANAHTAR, 1.0)
    satir = db.query(UserTasteWeight).one()
    beklenen = onceki + TASTE_ALPHA * (1.0 - onceki)
    assert satir.weight == pytest.approx(beklenen)


# ---------------------------------------------------------------- yakinsama
def test_sabit_sinyal_altinda_doygunlasir(db, user):
    """Ayni sinyal tekrarlanirsa agirlik hedefe yakinsar - beklenen davranis."""
    satir = sinyal_gonder(db, user, 1.0, adet=30)
    assert satir.weight == pytest.approx(1.0, abs=1e-3)


def test_zevk_degisimi_takip_edilir(db, user):
    """W4-T04'un ASIL kazanimi: ornek ortalamasinin yapamadigi sey.

    Kullanici 30 kart begenip sonra fikir degistirirse motor bunu makul
    surede takip etmeli. Ornek ortalamasinda 5 zit sinyal agirligi
    1.0'dan ancak ~0.71'e cekerdi; sonumlu ortalamada isaret degistirir.
    """
    sinyal_gonder(db, user, 1.0, adet=30)
    satir = sinyal_gonder(db, user, -1.0, adet=5)

    ornek_ortalamasi = (30 * 1.0 + 5 * -1.0) / 35  # ~0.714
    assert satir.weight < 0, f"zevk degisimi takip edilmedi: {satir.weight}"
    assert satir.weight < ornek_ortalamasi


def test_yaptim_begendimden_daha_hizli_ogrenir(db, user):
    """Eski tasarimda tekrar=3 nihai agirligi DEGISTIRMIYORDU.

    Ayni ortalama guncellemesini uc kez kosturmak yalnizca yakinsamayi
    hizlandiriyor, tavani yine 1.0'da birakiyordu; 'yaptim' pratikte
    'begendim' ile ayni agirligi uretiyordu. Guc artik sonum hizinda.
    """
    # Once tabani notr olmayan bir yere getir ki fark gorunur olsun.
    begendim = sinyal_gonder(db, user, -1.0, adet=10)
    assert begendim.weight == pytest.approx(-1.0, abs=1e-3)
    apply_taste_event(db, user.id, BOYUT, ANAHTAR, 1.0,
                      strength=STRENGTH_BEGENDIM)
    begendim_sonrasi = db.query(UserTasteWeight).one().weight

    db.query(UserTasteWeight).delete()
    db.commit()

    yaptim = sinyal_gonder(db, user, -1.0, adet=10)
    assert yaptim.weight == pytest.approx(-1.0, abs=1e-3)
    apply_taste_event(db, user.id, BOYUT, ANAHTAR, 1.0,
                      strength=STRENGTH_YAPTIM)
    yaptim_sonrasi = db.query(UserTasteWeight).one().weight

    assert yaptim_sonrasi > begendim_sonrasi, (
        f"yaptim={yaptim_sonrasi} begendim={begendim_sonrasi} - "
        "sinyal gucleri ayrismiyor"
    )


def test_sevmedim_begendimi_dengeler(db, user):
    """Zit ve esit guclu sinyaller agirligi notre yaklastirmali."""
    assert STRENGTH_SEVMEDIM == STRENGTH_BEGENDIM
    for _ in range(10):
        apply_taste_event(db, user.id, BOYUT, ANAHTAR, 1.0,
                          strength=STRENGTH_BEGENDIM)
        apply_taste_event(db, user.id, BOYUT, ANAHTAR, -1.0,
                          strength=STRENGTH_SEVMEDIM)
    satir = db.query(UserTasteWeight).one()
    assert abs(satir.weight) < 0.35


# ---------------------------------------------------------------- sayac
def test_event_count_gercek_sinyal_sayisini_tasir(db, user):
    """Yakinsama raporu bu sayaca bakiyor; sisirilmis olmamali."""
    sinyal_gonder(db, user, 1.0, adet=4, strength=STRENGTH_YAPTIM)
    assert db.query(UserTasteWeight).one().event_count == 4


def test_tekrar_parametresi_kaldirildi():
    """Eski API yanlislikla geri gelmesin."""
    with pytest.raises(TypeError):
        taste_service.register_recipe_signal(
            None, 1, {"cuisine": "turk"}, signal=1.0, tekrar=3
        )
