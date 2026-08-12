"""Malzeme adi eslestirme ve bulanik arama. W2-T05.

UC ASAMA (ilk tutan kazanir):
  1) canonical : ingredients.canonical_name / display_name tam eslesme
  2) alias     : ingredient_aliases.alias tam eslesme
  3) fuzzy     : rapidfuzz token_set_ratio >= 85

Cekirdek fonksiyon match_name() SAFTIR: veritabani, ag, saat veya rastgelelik
kullanmaz. Ayni girdi + ayni sozluk daima ayni sonucu verir. Bu sayede 30+
vaka DB olmadan, milisaniyede ve deterministik olarak test edilebiliyor.

DB'ye dokunan her sey dosyanin alt yarisinda; ust yari tamamen saf.
Hem gorme modeli ciktisi (W2-T04) hem chatbot metni (W3-T12) buradan gecer.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Iterable

from rapidfuzz import fuzz, process
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models import Ingredient, IngredientAlias, UnmatchedIngredient
from app.services.unit_service import normalize_text

logger = logging.getLogger(__name__)

# ==================================================================
# Ayarlar
# ==================================================================
# 85: gorev tanimindaki esik. Deneysel olarak da makul - 80'de
# 'kabak'<->'kavak', 'kimyon'<->'kimyon' disi eslesmeler basliyor;
# 90'da yazim hatalari kaciriyor.
FUZZY_ESIK = 85

# token_set_ratio birden fazla adaya 100 verebildigi icin tek aday degil
# kisa bir liste aliyoruz; dogru olani ikincil olcutle seciyoruz.
FUZZY_ADAY_SAYISI = 5

# 3 harften kisa girdide her sey her seye benzer ('un' <-> 'up').
FUZZY_MIN_UZUNLUK = 4

# Uzun ekler once denenmeli: 'domateslari' -> 'lari' atilmali, 'lar' degil.
# normalize_text Turkce harfleri zaten ASCII'ye katladigi icin
# 'ları' yerine 'lari' yazmak yeterli.
_COGUL_EKLERI = ("lari", "leri", "lar", "ler")


# ==================================================================
# Sonuc tipi
# ==================================================================
@dataclass(frozen=True, slots=True)
class MatchResult:
    """Tek bir ham adin eslestirme sonucu.

    matched_by ve score API yanitinda YER ALMAZ; log, hata ayiklama ve
    W4-T11 dogruluk olcumu icin tutulur.
    """
    raw_name: str
    canonical_name: str | None
    display_name: str
    confidence: float
    matched_by: str   # canonical | alias | canonical_ek | alias_ek | fuzzy | none
    score: float      # 0-100 benzerlik puani; tam eslesmede 100, eslesmeyende 0

    @property
    def matched(self) -> bool:
        return self.canonical_name is not None


# ==================================================================
# Sozluk yapisi (saf veri)
# ==================================================================
@dataclass(frozen=True, slots=True)
class IngredientLookup:
    """Eslestirme icin hazirlanmis, salt-okunur sozluk.

    canonical : normalize(canonical_name veya display_name) -> canonical_name
    alias     : normalize(alias)                            -> canonical_name
    display   : canonical_name                              -> display_name
    fuzzy_keys: 1. ve 2. asamadaki TUM anahtarlar (rapidfuzz aday havuzu)
    """
    canonical: dict[str, str]
    alias: dict[str, str]
    display: dict[str, str]
    fuzzy_keys: tuple[str, ...]

    def __len__(self) -> int:
        return len(self.display)

    def canonical_of(self, anahtar: str) -> str | None:
        return self.canonical.get(anahtar) or self.alias.get(anahtar)


def build_lookup(
    ingredients: Iterable[tuple[str, str]],
    aliases: Iterable[tuple[str, str]] = (),
) -> IngredientLookup:
    """Sozlugu ham satirlardan kurar. SAF: veritabani gormez.

    ingredients: (canonical_name, display_name) ciftleri
    aliases    : (alias, canonical_name) ciftleri

    Testler bu fonksiyona elle liste verir, uretim kodu DB'den okuyup verir.
    """
    canonical: dict[str, str] = {}
    display: dict[str, str] = {}

    for canonical_name, display_name in ingredients:
        display[canonical_name] = display_name
        # canonical_name 'kirmizi_mercimek' -> normalize -> 'kirmizi mercimek'
        canonical[normalize_text(canonical_name)] = canonical_name
        # display_name ikinci sirada: canonical adin uzerine YAZMAZ
        canonical.setdefault(normalize_text(display_name), canonical_name)

    alias_map: dict[str, str] = {}
    for alias_text, canonical_name in aliases:
        if canonical_name not in display:
            # Sozlukte olmayan bir malzemeye isaret eden alias sessizce
            # yutulursa ilerde 'neden eslesmiyor' diye saatler harcanir.
            logger.warning(
                "Alias '%s' bilinmeyen malzemeye isaret ediyor: '%s'. Atlandi.",
                alias_text, canonical_name,
            )
            continue
        anahtar = normalize_text(alias_text)
        if anahtar in canonical:
            continue  # 1. asama zaten yakaliyor, aday havuzunu sisirme
        alias_map.setdefault(anahtar, canonical_name)

    canonical.pop("", None)
    alias_map.pop("", None)

    return IngredientLookup(
        canonical=canonical,
        alias=alias_map,
        display=display,
        fuzzy_keys=tuple(canonical) + tuple(alias_map),
    )


# ==================================================================
# Cekirdek: SAF eslestirme
# ==================================================================
def _tekillestir(norm: str) -> str | None:
    """Turkce cogul ekini atar; ek yoksa None.

    NEDEN AYRI ASAMA: rapidfuzz bunu yakalayamiyor. Tek kelimede token
    kumesi tek elemanli oldugu icin token_set_ratio duz ratio'ya iner:
        token_set_ratio('domatesler', 'domates') = 82  <  85
    """
    for ek in _COGUL_EKLERI:
        if norm.endswith(ek) and len(norm) - len(ek) >= 3:
            return norm[: -len(ek)]
    return None


def _insan_okunur(ham: str) -> str:
    """Eslesmeyenler icin gosterim adi. Ham metni bozmadan bas harfi buyutur."""
    temiz = " ".join(ham.split())[:120]
    return temiz[:1].upper() + temiz[1:] if temiz else "Bilinmeyen"


def _sonuc(
    raw_name: str, canonical_name: str, lookup: IngredientLookup,
    confidence: float, matched_by: str, score: float,
) -> MatchResult:
    # Bulanik eslesme kesin degil: guven puanini benzerlik oraniyla kis.
    # Onay ekraninda (W2-T10) daha asagida gorunmesi dogru davranis.
    carpan = score / 100.0 if matched_by == "fuzzy" else 1.0
    return MatchResult(
        raw_name=raw_name,
        canonical_name=canonical_name,
        display_name=lookup.display[canonical_name],
        confidence=round(min(confidence * carpan, 1.0), 3),
        matched_by=matched_by,
        score=round(float(score), 1),
    )


def _eslesmedi(raw_name: str, confidence: float) -> MatchResult:
    return MatchResult(
        raw_name=raw_name,
        canonical_name=None,
        display_name=_insan_okunur(raw_name),
        confidence=round(confidence, 3),
        matched_by="none",
        score=0.0,
    )


def _bulanik_eslestir(
    raw_name: str, norm: str, lookup: IngredientLookup, confidence: float,
) -> MatchResult:
    if len(norm) < FUZZY_MIN_UZUNLUK:
        return _eslesmedi(raw_name, confidence)

    adaylar = process.extract(
        norm,
        lookup.fuzzy_keys,
        scorer=fuzz.token_set_ratio,
        limit=FUZZY_ADAY_SAYISI,
        score_cutoff=FUZZY_ESIK,
    )
    if not adaylar:
        return _eslesmedi(raw_name, confidence)

    # DIKKAT - token_set_ratio'nun tuzagi:
    # Girdiyi TAMAMEN iceren her adaya 100 verir.
    #   token_set_ratio('domates', 'domates')         = 100
    #   token_set_ratio('domates', 'domates salcasi') = 100   <-- yanlis aday
    # Tek olcutle secseydik hangisinin donecegi liste sirasina kalirdi.
    # token_sort_ratio uzunluk farkini cezalandirir ve ayrimi yapar:
    #   token_sort_ratio('domates', 'domates')         = 100
    #   token_sort_ratio('domates', 'domates salcasi') = 63
    anahtar, skor, _ = max(
        adaylar,
        key=lambda aday: (aday[1], fuzz.token_sort_ratio(norm, aday[0])),
    )

    canonical_name = lookup.canonical_of(anahtar)
    if canonical_name is None:  # olmamali; savunma amacli
        return _eslesmedi(raw_name, confidence)
    return _sonuc(raw_name, canonical_name, lookup, confidence, "fuzzy", skor)


def match_name(
    raw_name: str, lookup: IngredientLookup, *, confidence: float = 1.0,
) -> MatchResult:
    """SAF FONKSIYON. Tek bir ham adi sozlukle eslestirir.

    Veritabani, ag, saat, rastgelelik YOK. Ayni girdi -> ayni cikti.
    """
    norm = normalize_text(raw_name)
    if not norm:
        return _eslesmedi(raw_name, confidence)

    # 1) canonical_name / display_name tam eslesme
    if canonical_name := lookup.canonical.get(norm):
        return _sonuc(raw_name, canonical_name, lookup, confidence, "canonical", 100)

    # 2) alias tam eslesme
    if canonical_name := lookup.alias.get(norm):
        return _sonuc(raw_name, canonical_name, lookup, confidence, "alias", 100)

    # 1b/2b) cogul eki atilarak ayni iki asama
    if tekil := _tekillestir(norm):
        if canonical_name := lookup.canonical.get(tekil):
            return _sonuc(raw_name, canonical_name, lookup, confidence, "canonical_ek", 100)
        if canonical_name := lookup.alias.get(tekil):
            return _sonuc(raw_name, canonical_name, lookup, confidence, "alias_ek", 100)

    # 3) bulanik eslesme
    return _bulanik_eslestir(raw_name, norm, lookup, confidence)


def match_names(
    items: Iterable[tuple[str, float]], lookup: IngredientLookup,
) -> list[MatchResult]:
    """Toplu SAF eslestirme. (ham_ad, confidence) ciftleri alir."""
    return [match_name(ham, lookup, confidence=guven) for ham, guven in items]


# ==================================================================
# BURADAN ASAGISI VERITABANINA DOKUNUR
# ==================================================================
_ONBELLEK_SURESI = 300  # saniye
_onbellek: tuple[float, IngredientLookup] | None = None


def load_lookup(db: Session) -> IngredientLookup:
    """Sozlugu veritabanindan okuyup saf yapiya cevirir."""
    ingredients = db.execute(
        select(Ingredient.canonical_name, Ingredient.display_name)
    ).all()
    aliases = db.execute(
        select(IngredientAlias.alias, Ingredient.canonical_name)
        .join(Ingredient, IngredientAlias.ingredient_id == Ingredient.id)
    ).all()

    lookup = build_lookup(ingredients, aliases)
    logger.info(
        "Malzeme sozlugu yuklendi: %d malzeme, %d arama anahtari",
        len(lookup), len(lookup.fuzzy_keys),
    )
    return lookup


def get_lookup(db: Session, *, force: bool = False) -> IngredientLookup:
    """Sozlugu onbellekten doner; TTL dolduysa yeniden yukler.

    NEDEN ONBELLEK: 10 malzemelik bir fotograf icin 20 SQL sorgusu yerine
    tek sorgu. Sozluk gun icinde nadiren degisir.
    """
    global _onbellek
    simdi = time.monotonic()
    if not force and _onbellek and simdi - _onbellek[0] < _ONBELLEK_SURESI:
        return _onbellek[1]
    lookup = load_lookup(db)
    _onbellek = (simdi, lookup)
    return lookup


def clear_lookup_cache() -> None:
    """Testlerde ve seed sonrasi cagrilir."""
    global _onbellek
    _onbellek = None


def kaydet_eslesmeyen(db: Session, ham: str, norm: str, source: str) -> None:
    """unmatched_ingredients tablosuna upsert eder.

    normalized_text UNIQUE oldugu icin es zamanli iki istek cakisabilir.
    begin_nested() ile SAVEPOINT aciyoruz: cakisma olursa yalnizca bu
    ekleme geri alinir, isteğin geri kalani kaybolmaz.
    """
    kayit = db.execute(
        select(UnmatchedIngredient).where(UnmatchedIngredient.normalized_text == norm)
    ).scalar_one_or_none()

    if kayit is not None:
        kayit.occurrence_count += 1
        kayit.last_seen_at = datetime.now()
        return

    try:
        with db.begin_nested():
            db.add(UnmatchedIngredient(
                raw_text=ham[:255],
                normalized_text=norm[:255],
                source=source,
            ))
    except IntegrityError:
        logger.debug("Eslesmeyen '%s' baska bir istek tarafindan eklendi.", norm)


def match_ingredients(
    db: Session,
    items: Iterable[tuple[str, float]],
    *,
    source: str = "vision",
    record_unmatched: bool = True,
) -> list[MatchResult]:
    """DB'li sarmalayici: eslestirir + eslesmeyenleri kaydeder.

    COMMIT ETMEZ. Cagiran katman islemi tek transaction'da kapatmali.
    """
    lookup = get_lookup(db)
    sonuclar: list[MatchResult] = []

    for ham, guven in items:
        sonuc = match_name(ham, lookup, confidence=guven)
        if not sonuc.matched and record_unmatched:
            if norm := normalize_text(ham):
                kaydet_eslesmeyen(db, ham, norm, source)
        sonuclar.append(sonuc)

    return sonuclar


def match_one(db: Session, ham: str, *, source: str = "manual") -> MatchResult:
    """Tek ad icin kisayol. W2-T02 elle malzeme ekleme ucu kullanacak."""
    return match_ingredients(db, [(ham, 1.0)], source=source)[0]