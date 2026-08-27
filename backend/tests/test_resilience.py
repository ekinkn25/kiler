"""W4-T15 dayaniklilik testleri.

KABUL KRITERI: gorme modeli veya LLM coktugunde uygulama COKMEZ; kural
tabanli oneriye / elle girise duser ve kullaniciya NOTR mesaj gosterir.

Ag ve GERCEK veritabani GEREKTIRMEZ:
  - 'broken' saglayicilar deterministik olarak patlar (ag kesmeye gerek yok)
  - log_vision_call icin SahteOturum yeterli: VisionRequest nesnesi
    olusturmak veritabani istemiyor, sadece add/commit/refresh cagriliyor

Bu dosya ayrica B1-B4 hata duzeltmelerinin GERI GELMEMESI icin nobet tutar.
"""
from __future__ import annotations

import asyncio
import io

import pytest
from PIL import Image

from app.core.circuit_breaker import DevreKesici, gorme_devresi, sohbet_devresi
from app.core.config import settings
from app.schemas import MealEstimate, RagChatResponse
from app.services.chat import BrokenChatProvider, ChatError, reset_chat_provider
from app.services.chat_rag import kural_tabanli_yanit
from app.services.meal_estimation import bos_tahmin, estimate_meal
from app.services.vision import (
    BrokenVisionProvider, GroqVisionProvider, InvalidImage, VisionError,
    prepare_image, reset_vision_provider,
)
from app.services.vision_ingredients import VisionDailyLimitExceeded, detect_ingredients


# ==================================================================
# Yardimcilar
# ==================================================================
class SahteOturum:
    """log_vision_call'in ihtiyac duydugu en kucuk Session taklidi.

    Gercek veritabani acmiyoruz: bu testlerin konusu KAYIT degil, hata
    aninda dogru YOLA sapilip sapilmadigi.
    """

    def __init__(self) -> None:
        self.eklenenler: list = []

    def add(self, nesne) -> None:
        self.eklenenler.append(nesne)

    def commit(self) -> None:
        pass

    def refresh(self, nesne) -> None:
        pass


def ornek_jpeg(boyut: tuple[int, int] = (64, 64)) -> bytes:
    """prepare_image'in kabul edecegi gercek bir JPEG uretir."""
    tampon = io.BytesIO()
    Image.new("RGB", boyut, (180, 90, 60)).save(tampon, format="JPEG")
    return tampon.getvalue()


ADAYLAR = [
    {"id": "a1", "title": "mercimek corbasi", "calories_per_serving": 180},
    {"id": "a2", "title": "menemen", "calories_per_serving": 320},
    {"id": "a3", "title": "pilav", "calories_per_serving": 400},
    {"id": "a4", "title": "makarna", "calories_per_serving": 450},
]


@pytest.fixture(autouse=True)
def devreleri_sifirla():
    """Devre kesiciler SUREC OMURLU tekil nesneler.

    Sifirlanmazsa bir testin urettigi 3 hata devreyi acar ve SONRAKI test
    'vision_timeout' yerine 'vision_circuit_open' gorur. Test sirasina
    bagimli, aralikli patlayan bir paket istemiyoruz.
    """
    gorme_devresi.sifirla()
    sohbet_devresi.sifirla()
    yield
    gorme_devresi.sifirla()
    sohbet_devresi.sifirla()


@pytest.fixture
def bozuk_gorme(monkeypatch):
    """Gorme saglayicisini 'broken'a cevirir, test sonunda geri alir."""
    monkeypatch.setattr(settings, "VISION_PROVIDER", "broken")
    reset_vision_provider()
    yield
    reset_vision_provider()


# ==================================================================
# 1) Bozuk saglayicilar gercekten patliyor mu
# ==================================================================
def test_bozuk_gorme_saglayicisi_vision_error_firlatir():
    with pytest.raises(VisionError):
        asyncio.run(BrokenVisionProvider().analyze(b"x", "prompt"))


def test_bozuk_sohbet_saglayicisi_chat_error_firlatir():
    with pytest.raises(ChatError):
        asyncio.run(BrokenChatProvider().complete("sistem", "kullanici"))


def test_broken_saglayici_ayardan_secilebiliyor(bozuk_gorme):
    from app.services.vision import get_vision_provider

    assert get_vision_provider().name == "broken"


def test_broken_sohbet_saglayicisi_ayardan_secilebiliyor(monkeypatch):
    from app.services.chat import get_chat_provider

    monkeypatch.setattr(settings, "CHAT_PROVIDER", "broken")
    reset_chat_provider()
    try:
        assert get_chat_provider().name == "broken"
    finally:
        reset_chat_provider()


# ==================================================================
# 2) A2 - LLM coktugunde kural tabanli yanit
# ==================================================================
def test_kural_tabanli_yanit_ilk_ucu_secer():
    """Adaylar skorlama motorundan SIRALI geliyor; ilk 3'u aliyoruz."""
    mesaj, idler = kural_tabanli_yanit(ADAYLAR)
    assert idler == ["a1", "a2", "a3"]
    assert mesaj.strip()


def test_kural_tabanli_yanit_notr_dil_kullanir():
    """Kullaniciya altyapi arizasi ANLATILMAZ."""
    mesaj, _ = kural_tabanli_yanit(ADAYLAR)
    yasakli = ("hata", "çöktü", "coktu", "sunucu", "yapay zeka", "api", "servis")
    assert not any(k in mesaj.lower() for k in yasakli), mesaj


def test_aday_yoksa_yol_gosteren_mesaj_doner():
    mesaj, idler = kural_tabanli_yanit([])
    assert idler == []
    assert "kiler" in mesaj.lower()      # ne yapacagini SOYLUYOR


def test_ucten_az_aday_varsa_hepsi_donuyor():
    mesaj, idler = kural_tabanli_yanit(ADAYLAR[:2])
    assert idler == ["a1", "a2"]
    assert "2" in mesaj                  # sayi mesajda dogru geciyor


def test_dusus_yaniti_sozlesmeye_uyuyor():
    """Kural tabanli yanit RagChatResponse'a sorunsuz oturmali."""
    mesaj, idler = kural_tabanli_yanit(ADAYLAR)
    yanit = RagChatResponse(
        conversation_id=1, mesaj=mesaj, onerilen_tarif_idleri=idler,
        degraded=True, degraded_reason="chat_timeout",
    )
    assert yanit.degraded is True
    assert len(yanit.onerilen_tarif_idleri) == 3


# ==================================================================
# 3) A1 - gorme modeli coktugunde elle girise dusus
# ==================================================================
def test_bos_tahmin_elle_girise_hazir():
    t = bos_tahmin("ozet123", neden="vision_timeout")
    assert t["degraded"] is True
    assert t["degraded_reason"] == "vision_timeout"
    assert t["needs_manual_entry"] is True
    assert t["requires_confirmation"] is True
    assert t["calories"] is None
    # Sema gt=0 istiyor: 0 dondurursek dogrulama patlar.
    assert t["estimated_grams"] > 0
    # Porsiyon secenekleri DOLU: kullanici boyu degistirebilsin.
    assert len(t["portion_options"]) == 3


def test_bos_tahmin_semaya_oturuyor():
    """MealEstimate dogrulamasi gecmezse uc 500 doner - dusus ise yaramaz."""
    model = MealEstimate(**bos_tahmin("ozet123", neden="vision_error"))
    assert model.degraded is True
    assert model.dish_name == ""
    assert model.calories is None
    assert model.macros is None


def test_estimate_meal_gorme_cokunce_200_donuyor(bozuk_gorme):
    """UCTAN UCA: saglayici %100 hata verirken istisna DEGIL, tahmin doner."""
    db = SahteOturum()
    sonuc = asyncio.run(
        estimate_meal(db, None, raw_image=ornek_jpeg(), user_id=None)
    )

    assert sonuc["degraded"] is True
    assert sonuc["needs_manual_entry"] is True
    assert sonuc["degraded_reason"] == "vision_timeout"
    # Basarisiz cagri da kaydedilmeli: hata orani maliyet analizinin parcasi.
    assert len(db.eklenenler) == 1
    assert db.eklenenler[0].success is False
    # Ve yanit sema dogrulamasindan gecmeli.
    assert MealEstimate(**sonuc).degraded is True


def test_estimate_meal_devre_acikken_saglayiciya_gitmiyor(bozuk_gorme):
    """Devre acikken cagri HIC yapilmaz: hizli basarisizlik."""
    gorme_devresi.basarisiz()
    gorme_devresi.basarisiz()
    gorme_devresi.basarisiz()
    assert gorme_devresi.durum == "acik"

    db = SahteOturum()
    sonuc = asyncio.run(
        estimate_meal(db, None, raw_image=ornek_jpeg(), user_id=None)
    )
    assert sonuc["degraded_reason"] == "vision_circuit_open"


def test_detect_ingredients_dusmez_hata_firlatir(bozuk_gorme):
    """/vision/ingredients sozlesmesi list[...]; bayrak tasiyamaz.

    Bu yuzden BURADA dusus YOK - hata firlar, dususu mobil taraf yapar.
    Devre kesici yine de calismali.
    """
    db = SahteOturum()
    with pytest.raises(VisionError):
        asyncio.run(detect_ingredients(db, raw_image=ornek_jpeg(), user_id=None))


# ==================================================================
# 4) Devre kesici
# ==================================================================
def test_devre_esikten_sonra_acilir():
    d = DevreKesici("test", hata_esigi=3, acik_kalma_saniye=60)
    assert d.izin_var_mi()
    for _ in range(3):
        d.basarisiz()
    assert d.durum == "acik"
    assert not d.izin_var_mi()


def test_devre_esigin_altinda_kapali_kalir():
    d = DevreKesici("test", hata_esigi=3, acik_kalma_saniye=60)
    d.basarisiz()
    d.basarisiz()
    assert d.durum == "kapali"
    assert d.izin_var_mi()


def test_devre_basarili_cagriyla_kapanir():
    """Sayac ARDISIK hatayi sayar; araya basarili girerse sifirlanir."""
    d = DevreKesici("test", hata_esigi=2, acik_kalma_saniye=60)
    d.basarisiz()
    d.basarili()
    d.basarisiz()
    assert d.durum == "kapali"


def test_devre_sure_dolunca_yari_acilir():
    d = DevreKesici("test", hata_esigi=1, acik_kalma_saniye=0)
    d.basarisiz()
    assert d.durum == "yari_acik"
    assert d.izin_var_mi()      # tek deneme cagrisina izin


def test_devre_ayarlardan_besleniyor():
    """circuit_breaker.py'de '...' yer tutucusu kalmis olmasin (W4-T15/H4)."""
    for devre in (gorme_devresi, sohbet_devresi):
        assert isinstance(devre.hata_esigi, int)
        assert isinstance(devre.acik_kalma, (int, float))
        assert devre.hata_esigi == settings.CIRCUIT_FAILURE_THRESHOLD


# ==================================================================
# 5) Hangi hata DUSMEZ - kullanici hatalari aynen gitmeli
# ==================================================================
def test_bozuk_dosya_400_veriyor_502_degil():
    """W4-T15/B4: okunamayan dosya dis servis hatasi DEGIL."""
    with pytest.raises(InvalidImage) as bilgi:
        prepare_image(b"bu bir fotograf degil, duz metin")
    assert bilgi.value.status_code == 400
    assert not isinstance(bilgi.value, VisionError)   # dususe UGRAMAZ


def test_cok_buyuk_dosya_413_veriyor():
    from app.services.vision import ImageTooLarge

    with pytest.raises(ImageTooLarge) as bilgi:
        prepare_image(b"x" * (16 * 1024 * 1024))
    assert bilgi.value.status_code == 413


def test_gunluk_kota_hatasi_dis_servis_hatasi_degil():
    """Kota KASITLI sinir; sessizce dususe ugrarsa kullanici anlamaz."""
    hata = VisionDailyLimitExceeded()
    assert hata.status_code == 429
    assert not isinstance(hata, VisionError)


# ==================================================================
# 6) Kapatilan hatalarin nobeti (regresyon)
# ==================================================================
def test_b1_max_tokens_ayardan_okunuyor():
    """1024 SABIT yaziliydi; VISION_MAX_TOKENS olu ayardi."""
    govde = GroqVisionProvider()._govde(b"x", "prompt")
    assert govde["max_tokens"] == settings.VISION_MAX_TOKENS


def test_b2_kota_hata_kodu_dogru_yazilmis():
    """'cision_daily_limit' yazim hatasi istemcinin dallanmasini bozuyordu."""
    assert VisionDailyLimitExceeded.code == "vision_daily_limit"


def test_b3_router_ortak_istisna_siniflarini_kullaniyor():
    """routers/vision.py bu iki sinifi YENIDEN tanimliyordu."""
    from app.routers import vision as vision_router
    from app.services.vision import EmptyImage, UnsupportedImageType

    assert vision_router.UnsupportedImageType is UnsupportedImageType
    assert vision_router.EmptyImage is EmptyImage


def test_dusus_kapatilabiliyor(monkeypatch, bozuk_gorme):
    """DEGRADE_ON_PROVIDER_FAILURE=False -> eski davranis (hata firlat).

    Acil geri alma anahtari: sahada dusus beklenmedik bir sorun cikarirsa
    kod degistirmeden .env ile kapatilabilmeli.
    """
    monkeypatch.setattr(settings, "DEGRADE_ON_PROVIDER_FAILURE", False)
    db = SahteOturum()
    with pytest.raises(VisionError):
        asyncio.run(estimate_meal(db, None, raw_image=ornek_jpeg(), user_id=None))
