"""Kiler agirlikli tarif skorlama.

iki veri tabani problemi:
Kiler SQLite'ta, tarifler MongoDB'de. Mongo SQLite'a $lookup yapamaz.
Bu yuzden once SQLite'tan bir BAGLAM (ScoringContext) toplanip, bu baglam
Mongo pipeline'ina parametre olarak gomuluyor.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any, Sequence

from bson import ObjectId #BSON mongodbnin verileri kaydederken kullandığı binary json formatıdır | obejctId: bir veri kayıt ettığında ona otomatik 24 jarajter evrensel ılarak eşsizbi kimlik verir
from bson.errors import InvalidId #dışarıdan /arayüzden gelen metnin mongodb kuralına uymadığında  kullanılır
from motor.motor_asyncio import AsyncIOMotorDatabase #mongodbnin asenkron çalışan sürücüsü
from pymongo.errors import PyMongoError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import ExternalServiceError
from app.db.mongo_schema import RECIPE_COLLECTION
from app.models import Ingredient, PantryItem, User
from app.models.pantry import filter_confirmed, filter_unknown
from app.models.recipe import UserTasteWeight

logger = logging.getLogger(__name__)


# Bağlam
@dataclass(frozen=True, slots=True)
class ScoringContext:
    """Skorlama icin SQLite'tan toplanan her şey.
    Pipeline bu nesneden üretilir; böylece skorlama mantığı kullanıcıdan ve dbden bağımsız olarak test edilebilir.
    """
    var: tuple[str, ...] = ()              # availability='var' canonical adlar
    bilinmiyor: tuple[str, ...] = ()       # availability='bilinmiyor'
    diet_tags: tuple[str, ...] = ()        # kullanicinin beyan ettigi diyetler
    allergens: tuple[str, ...] = ()        # GUVENLIK KRITIK
    taste: tuple[dict[str, Any], ...] = () # [{dim, key, w}, ...]
    calorie_target: float = 650.0          # ogun basina
    target_minutes: int = 45
    max_calories: float | None = None   
    max_total_minutes: int | None = None   # sert tavan (opsiyonel)
    required_ingredients: tuple[str, ...] = ()
    excluded_ingredients: tuple[str, ...] = ()


def build_context(
    db: Session,
    user: User,
    *,
    max_calories: float | None = None,
    target_minutes: int | None = None,
    max_total_minutes: int | None = None,
    excluded_ingredients: Sequence[str] = (),
) -> ScoringContext:
    #Kullanıcının kilerini, kısıtlarını ve zevk vektörünü SQLite'tan toplar.
    hedef_dk = target_minutes or settings.SCORE_TARGET_MINUTES
    if max_total_minutes:
        # Sert tavan 30 dk iken 45 dk'yi 'ideal' saymak tutarsiz olurdu.
        hedef_dk = min(hedef_dk, max_total_minutes)

    var = tuple(db.scalars(
        select(Ingredient.canonical_name)
        .join(PantryItem, PantryItem.ingredient_id == Ingredient.id)
        .where(PantryItem.user_id == user.id, filter_confirmed())
    ))
    bilinmiyor = tuple(db.scalars(
        select(Ingredient.canonical_name)
        .join(PantryItem, PantryItem.ingredient_id == Ingredient.id)
        .where(PantryItem.user_id == user.id, filter_unknown())
    ))

    taste = tuple(
        {"dim": a.dimension.value, "key": a.taste_key, "w": float(a.weight)}
        for a in db.scalars(
            select(UserTasteWeight).where(UserTasteWeight.user_id == user.id)
        )
        if a.weight  # 0 agirlik pipeline'i şişirmesin
    )

    profil = user.profile
    gunluk = float(profil.daily_calorie_target) if profil else 2000.0
    ogun_basi = max(gunluk / max(settings.SCORE_MEALS_PER_DAY, 1), 1.0)

    ctx = ScoringContext(
        var=var,
        bilinmiyor=bilinmiyor,
        diet_tags=tuple(d.code for d in user.diet_tags),
        allergens=tuple(a.code for a in user.allergens),
        taste=taste,
        calorie_target=ogun_basi,
        target_minutes=hedef_dk,
        max_calories=max_calories,
        max_total_minutes=max_total_minutes,
        excluded_ingredients=tuple(excluded_ingredients),
    )
    logger.info(
        "Skorlama baglami | kullanici=%s var=%d bilinmiyor=%d diyet=%s alerjen=%s "
        "zevk=%d hedef=%.0f kcal",
        user.id, len(ctx.var), len(ctx.bilinmiyor), ctx.diet_tags,
        ctx.allergens, len(ctx.taste), ctx.calorie_target,
    )
    if ctx.excluded_ingredients:
        logger.info("Oturumda yok sayilan malzemeler: %s", ctx.excluded_ingredients)
    return ctx


# Pipeline
def _match_stage(ctx: ScoringContext, exclude_ids: Sequence[str]) -> dict:
    """Sert filtreler. SKORLAMADAN ÖNCE çalışır.

    Alerjen filtresi buraya konmalı; skora karıştırılsaydı çok yüksek
    kiler skorlu alerjenli bir tarif üst sıraya çıkabilirdi. Kabul kriteri
    'hiçbir koşulda dönmuyor' diyor - bunu ancak sert filtre garanti eder.
    """
    kosul: dict[str, Any] = {"is_active": {"$ne": False}}

    if ctx.allergens:
        # $nin: dizinin HICBIR elemani listede olmayacak. Alani hic
        # olmayan dokumanlar da gecer - dogrusu bu.
        kosul["allergens"] = {"$nin": list(ctx.allergens)}

    if ctx.diet_tags:
        # $all kullaniyoruz, $in degil. Kullanici hem vegan hem glutensizse
        # tarifin IKISINI birden tasimasi gerekir; $in "en az biri" der ve
        # vegan ama glutenli bir tarifi gecirirdi.
        kosul["diet_tags"] = {"$all": list(ctx.diet_tags)}

    if ctx.max_calories:
        kosul["calories_per_serving"] = {"$lte": float(ctx.max_calories)}

    if ctx.max_total_minutes:
        # prep_time + cook_time toplamı bir alan degil, bu yuzden $expr şart.
        # DİKKAT: $expr indeks kullanamaz. Tarif sayısı binlerle ölçüyken sorun degil; yuz binlere çıkarsa dökümana 'total_time' alanı eklenip indekslenmeli.
        kosul["$expr"] = {"$lte": [
            {"$add": [
                {"$ifNull": ["$prep_time", 0]},
                {"$ifNull": ["$cook_time", 0]},
            ]},
            float(ctx.max_total_minutes),
        ]}

    if exclude_ids:
        gecerli = []
        for i in exclude_ids:
            try:
                gecerli.append(ObjectId(i))
            except (InvalidId, TypeError):
                logger.warning("Gecersiz tarif kimligi atlandi: %r", i)
        if gecerli:
            kosul["_id"] = {"$nin": gecerli}

    if ctx.required_ingredients:
        kosul["ingredients.canonical_name"] = {"$in": list(ctx.required_ingredients)}

    if ctx.excluded_ingredients:
        kosul["$nor"] = [{
            "ingredients": {
                "$elemMatch" : {
                    "canonical_name": {"$in": list(ctx.excluded_ingredients)},
                    "optional": {"$ne": True},
                }
            }
        }]

    return {"$match": kosul}


def build_scoring_pipeline(
    ctx: ScoringContext,
    *,
    limit: int = 20,
    skip: int = 0,
    exclude_ids: Sequence[str] = (),
) -> list[dict]:
    """Skorlama pipeline'ini üretir. SAF: bağlantı kurmaz, sorgu çalıştırmaz."""
    bilinmiyor_agirlik = float(settings.PANTRY_UNKNOWN_WEIGHT)
    hedef_kcal = float(ctx.calorie_target)
    hedef_dk = float(ctx.target_minutes)

    return [
        _match_stage(ctx, exclude_ids),

        # --- 1) Tarifin ZORUNLU ve eşleştirilebilir malzemeleri ---------
        # canonical_name'i null olanlar sozlukte karsiligi olmayanlardir;
        # kiler eslestirmesine giremezler, paydayi da şişirmemeliler.
        # optional=true olanlar da paydaya girmez: 'isteğe bagli maydanoz'
        # yüzünden tarif düşük skor almamalı.
        {"$addFields": {
            "_zorunlu": {
                "$map": {
                    "input": {
                        "$filter": {
                            "input": {"$ifNull": ["$ingredients", []]},
                            "as": "m",
                            "cond": {"$and": [
                                {"$ne": [{"$ifNull": ["$$m.canonical_name", None]}, None]},
                                {"$ne": [{"$ifNull": ["$$m.optional", False]}, True]},
                            ]},
                        }
                    },
                    "as": "m",
                    "in": "$$m.canonical_name",
                }
            }
        }},

        # --- 2)Kiler Kesişimi
        {"$addFields": {
            "_var": {"$setIntersection": ["$_zorunlu", list(ctx.var)]},
            "_bilinmiyor": {"$setIntersection": ["$_zorunlu", list(ctx.bilinmiyor)]},
            # DIKKAT: $setIntersection sonucu TEKİLLEŞTİRİR. Payda da aynı sekilde tekillestirilmeli yoksa aynı malzemeyi iki satırda yazan bir tarif ederinden az puan alir.
            "_toplam": {"$size": {"$setUnion": ["$_zorunlu", []]}},
        }},
        {"$addFields": {
            "_eksik": {
                "$setDifference": [
                    {"$setUnion": ["$_zorunlu", []]},
                    {"$setUnion": ["$_var", "$_bilinmiyor"]},
                ]
            }
        }},

        # --- 3) Dört alt skor
        {"$addFields": {
            # KİLER: 'var' tam puan, 'bilinmiyor' kısmi puan
            "_s_kiler": {
                "$cond": [
                    {"$eq": ["$_toplam", 0]},
                    0.0,
                    {"$divide": [
                        {"$add": [
                            {"$size": "$_var"},
                            {"$multiply": [{"$size": "$_bilinmiyor"}, bilinmiyor_agirlik]},
                        ]},
                        "$_toplam",
                    ]},
                ]
            },

            # KALORI: iki yönlu ceza - çok düşük de çok yüksek de kötü
            "_s_kalori": {
                "$max": [0.0, {"$subtract": [1.0, {"$min": [1.0, {"$divide": [
                    {"$abs": {"$subtract": [
                        {"$ifNull": ["$calories_per_serving", hedef_kcal]}, hedef_kcal
                    ]}},
                    hedef_kcal,
                ]}]}]}]
            },

            # ZEVK: eslesen ogrenilmis agirliklarin ORTALAMASI.
            #
            # W4-T04 olcumu: eskiden bu bir TOPLAM'di ve asagida [-1,1]'e
            # kirpiliyordu. Bir tarifte cuisine + difficulty + diet_tag +
            # ~8 zorunlu malzeme eslestigi icin ham toplam rahatca 5-8'e
            # cikiyor, kirpma sonrasi 110 tarifin neredeyse hepsi 1.0
            # oluyordu: zevk bileseni her tarife SABIT +0.10 ekleyen bir
            # terime donusmustu, yani siralamayi hic degistirmiyordu
            # (Spearman 0.987, top-10'da sifir degisiklik).
            #
            # Ortalama iki sorunu birden cozer: kirpma devreye girmez
            # (agirliklar zaten [-1,1]) ve 40 malzemeli tarif 3 malzemeli
            # tarifi salt uzunlugu yuzunden ezemez.
            #
            # $literal sart: içerideki 'dim'/'key' anahtarları ifade olarak degil, düz veri olarak değerlendirilsin.
            "_zevk": {
                "$reduce": {
                    "input": {"$literal": list(ctx.taste)},
                    "initialValue": {"toplam": 0.0, "adet": 0},
                    "in": {"$cond": [
                        {"$or": [
                            {"$and": [
                                {"$eq": ["$$this.dim", "cuisine"]},
                                {"$eq": ["$$this.key", {"$ifNull": ["$cuisine", ""]}]},
                            ]},
                            {"$and": [
                                {"$eq": ["$$this.dim", "difficulty"]},
                                {"$eq": ["$$this.key", {"$ifNull": ["$difficulty", ""]}]},
                            ]},
                            {"$and": [
                                {"$eq": ["$$this.dim", "diet_tag"]},
                                {"$in": ["$$this.key", {"$ifNull": ["$diet_tags", []]}]},
                            ]},
                            {"$and": [
                                {"$eq": ["$$this.dim", "ingredient"]},
                                {"$in": ["$$this.key", "$_zorunlu"]},
                            ]},
                        ]},
                        {
                            "toplam": {"$add": ["$$value.toplam", "$$this.w"]},
                            "adet": {"$add": ["$$value.adet", 1]},
                        },
                        "$$value",
                    ]},
                }
            },

            "_sure_dk": {"$add": [
                {"$ifNull": ["$prep_time", 0]}, {"$ifNull": ["$cook_time", 0]}
            ]},
        }},

        {"$addFields": {
            # Hic eslesme yoksa 0 (notr); bolme hatasi da boylece olmaz.
            "_zevk_ham": {"$cond": [
                {"$eq": ["$_zevk.adet", 0]},
                0.0,
                {"$divide": ["$_zevk.toplam", "$_zevk.adet"]},
            ]},
        }},

        {"$addFields": {
            # -1..+1 aralığını 0..1'e taşi. Zevk verisi YOKKEN 0.5 (notr) çıkar eğer 0 verseydik yeni kullanıcı tüm tariflerde 0.20 kaybederdi.
            # Kirpma artik guvenlik agi: agirliklar [-1,1] oldugu icin
            # ortalamalari da oyle, ama bozuk veri skoru tasirmasin.
            "_s_zevk": {"$divide": [
                {"$add": [{"$max": [-1.0, {"$min": [1.0, "$_zevk_ham"]}]}, 1.0]}, 2.0
            ]},

            "_s_sure": {"$switch": {"branches": [
                # Süre bilgisi yoksa nötr puan; olmayan veriyi ödüllendirme.
                {"case": {"$lte": ["$_sure_dk", 0]}, "then": 0.5},
                {"case": {"$lte": ["$_sure_dk", hedef_dk]}, "then": 1.0},
            ], "default": {
                "$max": [0.0, {"$subtract": [1.0, {"$divide": [
                    {"$subtract": ["$_sure_dk", hedef_dk]}, hedef_dk * 2.0
                ]}]}]
            }}},
        }},

        # --- 4) Nihai skor
        {"$addFields": {
            "final_score": {"$round": [{"$add": [
                {"$multiply": [settings.SCORE_W_PANTRY, "$_s_kiler"]},
                {"$multiply": [settings.SCORE_W_CALORIE, "$_s_kalori"]},
                {"$multiply": [settings.SCORE_W_TASTE, "$_s_zevk"]},
                {"$multiply": [settings.SCORE_W_TIME, "$_s_sure"]},
            ]}, 4]}
        }},

        # _id ikincil siralama: eşit skorlu tariflerin sırası sayfalar arasında değişmesin, yoksa aynı tarif iki sayfada görünür.
        {"$sort": {"final_score": -1, "_id": 1}},
        {"$skip": int(skip)},
        {"$limit": int(limit)},

        # --- 5) Aciklanabilir çıktı
        {"$project": {
            "_id": 0,
            "id": {"$toString": "$_id"},
            "title": 1, "slug": 1, "image_url": 1,
            "calories_per_serving": 1, "servings": 1,
            "prep_time": 1, "cook_time": 1,
            "difficulty": 1, "cuisine": 1,
            "diet_tags": {"$ifNull": ["$diet_tags", []]},
            "allergens": {"$ifNull": ["$allergens", []]},
            "final_score": 1,
            # ACIKLANABILIRLIK: kullaniciya 'neden bu tarif' denebilsin geliştirici de sıralamayi elle doğrulayabilsin.
            "score_breakdown": {
                "pantry": {"$round": ["$_s_kiler", 4]},
                "calorie": {"$round": ["$_s_kalori", 4]},
                "taste": {"$round": ["$_s_zevk", 4]},
                # Zevk skoru kac ogrenilmis anahtardan hesaplandi. 0 ise
                # skor notr 0.5'tir; 'motor bu tarif hakkinda bir sey
                # bilmiyor' ile 'notr buluyor' ayirt edilebilsin.
                "taste_matched": {"$ifNull": ["$_zevk.adet", 0]},
                "time": {"$round": ["$_s_sure", 4]},
                "weights": {"$literal":{
                    "pantry": settings.SCORE_W_PANTRY,
                    "calorie": settings.SCORE_W_CALORIE,
                    "taste": settings.SCORE_W_TASTE,
                    "time": settings.SCORE_W_TIME,
                }},
            },
            "matched_ingredients": "$_var",
            "unknown_ingredients": "$_bilinmiyor",
            "missing_ingredients": "$_eksik",
            "total_required": "$_toplam",
        }},
    ]


# Calistirma
async def score_recipes(
    mongo_db: AsyncIOMotorDatabase,
    ctx: ScoringContext,
    *,
    limit: int = 20,
    skip: int = 0,
    exclude_ids: Sequence[str] = (),
) -> list[dict]:
    """Pipeline'ı çalıştırır ve skorlanmış tarif listesi döner."""
    pipeline = build_scoring_pipeline(
        ctx, limit=limit, skip=skip, exclude_ids=exclude_ids
    )
    try:
        imlec = mongo_db[RECIPE_COLLECTION].aggregate(pipeline)
        sonuclar = await imlec.to_list(length=limit)
    except PyMongoError as exc:
        logger.error("Tarif skorlama sorgusu başarısız: %s", exc)
        raise ExternalServiceError("Tarif önerileri şu anda üretilmiyor.") from exc

    logger.info(
        "Skorlama: %d tarif döndü | en yüksek=%.4f en düşük=%.4f",
        len(sonuclar),
        sonuclar[0]["final_score"] if sonuclar else 0,
        sonuclar[-1]["final_score"] if sonuclar else 0,
    )
    return sonuclar