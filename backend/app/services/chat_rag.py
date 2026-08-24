"""Chatbot RAG orkestrasyonu

RAG'ın özü: LLM'e 'bir tarif öner' denmiyor. Once SQLite (kiler, profil,
diyet, alerjen) ve MongoDB'den gerçek yemek adayları çekiliyor LLM SADECE bu adaylar arasından seçim yapıyor. 
Dönen tarif kimlikleri adaylarin dışında kaldiysa sunucu tarafında elenir bu sayede model ne derse desin uydurma bir tarif kullanıcıya  gitmez.

Akış:
    1) extract_intent()    : mesajdan niyet cikartır (SAF fonksiyon)
    2) build_candidates()  : SQLite+Mongo'dan 5-8 gercek aday getir
    3) build_prompt()      : kompakt JSON baglam olustur
    4) LLM cagrisi
    5) parse_and_validate(): LLM ciktisini aday kumesiyle kesiştirir
"""
from __future__ import annotations

import hashlib
import json
import logging
import re
from dataclasses import dataclass, replace
from datetime import datetime, timedelta, timezone
from typing import Sequence

from motor.motor_asyncio import AsyncIOMotorDatabase
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError, PermissionDeniedError
from app.models import ChatConversation, ChatMessage, LlmCache, User
from app.models.enums import ChatRole
from app.models.recipe import ids_permanently_disliked
from app.services.chat import ADAYLAR_BASI, ADAYLAR_SONU, get_chat_provider
from app.services.ingredient_matcher import IngredientLookup, get_lookup, match_name
from app.services.recipe_scoring import build_context, score_recipes
from app.services.unit_service import normalize_text
from app.schemas import DetectedIngredient
from app.services.vision_ingredients import detect_ingredients

logger = logging.getLogger(__name__)


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class ChatDailyLimitExceeded(AppError):
    status_code = 429
    code = "chat_daily_limit"
    message = "Bugunluk sohbet hakkin doldu. Yarin tekrar dene."


# 1) Niyet çıkarma - SAF Fonksiyon | keşke gerçekte de kişiliğe atanmış böyle bi fonksiyonum olsaydı
LIGHT_PHRASES = ("hafif", "az kalorili", "dusuk kalorili", "diyetlik")
HEAVY_PHRASES = ("doyurucu", "yogun kalorili", "bol kalorili")

_SAAT_DESENI = re.compile(r"(\d{1,2})\s*saat")
_DAKIKA_DESENI = re.compile(r"(\d{1,3})\s*(?:dk|dak)")
_SURE_SOZCUKLERI = {"yarim saat": 30, "ceyrek saat": 15, "hizli": 20, "cabuk": 20}


@dataclass(frozen=True, slots=True)
class ChatIntent:
    raw_message: str
    calorie_ratio: float | None = None          # 0.7 hafif, 1.3 doyurucu
    max_total_minutes: int | None = None
    mentioned_ingredients: tuple[str, ...] = ()  # canonical adlar


def _sureyi_coz(norm_mesaj: str) -> int | None:
    if m := _DAKIKA_DESENI.search(norm_mesaj):
        return int(m.group(1))
    if m := _SAAT_DESENI.search(norm_mesaj):
        return int(m.group(1)) * 60
    for kelime, dakika in _SURE_SOZCUKLERI.items():
        if kelime in norm_mesaj:
            return dakika
    return None


def _malzemeleri_bul(norm_mesaj: str, lookup: IngredientLookup) -> tuple[str, ...]:
    """Mesajdaki malzeme adlarını sözlükle eşleştirir.

    Yalnızca kesin eşleşmeler (canonical/alias) kabul edilir; fuzzy
    KULLANILMAZ.
    """
    _EKLER = ("li", "lu", "lı", "lü", "da", "de", "ta", "te", "ca", "ce", "la", "le", "yla", "yle", "dan", "den")

    bulunan: list[str] = []
    kelimeler = norm_mesaj.split()
    adaylar = list(kelimeler) + [f"{a} {b}" for a, b in zip(kelimeler, kelimeler[1:])]

    # Her aday için hem orijinal hem de ek soyulmuş halleri dene
    genisletilmis: list[str] = []
    for aday in adaylar:
        genisletilmis.append(aday)
        for ek in _EKLER:
            if aday.endswith(ek) and len(aday) - len(ek) >= 4:
                genisletilmis.append(aday[: -len(ek)])

    for aday in genisletilmis:
        if len(aday) < 4:
            continue
        sonuc = match_name(aday, lookup)
        if sonuc.canonical_name and sonuc.matched_by in ("canonical", "alias", "canonical_ek"):
            if sonuc.canonical_name not in bulunan:
                bulunan.append(sonuc.canonical_name)

    return tuple(bulunan)


def extract_intent(message: str, lookup: IngredientLookup) -> ChatIntent:
    """Serbest metin mesajdan niyet ve kısıtları çıkarır. Saf fonksiyon."""
    norm = normalize_text(message)

    oran = None
    if any(p in norm for p in LIGHT_PHRASES):
        oran = 0.7
    elif any(p in norm for p in HEAVY_PHRASES):
        oran = 1.3

    return ChatIntent(
        raw_message=message.strip(),
        calorie_ratio=oran,
        max_total_minutes=_sureyi_coz(norm),
        mentioned_ingredients=_malzemeleri_bul(norm, lookup),
    )


# 2) Aday getirme
async def build_candidates(
    db: Session, mongo_db: AsyncIOMotorDatabase, user: User, intent: ChatIntent,
) -> tuple[list[dict], list[str]]:
    """SQLite+Mongo'dan gerçek adayları getirir.
    Döner: (adaylar, uygulanan_filtreler). uygulanan_filtreler SUNUCU
    TARAFINDA üretilir.
    """
    filtreler: list[str] = []

    profil = user.profile
    gunluk = float(profil.daily_calorie_target) if profil else 2000.0
    hedef_ogun = max(gunluk / settings.SCORE_MEALS_PER_DAY, 1.0)

    max_kalori = None
    if intent.calorie_ratio is not None:
        max_kalori = round(hedef_ogun * intent.calorie_ratio, 0)
        etiket = "hafif" if intent.calorie_ratio < 1 else "doyurucu"
        filtreler.append(f"{etiket} (<= {max_kalori:.0f} kcal)")

    if intent.max_total_minutes:
        filtreler.append(f"toplam sure <= {intent.max_total_minutes} dk")

    # W2-T07'nin kalici eleme kurali: bu sohbette de 'sevmedim' denenler donmez.
    disliked = tuple(db.scalars(ids_permanently_disliked(user.id)))

    ctx = build_context(
        db, user, max_calories=max_kalori, max_total_minutes=intent.max_total_minutes,
    )

    if intent.mentioned_ingredients:
        ctx_ile = replace(ctx, required_ingredients=intent.mentioned_ingredients)
        adaylar = await score_recipes(
            mongo_db, ctx_ile, limit=settings.CHAT_MAX_CANDIDATES, exclude_ids=disliked,
        )
        if adaylar:
            filtreler.append("malzeme: " + ", ".join(intent.mentioned_ingredients))
            return adaylar, filtreler
        logger.info(
            "'%s' içeren aday bulunamadı, malzeme filtresi gevşetildi.",
            intent.mentioned_ingredients,
        )

    adaylar = await score_recipes(
        mongo_db, ctx, limit=settings.CHAT_MAX_CANDIDATES, exclude_ids=disliked,
    )
    return adaylar, filtreler


# 3) Prompt olusturma
def build_prompt(
    intent: ChatIntent,
    candidates: list[dict],
    detected_names: Sequence[str] = (),
) -> tuple[str, str]:
    kompakt = [
        {
            "id": c["id"],
            "title": c["title"],
            "calories_per_serving": c["calories_per_serving"],
            "total_minutes": (c.get("prep_time") or 0) + (c.get("cook_time") or 0),
            "matched_ingredients": c.get("matched_ingredients", []),
            "missing_ingredients": (c.get("missing_ingredients") or [])[:5],
        }
        for c in candidates
    ]
    aday_json = json.dumps({"adaylar": kompakt}, ensure_ascii=False)

    # Foto varsa gorme modelinin bulduklari LLM'e VERILIR. Bu satir
    # olmadan model fotografta ne oldugunu bilemez ve 'taniyamiyorum' der.
    foto_notu = ""
    if detected_names:
        liste = ", ".join(detected_names)
        foto_notu = (
            f'\nKullanicinin GONDERDIGI FOTOGRAFTA su malzemeler goruldu: '
            f'{liste}.\nBu malzemeleri KULLANARAK yapilabilecek adaylari one '
            f'cikar ve mesajinda bu malzemelere deginebilirsin.\n'
        )

    system_prompt = (
        "Sen bir yemek tarifi onerme asistanisin. SADECE sana verilen aday "
        "listesinden secim yapabilirsin. Listede OLMAYAN hicbir tarifi "
        "ONERME veya UYDURMA. Adaylarin hicbiri istege tam uymuyorsa en "
        "yakin olanlari sec ve bunu mesajinda belirt. Turkce, samimi ve "
        "KISA (en fazla 2 cumle) yaz.\n\n"
        'Yanitini SADECE su JSON nesnesi olarak, TEK SATIRDA ver: '
        '{"mesaj": "...", "onerilen_tarif_idleri": ["<id>", ...]}\n'
        "onerilen_tarif_idleri degerleri MUTLAKA aday listesindeki 'id' "
        "alanlarindan biri olmali, baska bir sey OLAMAZ."
    )
    user_prompt = (
        f'Kullanicinin istegi: "{intent.raw_message}"\n'
        f"{foto_notu}\n"
        f"{ADAYLAR_BASI}\n{aday_json}\n{ADAYLAR_SONU}\n\n"
        "Yukaridaki adaylardan en uygun 1-3 tanesini sec."
    )
    return system_prompt, user_prompt


# 4) LLM çıktısını doğrulama
_MESAJ_ANAHTARLARI = ("mesaj", "message", "reply", "cevap")
_ID_ANAHTARLARI = ("onerilen_tarif_idleri", "recommended_recipe_ids",
                   "tarif_idleri", "recipe_ids", "ids")


def parse_and_validate(data: dict, candidates: list[dict]) -> tuple[str, list[str]]:
    """LLM çıktısını adaylarla KESİŞTİRİR.

    Model listede olmayan bir id uydurursa (veya hic id donmezse ama
    adaylar varsa) burada elenir/duzeltilir.
    """
    gecerli_idler = {c["id"] for c in candidates}

    mesaj = next(
        (str(data[k]) for k in _MESAJ_ANAHTARLARI if data.get(k)),
        "İşte sana önerebileceklerim." if candidates else
        "Şu an uygun bir tarif bulamadım.",
    )

    ham_idler = next((data[k] for k in _ID_ANAHTARLARI if isinstance(data.get(k), list)), [])
    onerilen = [i for i in ham_idler if isinstance(i, str) and i in gecerli_idler]

    if not onerilen and candidates:
        # Model hic geçerli id vermedi ama elimizde aday var ise deterministik bir geri dönüş uyguluyoruz: en yüksek skorlu ilk 3 aday döner.
        onerilen = [c["id"] for c in candidates[:3]]
        logger.warning("LLM geçerli id döndürülmedi, otomatik sıralamaya düşüldü.")

    return mesaj.strip()[:1000], onerilen


# 5) Önbellek
def _cache_key(user: User, intent: ChatIntent, candidate_ids: Sequence[str]) -> str:
    """sha256(soru + kullanici + aday parmak izi).

    Aday kimlikleri parmak izine dahil: kiler/profil degisip adaylar
    farklilasirsa onbellek otomatik gecersiz olur.
    """
    parcalar = "|".join([
        normalize_text(intent.raw_message), str(user.id), ",".join(sorted(candidate_ids)),
    ])
    return hashlib.sha256(parcalar.encode()).hexdigest()


def _cache_oku(db: Session, anahtar: str) -> dict | None:
    kayit = db.scalar(
        select(LlmCache).where(
            LlmCache.cache_key == anahtar,
            (LlmCache.expires_at.is_(None)) | (LlmCache.expires_at > utcnow()),
        )
    )
    if kayit is None:
        return None
    kayit.hit_count += 1
    db.commit()
    return json.loads(kayit.response_json)


def _cache_yaz(db: Session, anahtar: str, veri: dict, model: str | None) -> None:
    db.add(LlmCache(
        cache_key=anahtar, response_json=json.dumps(veri, ensure_ascii=False), model=model,
        expires_at=utcnow() + timedelta(minutes=settings.CHAT_CACHE_TTL_MINUTES),
    ))
    db.commit()


# Kota ve konusma
def _gunluk_kotayi_kontrol_et(db: Session, user_id: int) -> None:
    limit = settings.CHAT_DAILY_LIMIT_PER_USER
    if limit <= 0:
        return
    bugun_baslangic = utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    adet = db.scalar(
        select(func.count(ChatMessage.id))
        .join(ChatConversation, ChatMessage.conversation_id == ChatConversation.id)
        .where(
            ChatConversation.user_id == user_id,
            ChatMessage.role == ChatRole.USER,
            ChatMessage.created_at >= bugun_baslangic,
        )
    ) or 0
    if adet >= limit:
        raise ChatDailyLimitExceeded()


def _get_or_create_conversation(
    db: Session, user: User, conversation_id: int | None
) -> ChatConversation:
    if conversation_id is None:
        konusma = ChatConversation(user_id=user.id)
        db.add(konusma)
        db.commit()
        db.refresh(konusma)
        return konusma

    konusma = db.get(ChatConversation, conversation_id)
    if konusma is None:
        raise NotFoundError("Sohbet bulunamadı.")
    if konusma.user_id != user.id:
        raise PermissionDeniedError("Bu sohbet size ait deĞil.")
    return konusma


async def chat_completion(
    db: Session, mongo_db: AsyncIOMotorDatabase, user: User,
    *, message: str, conversation_id: int | None, raw_image: bytes | None = None,
) -> dict:
    _gunluk_kotayi_kontrol_et(db, user.id)
    konusma = _get_or_create_conversation(db, user, conversation_id)

    # W2-T10: foto varsa ONCE malzeme tespiti yapilir. Tespit ONAY BEKLER -
    # burada hicbir sey pantry_items'a YAZILMAZ (bkz. pantry_service.py).
    image_hash: str | None = None
    detected: list[DetectedIngredient] = []
    if raw_image is not None:
        tespit = await detect_ingredients(db, raw_image=raw_image, user_id=user.id)
        image_hash, detected = tespit.image_hash, tespit.items

    lookup = get_lookup(db)
    intent = extract_intent(message, lookup)
    adaylar, filtreler = await build_candidates(db, mongo_db, user, intent)

    anahtar = _cache_key(user, intent, [a["id"] for a in adaylar])
    # Fotografli istekte ONBELLEK ATLANIR: tespit edilen malzemeler
    # onbellek anahtarina girmiyor, yoksa foto yaniti metin sorgusunun
    # bayat yanitina dusebilir.
    onbellek = None if detected else _cache_oku(db, anahtar)

    db.add(ChatMessage(
        conversation_id=konusma.id, role=ChatRole.USER, content=message,
        image_url=image_hash,
        detected_ingredients=(
            json.dumps([d.model_dump() for d in detected], ensure_ascii=False)
            if detected else None
        ),
    ))

    if onbellek is not None:
        mesaj, onerilen = onbellek["mesaj"], onbellek["onerilen_tarif_idleri"]
        model_adi = prompt_tok = tamamlama_tok = None
        from_cache = True
    else:
        system_prompt, user_prompt = build_prompt(intent, adaylar, detected_names=[d.display_name for d in detected])
        saglayici = get_chat_provider()
        sonuc = await saglayici.complete(system_prompt, user_prompt)
        mesaj, onerilen = parse_and_validate(sonuc.data, adaylar)
        model_adi = sonuc.usage.model
        prompt_tok, tamamlama_tok = sonuc.usage.prompt_tokens, sonuc.usage.completion_tokens
        from_cache = False
        if not detected:
            _cache_yaz(db, anahtar, {"mesaj": mesaj, "onerilen_tarif_idleri": onerilen}, model_adi)

    db.add(ChatMessage(
        conversation_id=konusma.id, role=ChatRole.ASSISTANT, content=mesaj,
        suggested_recipe_ids=json.dumps(onerilen, ensure_ascii=False),
        prompt_tokens=prompt_tok, completion_tokens=tamamlama_tok, from_cache=from_cache,
    ))
    konusma.last_message_at = utcnow()
    db.commit()

    logger.info(
        "Sohbet | kullanici=%s konusma=%s adaylar=%d onerilen=%d onbellek=%s "
        "foto=%s tespit=%d filtreler=%s",
        user.id, konusma.id, len(adaylar), len(onerilen), from_cache,
        bool(image_hash), len(detected), filtreler,
    )

    return {
        "conversation_id": konusma.id,
        "mesaj": mesaj,
        "onerilen_tarif_idleri": onerilen,
        "uygulanan_filtreler": filtreler,
        "from_cache": from_cache,
        "detected_ingredients": detected,
    }


# Ana akış
# async def chat_completion(
#     db: Session, mongo_db: AsyncIOMotorDatabase, user: User,
#     *, message: str, conversation_id: int | None,
# ) -> dict:
#     _gunluk_kotayi_kontrol_et(db, user.id)
#     konusma = _get_or_create_conversation(db, user, conversation_id)

#     lookup = get_lookup(db)
#     intent = extract_intent(message, lookup)
#     adaylar, filtreler = await build_candidates(db, mongo_db, user, intent)

#     anahtar = _cache_key(user, intent, [a["id"] for a in adaylar])
#     onbellek = _cache_oku(db, anahtar)

#     db.add(ChatMessage(conversation_id=konusma.id, role=ChatRole.USER, content=message))

#     if onbellek is not None:
#         mesaj, onerilen = onbellek["mesaj"], onbellek["onerilen_tarif_idleri"]
#         model_adi = prompt_tok = tamamlama_tok = None
#         from_cache = True
#     else:
#         system_prompt, user_prompt = build_prompt(intent, adaylar)
#         saglayici = get_chat_provider()
#         sonuc = await saglayici.complete(system_prompt, user_prompt)
#         mesaj, onerilen = parse_and_validate(sonuc.data, adaylar)
#         model_adi = sonuc.usage.model
#         prompt_tok, tamamlama_tok = sonuc.usage.prompt_tokens, sonuc.usage.completion_tokens
#         from_cache = False
#         _cache_yaz(db, anahtar, {"mesaj": mesaj, "onerilen_tarif_idleri": onerilen}, model_adi)

#     db.add(ChatMessage(
#         conversation_id=konusma.id, role=ChatRole.ASSISTANT, content=mesaj,
#         suggested_recipe_ids=json.dumps(onerilen, ensure_ascii=False),
#         prompt_tokens=prompt_tok, completion_tokens=tamamlama_tok, from_cache=from_cache,
#     ))
#     konusma.last_message_at = utcnow()
#     db.commit()

#     logger.info(
#         "Sohbet | kullanıcı=%s konuşma=%s adaylar=%d önerilen=%d önbellek=%s filtreler=%s",
#         user.id, konusma.id, len(adaylar), len(onerilen), from_cache, filtreler,
#     )

#     return {
#         "conversation_id": konusma.id,
#         "mesaj": mesaj,
#         "onerilen_tarif_idleri": onerilen,
#         "uygulanan_filtreler": filtreler,
#         "from_cache": from_cache,
#     }