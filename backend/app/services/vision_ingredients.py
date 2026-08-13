"""foto -> malzeme çıkarma iş akışı
router ince kalsın diye tüm iş mantığı burada: kota kontrolü, model çağrısı, yanıt ayrıştırma, sözlük eşleştirme, kayıt
"""
from __future__ import annotations
import logging
from datetime import date
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.exceptions import AppError
from app.models import VisionRequest, VisionRequestType
from app.schemas import DetectedIngredient
from app.services.ingredient_matcher import match_ingredients
from app.services.vision import (
    VisionInvalidResponse, get_vision_provider, prepare_image,
)
from app.services.vision_log import log_vision_call

logger = logging.getLogger(__name__)

class VisionDailyLimitExceeded(AppError):
    status_code = 429
    code = "cision_daily_limit"
    message = "Bugünlük foto hakkın doldu, yarın tekrar dene !"

INGREDIENT_PROMPT = """Bu fotograftaki YENILEBILIR malzemeleri listele.

Kurallar:
1. Sadece yenilebilir gida maddelerini yaz. Kap, catal, bicak, tabak, kase, ambalaj,
   deterjan gibi yenmeyen nesneleri YAZMA.
2. Ambalajli urunlerde marka adini degil ICINDEKI gidayi yaz.
   ("Sutas Yogurt 1kg" degil -> "yogurt")
3. Malzeme adlarini Turkce, tekil ve sade yaz. ("domatesler" degil -> "domates")
4. FOTOGRAFTA GORMEDIGIN hicbir seyi ekleme. Tipik bir buzdolabinda ne
   bulunacagini TAHMIN ETME.
5. Emin olmadiklarini listeden CIKARMA, dusuk confidence ile isaretle.
   confidence 0.0 ile 1.0 arasi ondalik bir sayidir:
     0.9+ = net gorunuyor ve ne oldugu kesin
     0.5-0.9 = gorunuyor ama tam emin degilim
     0.5 alti = bulanik / kismen kapali / tahmin
6. En fazla 15 malzeme yaz, en belirginden baslayarak.

Yanitini SADECE su JSON nesnesi olarak, TEK SATIRDA, girintisiz ver.
Aciklama, markdown blogu veya baska hicbir metin ekleme:
{"items":[{"name":"domates","confidence":0.95},{"name":"yogurt","confidence":0.62}]}
"""

# Model yanıtını ayrıştırma
_LISTE_ANAHTARLARI = ("items", "ingredients", "malzemeler", "results", "data")
_AD_ANAHTARLARI = ("name", "ad", "raw_name", "ingredient", "malzeme", "label", "item")
_GUVEN_ANAHTARLARI = ("confidence", "guven", "score", "certainty", "probability")

def _guveni_normalize_et(deger) -> float:
    """0-100 aralığını 0-1e katlar. 2'den büyük değerler yüzde olarak yorumlanır."""
    try:
        sayi = float(deger)
    except (TypeError, ValueError):
        return 0.5
    if sayi > 2.0:
        sayi = sayi / 100.0
    return round(min(max(sayi, 0.0), 1.0), 3)

def _ham_listeyi_cikar(data:dict) -> list[tuple[str, float]]:
    """VisionResult.data -> [(ham_ad, confidence)]
    aynı ad brden fazla gelirse en yüksek confidence korunur"""
    liste = None
    for anahtar in _LISTE_ANAHTARLARI:
        deger = data.get(anahtar)
        if isinstance(deger, list):
            liste = deger 
            break
    if liste is None: 
        degerler = [v for v in data.values() if isinstance(v, list)]
        liste = degerler[0] if len(degerler) == 1 else []

    toplanan: dict[str, tuple[str, float]] = {}
    for oge in liste:
        if isinstance(oge, str):
            ad, guven = oge, 0.5
        elif isinstance(oge, dict):
            ad = next(
                (str(oge[k]) for k in _AD_ANAHTARLARI if oge.get(k)), None
            )
            guven = _guveni_normalize_et(
                next((oge[k] for k in _GUVEN_ANAHTARLARI if k in oge), None)
            )
        else:
            continue

        if not ad or not ad.strip():
            continue

        anahtar = ad.strip().lower()
        mevcut = toplanan.get(anahtar)
        if mevcut is None or guven > mevcut[1]:
            toplanan[anahtar] = (ad.strip(), guven)

    return list(toplanan.values())


# Kota
def gunluk_kotayi_kontrol_et(db: Session, user_id: int) -> None:
    """Maliyet koruması: başarısız çağrılar da sayılır"""
    limit = settings.VISION_DAILY_LIMIT_PER_USER
    if limit <= 0:
        return
    adet = db.scalar(
        select(func.count(VisionRequest.id)).where(
            VisionRequest.user_id == user_id,
            func.date(VisionRequest.created_at) == date.today().isoformat(),
        )
    ) or 0
    if adet >= limit:
        logger.warning("Kullanici %s gunluk gorme kotasini doldurdu (%d).", user_id, adet)
        raise VisionDailyLimitExceeded()


# Ana akış
async def detect_ingredients(
    db: Session,
    *,
    raw_image: bytes,
    user_id: int | None,
) -> list[DetectedIngredient]:
    """Fotoğraftan malzeme listesi çıkarır ve sözlükle eşleştirir."""
    if user_id is not None:
        gunluk_kotayi_kontrol_et(db, user_id)

    islenmis, ozet = prepare_image(raw_image)
    saglayici = get_vision_provider()

    try:
        sonuc = await saglayici.analyze(islenmis, INGREDIENT_PROMPT)
    except AppError as exc:
        # Basarisiz cagri da kaydedilir: hata orani maliyet analizinin parcasi
        log_vision_call(
            db,
            request_type=VisionRequestType.MALZEME,
            image_hash=ozet,
            error_code=getattr(exc, "code", "vision_error"),
            user_id=user_id,
            image_bytes=len(islenmis),
            provider=saglayici.name,
        )
        raise

    ham_liste = _ham_listeyi_cikar(sonuc.data)
    if not ham_liste:
        logger.warning("Görme modeli boş liste döndürdü. Ham yanıt: %s", sonuc.raw_text[:300])
        log_vision_call(
            db,
            request_type=VisionRequestType.MALZEME,
            image_hash=ozet,
            error_code="vision_empty_result",
            user_id=user_id,
            image_bytes=len(islenmis),
            provider=saglayici.name,
        )
        raise VisionInvalidResponse(
            "Fotoğrafta tanıdığım bir nesne göremedim. Daha yakından çekip dener misin?"
        )

    eslesmeler = match_ingredients(db, ham_liste, source="vision")

    # Cok dusuk guvenli sonuclar onay ekranini kirletiyor.
    eslesmeler = [m for m in eslesmeler if m.confidence >= settings.VISION_MIN_CONFIDENCE]
    eslesmeler.sort(key=lambda m: m.confidence, reverse=True)
    eslesmeler = eslesmeler[: settings.VISION_MAX_ITEMS]

    eslesen = sum(1 for m in eslesmeler if m.canonical_name)
    kayit = log_vision_call(
        db,
        request_type=VisionRequestType.MALZEME,
        image_hash=ozet,
        result=sonuc,
        user_id=user_id,
    )
    kayit.matched_count = eslesen
    kayit.unmatched_count = len(eslesmeler) - eslesen
    db.commit()

    logger.info(
        "Fotoğraf analizi: %d ham -> %d sonuç (%d eşleşti, %d eşleşmedi) | yöntemler=%s",
        len(ham_liste), len(eslesmeler), eslesen, len(eslesmeler) - eslesen,
        {m.matched_by for m in eslesmeler},
    )

    return [
        DetectedIngredient(
            raw_name=m.raw_name,
            canonical_name=m.canonical_name,
            display_name=m.display_name,
            confidence=m.confidence,
        )
        for m in eslesmeler
    ]