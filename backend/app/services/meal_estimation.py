"""Fotograftan öğün ve kalori tahmini.

KALORİ KAYNAGI SORUNU:
Kullanıcı tabağında 'domates' görmüyor, 'menemen' görüyor. ingredients tablosunda yemek yok (170 satirin hepsi ham malzeme), products tablosu boş. Köprü MongoDB'deki recipes koleksiyonu: tarif başlığı yemek adıyla, tarifin malzemeleri canonical_name ile ingredients tablosuyla eşleşiyor.

    yemek adi -> tarif -> malzemeler -> ingredients.calories_per_100g

DIKKAT: Bu uç HİÇBİR şEY YAZMAZ. Yanıt 'tahmin' olarak işaretlenir ve
kullanıcı onayı beklenir; öğün kaydı W2-T12'de yazılaca.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass

from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import PyMongoError
from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError
from app.db.mongo_schema import RECIPE_COLLECTION
from app.models import Ingredient, Product, VisionRequestType
from app.models.enums import PortionSize
from app.services.ingredient_matcher import get_lookup, match_name
from app.services.unit_service import (
    UnitConversionError, normalize_text, raw_to_cooked, to_grams,
)
from app.services.vision import (
    VisionInvalidResponse, get_vision_provider, prepare_image,
)
from app.services.vision_ingredients import (
    _guveni_normalize_et, gunluk_kotayi_kontrol_et,
)
from app.services.vision_log import log_vision_call

logger = logging.getLogger(__name__)


# Sistem promptu
# Dikkat: Bu metin '"items"' ICERMEMELI. FakeVisionProvider hangi sahte yaniti donecegine prompt'ta '"items"' arayarak karar veriyor; gecerse malzeme listesi doner ve ogun akisi coker.

MEAL_PROMPT = """Bu fotograftaki tabakta ne yemek oldugunu tani.

Kurallar:
1. Yemegin YAYGIN TURKCE adini yaz. Marka veya restoran adi yazma.
   ("Ali Usta Iskender" degil -> "iskender")
2. OLCEK REFERANSI: tabagin yanindaki catal, kasik, bicak veya bardagi
   kullanarak porsiyon buyuklugunu tahmin et. Standart bir yemek catali
   yaklasik 19 cm, cay bardagi yaklasik 9 cm yuksekligindedir.
   Boyle bir referans bulduysan scale_reference_found alanini true yap.
3. portion alani yalnizca su uc degerden biri olabilir:
   "kucuk", "orta", "buyuk"
4. estimated_grams: tabaktaki YENEBILIR icerigin gram cinsinden agirligi.
   Tabagin, catalin, kagit peceteninkini SAYMA.
5. Emin degilsen tahmin etmekten kacinma, dusuk confidence ver.
   confidence 0.0 ile 1.0 arasi ondalik bir sayidir.
6. notes alanina tahminini neye dayandirdigini bir cumleyle yaz.

Yanitini SADECE su JSON nesnesi olarak, TEK SATIRDA, girintisiz ver.
Aciklama veya markdown blogu ekleme:
{"dish_name":"mercimek corbasi","portion":"orta","estimated_grams":250,"confidence":0.78,"scale_reference_found":true,"notes":"Kase yaninda yemek kasigi goruldu."}
"""

_AD_ANAHTARLARI = ("dish_name", "yemek_adi", "name", "dish", "food", "yemek")
_PORSIYON_ANAHTARLARI = ("portion", "porsiyon", "portion_size", "size")
_GRAM_ANAHTARLARI = ("estimated_grams", "grams", "gram", "tahmini_gram", "weight_g")

_PORSIYON_ESLEME = {
    "kucuk": PortionSize.KUCUK, "küçük": PortionSize.KUCUK,
    "small": PortionSize.KUCUK, "az": PortionSize.KUCUK,
    "orta": PortionSize.ORTA, "medium": PortionSize.ORTA, "normal": PortionSize.ORTA,
    "buyuk": PortionSize.BUYUK, "büyük": PortionSize.BUYUK,
    "large": PortionSize.BUYUK, "big": PortionSize.BUYUK, "cok": PortionSize.BUYUK,
}


def porsiyon_gramlari() -> dict[PortionSize, float]:
    return {
        PortionSize.KUCUK: settings.MEAL_GRAMS_SMALL,
        PortionSize.ORTA: settings.MEAL_GRAMS_MEDIUM,
        PortionSize.BUYUK: settings.MEAL_GRAMS_LARGE,
    }


# Model yanitini ayristirma
@dataclass(frozen=True, slots=True)
class MealGuess:
    """Modelin ham tahmini henüz kalori yok."""
    dish_name: str
    portion: PortionSize
    estimated_grams: float
    confidence: float
    scale_reference_found: bool
    notes: str | None


def _porsiyonu_coz(deger, gram: float | None) -> PortionSize:
    """Etiketi enum'a çevirir; etiket yoksa gramdan geri türetir."""
    if isinstance(deger, str):
        if (p := _PORSIYON_ESLEME.get(deger.strip().lower())) is not None:
            return p
    if gram:
        esikler = porsiyon_gramlari()
        if gram <= (esikler[PortionSize.KUCUK] + esikler[PortionSize.ORTA]) / 2:
            return PortionSize.KUCUK
        if gram <= (esikler[PortionSize.ORTA] + esikler[PortionSize.BUYUK]) / 2:
            return PortionSize.ORTA
        return PortionSize.BUYUK
    return PortionSize.ORTA


def parse_meal_response(data: dict) -> MealGuess:
    """VisionResult.data -> MealGuess. Anahtar sapmalarına toleranslı."""
    ad = next((str(data[k]).strip() for k in _AD_ANAHTARLARI if data.get(k)), None)
    if not ad:
        raise VisionInvalidResponse(
            "Fotoğrafta tanıdığım bir yemek göremedim. Tabağı tam kadraja al."
        )

    ham_gram = next((data[k] for k in _GRAM_ANAHTARLARI if data.get(k)), None)
    try:
        gram = float(ham_gram) if ham_gram is not None else None
    except (TypeError, ValueError):
        gram = None
    if gram is not None and not (10 <= gram <= 3000):
        # 3 kg'lik bir tabak yok; model halusinasyon gormus.
        logger.warning("Saçma gram tahmini yok sayıldı: %s", gram)
        gram = None

    porsiyon = _porsiyonu_coz(
        next((data[k] for k in _PORSIYON_ANAHTARLARI if data.get(k)), None), gram
    )
    if gram is None:
        gram = porsiyon_gramlari()[porsiyon]

    return MealGuess(
        dish_name=ad[:200],
        portion=porsiyon,
        estimated_grams=round(gram, 1),
        confidence=_guveni_normalize_et(data.get("confidence")),
        scale_reference_found=bool(data.get("scale_reference_found", False)),
        notes=(str(data["notes"])[:300] if data.get("notes") else None),
    )


# Kalori cozumleme
@dataclass(frozen=True, slots=True)
class CalorieSource:
    """Kalori bilgisinin nereden geldiği ve ne kadar guvenilir olduğu."""
    kcal_per_100g: float | None
    protein_100g: float = 0.0
    carb_100g: float = 0.0
    fat_100g: float = 0.0
    source: str = "none"          # recipe | ingredient | product | none
    matched_id: str | None = None
    matched_name: str | None = None
    match_score: float = 0.0
    confidence: float = 0.0


# Tarif basliklari nadiren degisir; her istekte 110 dokuman cekmeyelim.
_baslik_onbellek: tuple[float, dict[str, dict]] | None = None
_ONBELLEK_SURESI = 300


async def _tarif_basliklari(mongo_db: AsyncIOMotorDatabase) -> dict[str, dict]:
    """{normalize(baslik): tarif_ozeti} tablosu."""
    global _baslik_onbellek
    simdi = time.monotonic()
    if _baslik_onbellek and simdi - _baslik_onbellek[0] < _ONBELLEK_SURESI:
        return _baslik_onbellek[1]

    imlec = mongo_db[RECIPE_COLLECTION].find(
        {"is_active": {"$ne": False}},
        projection={"title": 1, "servings": 1, "calories_per_serving": 1,
                    "ingredients": 1, "macros": 1},
    )
    tablo = {}
    async for tarif in imlec:
        if anahtar := normalize_text(tarif.get("title", "")):
            tablo.setdefault(anahtar, tarif)

    _baslik_onbellek = (simdi, tablo)
    logger.info("Tarif başlığı önbelleği yenilendi: %d başlık", len(tablo))
    return tablo


def clear_title_cache() -> None:
    global _baslik_onbellek
    _baslik_onbellek = None


def _tarifin_pismis_grami(db: Session, tarif: dict) -> float:
    """Tarifin tamamının pişmiş ağırlığı.

    NEDEN PİŞMİŞ: tarifin malzeme toplamı CIG gramdir. 100 g pirinçten
    280 g pilav olur. Çiğ toplam uzerinden kcal/100g hesaplarsan
    tabaktaki pilava üçte bir ağırlık biçip kaloriyi 3 katına çıkarırsın.
    cooked_yield_factor tam bu iş için var.
    """
    kanonikler = [
        m["canonical_name"] for m in tarif.get("ingredients", [])
        if m.get("canonical_name")
    ]
    if not kanonikler:
        return 0.0

    bilgi = {
        i.canonical_name: i for i in db.scalars(
            select(Ingredient).where(Ingredient.canonical_name.in_(kanonikler))
        )
    }

    toplam = 0.0
    for malzeme in tarif.get("ingredients", []):
        kanonik = malzeme.get("canonical_name")
        kayit = bilgi.get(kanonik) if kanonik else None
        try:
            cig = to_grams(
                malzeme.get("quantity"),
                malzeme.get("unit"),
                grams_per_piece=kayit.grams_per_piece if kayit else None,
                ml_to_gram=kayit.ml_to_gram_factor if kayit else None,
            )
        except UnitConversionError as exc:
            # 'tuz, karabiber' gibi miktarsız satırlar; toplam gramı kayda deger ölçüde etkilemezler
            logger.debug("Birim cevrilemedi (%s): %s", kanonik, exc)
            continue
        toplam += raw_to_cooked(cig, kayit.cooked_yield_factor if kayit else None)

    return toplam


async def resolve_calories(
    db: Session, mongo_db: AsyncIOMotorDatabase | None, dish_name: str
) -> CalorieSource:
    """Yemek adından 100 g başına besin değerini bulur.
    Zincir: tarif -> malzeme -> urun -> yok. İlk tutan kazanir.
    """
    norm = normalize_text(dish_name)

    #1) Tarif başlığı 
    if mongo_db is not None and norm:
        try:
            basliklar = await _tarif_basliklari(mongo_db)
        except PyMongoError as exc:
            logger.warning("Tarif başlıkları okunamadı: %s", exc)
            basliklar = {}

        if basliklar:
            adaylar = process.extract(
                norm, list(basliklar), scorer=fuzz.token_set_ratio,
                limit=5, score_cutoff=settings.MEAL_TITLE_MATCH_TREASHOLD,
            )
            if adaylar:
                # token_set_ratio girdiyi iceren her basliga 100 verir token_sort_ratio ile ayiriyoruz.
                anahtar, skor, _ = max(
                    adaylar, key=lambda a: (a[1], fuzz.token_sort_ratio(norm, a[0]))
                )
                tarif = basliklar[anahtar]
                pismis = _tarifin_pismis_grami(db, tarif)
                toplam_kcal = (
                    float(tarif.get("calories_per_serving") or 0)
                    * int(tarif.get("servings") or 1)
                )
                if pismis > 50 and toplam_kcal > 0:
                    oran = 100.0 / pismis
                    makro = tarif.get("macros") or {}
                    porsiyon = int(tarif.get("servings") or 1)
                    return CalorieSource(
                        kcal_per_100g=round(toplam_kcal * oran, 2),
                        protein_100g=round(
                            float(makro.get("protein_g") or 0) * porsiyon * oran, 2),
                        carb_100g=round(
                            float(makro.get("carb_g") or 0) * porsiyon * oran, 2),
                        fat_100g=round(
                            float(makro.get("fat_g") or 0) * porsiyon * oran, 2),
                        source="recipe",
                        matched_id=str(tarif["_id"]),
                        matched_name=tarif.get("title"),
                        match_score=float(skor),
                        # Tarif dolayımlı tahmin: skorla orantılı ama tavanı 0.85 - tarifin porsiyonu kullanicinin tabagi degil.
                        confidence=round(min(skor / 100.0, 1.0) * 0.85, 3),
                    )
                logger.info(
                    "Tarif '%s' eslesti ama gramaj hesaplanamadi (pismis=%.0f g).",
                    tarif.get("title"), pismis,
                )

    # 2) Dogrudan malzeme ('elma', 'muz', 'makarna')
    eslesme = match_name(dish_name, get_lookup(db))
    if eslesme.canonical_name:
        malzeme = db.scalar(
            select(Ingredient).where(
                Ingredient.canonical_name == eslesme.canonical_name
            )
        )
        if malzeme and malzeme.calories_per_100g:
            return CalorieSource(
                kcal_per_100g=float(malzeme.calories_per_100g),
                protein_100g=float(malzeme.protein_per_100g or 0),
                carb_100g=float(malzeme.carb_per_100g or 0),
                fat_100g=float(malzeme.fat_per_100g or 0),
                source="ingredient",
                matched_id=str(malzeme.id),
                matched_name=malzeme.display_name,
                match_score=eslesme.score,
                confidence=round(min(eslesme.score / 100.0, 1.0) * 0.75, 3),
            )

    # 3) Urun katalogu (barkod) 
    urun = db.scalar(
        select(Product).where(Product.name.ilike(f"%{dish_name.strip()}%"))
        .where(Product.calories_per_100g.isnot(None))
        .limit(1)
    )
    if urun:
        return CalorieSource(
            kcal_per_100g=float(urun.calories_per_100g),
            protein_100g=float(urun.protein_per_100g or 0),
            carb_100g=float(urun.carb_per_100g or 0),
            fat_100g=float(urun.fat_per_100g or 0),
            source="product",
            matched_id=str(urun.id),
            matched_name=urun.name,
            match_score=100.0,
            confidence=0.7,
        )

    # 4) Bulunamadı
    logger.info("'%s' icin kalori kaynagi bulunamadi.", dish_name)
    return CalorieSource(kcal_per_100g=None)


# Ana akış
async def estimate_meal(
    db: Session,
    mongo_db: AsyncIOMotorDatabase | None,
    *,
    raw_image: bytes,
    user_id: int | None,
) -> dict:
    """Tabak fotoğrafından yemek + porsiyon + kalori tahmini üretir."""
    if user_id is not None:
        gunluk_kotayi_kontrol_et(db, user_id)

    islenmis, ozet = prepare_image(raw_image)
    saglayici = get_vision_provider()

    try:
        sonuc = await saglayici.analyze(islenmis, MEAL_PROMPT)
    except AppError as exc:
        log_vision_call(
            db, request_type=VisionRequestType.OGUN, image_hash=ozet,
            error_code=getattr(exc, "code", "vision_error"),
            user_id=user_id, image_bytes=len(islenmis), provider=saglayici.name,
        )
        raise

    try:
        tahmin = parse_meal_response(sonuc.data)
    except AppError as exc:
        logger.warning("Öğün yanıtı ayrıştırılamadı: %s", sonuc.raw_text[:300])
        log_vision_call(
            db, request_type=VisionRequestType.OGUN, image_hash=ozet,
            error_code=getattr(exc, "code", "vision_invalid_response"),
            user_id=user_id, image_bytes=len(islenmis), provider=saglayici.name,
        )
        raise

    kaynak = await resolve_calories(db, mongo_db, tahmin.dish_name)

    def kalori(gram: float) -> float | None:
        if kaynak.kcal_per_100g is None:
            return None
        return round(kaynak.kcal_per_100g * gram / 100.0, 1)

    def makro(deger: float, gram: float) -> float:
        return round(deger * gram / 100.0, 1)

    gram = tahmin.estimated_grams
    kayit = log_vision_call(
        db, request_type=VisionRequestType.OGUN, image_hash=ozet,
        result=sonuc, user_id=user_id,
    )
    kayit.matched_count = 1 if kaynak.kcal_per_100g is not None else 0
    kayit.unmatched_count = 0 if kaynak.kcal_per_100g is not None else 1
    db.commit()

    logger.info(
        "Ogun tahmini | yemek='%s' porsiyon=%s gram=%.0f kcal=%s kaynak=%s "
        "model_guven=%.2f kalori_guven=%.2f olcek=%s",
        tahmin.dish_name, tahmin.portion.value, gram, kalori(gram),
        kaynak.source, tahmin.confidence, kaynak.confidence,
        tahmin.scale_reference_found,
    )

    return {
        "dish_name": tahmin.dish_name,
        "portion": tahmin.portion,
        "estimated_grams": gram,
        "confidence": tahmin.confidence,
        "scale_reference_found": tahmin.scale_reference_found,
        "notes": tahmin.notes,

        "calories": kalori(gram),
        "calorie_confidence": kaynak.confidence,
        "macros": {
            "protein_g": makro(kaynak.protein_100g, gram),
            "carb_g": makro(kaynak.carb_100g, gram),
            "fat_g": makro(kaynak.fat_100g, gram),
            "fiber_g": 0.0,
        } if kaynak.kcal_per_100g is not None else None,

        "match_source": kaynak.source,
        "matched_id": kaynak.matched_id,
        "matched_name": kaynak.matched_name,
        "match_score": kaynak.match_score,

        # Onay ekranı porsiyonu değiştirince yeni istek atmasın.
        "portion_options": [
            {"portion": p, "grams": g, "calories": kalori(g)}
            for p, g in porsiyon_gramlari().items()
        ],

        # Önemli: bu bir tahmindir, kayıt değil.
        "is_estimate": True,
        "requires_confirmation": True,
        "needs_manual_entry": kaynak.kcal_per_100g is None,
        "image_hash": ozet,
    }