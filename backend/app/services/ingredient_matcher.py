"""ham malzeme -> sözlük isim olarak eşleştirme yapar 
foto/fiş/tarif metninden gelen her türlü ham adı Ingredient sözlüğüne bağlar
görme modeline bağımlı değildir 
eşleştirme sırası: 
1- exact: normalize edilmiş ad doğrudan sözlükte aranız 
2- suffix: türkçe çoğul eki ile aratılır
3- partial: son 1-2 kelime benzer olursa
4- fuzzy: difflib benzerlik >= 0.86 olursa (örn: domats -> domates)
"""
from __future__ import annotations
# future: pythonun zaman makinesi, geecekteki sürümlerinde standart/varsayılan olacak özellikler kullandığım kodda erkenden aktif edebilmeyi sağlar
#annotation: tip belirteçlerinin(type hints) python tarafından okunma şeklini değiştiren özellik: kod aktif edilince type hintsler kod tanımladığı an işlenmez hepsi bellekte birer string olarak tutulur

import difflib #metin/liste/veri dizilerini karşılaştırmaya yarar
import logging #programın geçtiği aşamalar hatalar olayları sistemli şekilde kayıt altına alma(loglama) kütüphanesi print()'in yerini alır mesajları önem seviyesine göre debug, info, warning, error, critical diye sınıflandırmaya yarar, kayıtları sadece ekrana basmaz metine dbye sunucuta kaydedebilir
import time
from dataclasses import dataclass #teme amacı veri tutmak olan class oluştururken kullanılan decorator | class içinde otomatik __init__(başlatıcı), __repr__(yazdırılabilir temsili), __eq__(eşitlik kontrolü) gibi std metodları benim yerime arka planda yazar 
from datetime import datetime
from typing import Iterable, Iterator #type hinting(tip belirleyici)| Iterable: üzerinde for döngüsü dönülenilen nesneleri temsil eder, | Iterator: verileri tek tek üreten ve nerede kaldığını hatırlayan (next() ile bir sonrakini çağıran) nesneleri temsil eder 

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError # db kuralları ihlal edilince fırlatılan hatadır 
from sqlalchemy.orm import Session # db ile kod arası çalışma masası, veri tabanına veri ekleme güncellem silme işlemlerini toplar ve ben session.commit() diyene kadar bekletir, eğer bir hata olursa session.rollback() ile tüm işlemleri geri alarak db bozulmaktan korur

from app.models import Ingredient, IngredientAlias, UnmatchedIngredient 
from app.services.unit_service import normalize_text

logger = logging.getLogger(__name__)

FUZZY_ESIK = 0.86 #bulanık eşleştirme eşiği

_COGUL_EKLERI = ("lari", "leri", "ları", "lerı", "lar", "ler")

_ONBELLEK_SURESI = 300 #saniye
_onbellek: tuple[float, dict[str, tuple[str, str]]] | None = None

@dataclass(frozen=True, slots=True)
class MatchResult:
    """tek bir ham adın eşleştrime sonucu"""
    raw_name: str
    canonical_name: str | None
    display_name: str
    confidence: float
    matched_by: str  # exact | suffix | partial | fuzzy | none

#SÖZLÜK ÖNBELLEĞİ

def _sozlugu_yukle(db: Session) -> dict[str, tuple[str, str]]:
    """{normalize_edilmis_anahtar: (canonical_name, display_name)} tablosu.

    Uc kaynaktan beslenir: canonical_name, display_name, tum alias'lar.
    setdefault kullaniliyor - canonical/display, alias'a gore ONCELIKLI.
    """
    tablo : dict[str, tuple[str, str]] = {}

    for canonical, display in db.execute(
        select(Ingredient.canonical_name, Ingredient.display_name)
    ).all():
        tablo[normalize_text(canonical)] = (canonical, display)
        tablo.setdefault(normalize_text(display), (canonical, display))

    for alias, canonical, display in db.execute(
        select(IngredientAlias.alias, Ingredient.canonical_name, Ingredient.display_name)
        .join(Ingredient, IngredientAlias.ingredient_id == Ingredient.id)
    ).all():
        tablo.setdefault(normalize_text(alias), (canonical, display))

    tablo.pop("", None)
    logger.info("Malzeme sözlüğü yüklendi: %d anahtar", len(tablo))
    return tablo

def get_lookup(db: Session, *, force:bool= False) -> dict[str,tuple[str,str]]:
    """sözlüğü önbellekten döner TTL dolduysa yeniden yükler neden ön bellek : 10 malzemelik bir foto için 20 sql sorgusu yerine tek sorgu + ramde O(1) arama 
    """
    global _onbellek
    simdi = time.monotonic()
    if not force and _onbellek and simdi - _onbellek[0] < _ONBELLEK_SURESI:
        return _onbellek[1]
    tablo = _sozlugu_yukle(db)
    _onbellek = (simdi, tablo)
    return tablo

def clear_lookup_cache() -> None:
    """testlerde ve seed sonrası çağrılır"""
    global _onbellek
    _onbellek = None

#EŞLEŞTİRME

def _adaylar(norm:str) -> Iterator[tuple[str, str]]:
    """aranacak anahtarları oncelik sırasıyla üretir"""
    yield norm, "exact"
    for ek in _COGUL_EKLERI:
        if norm.endswith(ek) and len(norm) - len(ek) >=3:
            yield norm[: -len(ek)], "suffix"

    parcalar = norm.split()
    if len(parcalar) > 1:
        yield " ".join(parcalar[-2:]), "partial"
        yield parcalar[-1], "partial"

def _eslestir(
        norm: str,
        tablo: dict[str, tuple[str, str]]
) -> tuple[tuple[str, str] | None, str]:
    for aday, yontem in _adaylar(norm):
        if bulunan := tablo.get(aday):
            return bulunan, yontem

    if len(norm) >= 4:
        yakin = difflib.get_close_matches(norm, tablo.keys(), n=1, cutoff=FUZZY_ESIK)
        if yakin: 
            return tablo[yakin[0]], "fuzzy"

    return None, "none"

def _insan_okunur(ham: str) -> str:
    """eşleşmeyenler için gösterim adı ham metni bozmadan baş harf büyütür"""
    temiz = " ".join(ham.split())[:120]
    return temiz[:1].upper() + temiz[1:] if temiz else "Bilinmeyen"

#Eşleşmeyen kayıtları
def kaydet_eslesmeyen(db:Session, ham: str, norm: str, source:str) -> None:
    kayit = db.execute(
        select(UnmatchedIngredient).where(UnmatchedIngredient.normalized_text == norm)
    ).scalar_one_or_none()
    #scalar: dbden gelen sonucu karmaşık bir tuple olarak değil doğrdudan kullanılan temiz python objesi olarak verir
    #one: bir tane bekliyorum
    #or none: yok ise boş dön
    if kayit is not None:
        kayit.occurrence_count +=1
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
        logger.debug("eşleşmeyen '%s' başka bir istek tarafından eklendi", norm)

#genel api
def match_ingredients(
        db:Session,
        items: Iterable[tuple[str, float]],
        *,
        source: str = "vision",
        record_unmatched: bool = True,
) -> list[MatchResult]:
    """ham_ad, confidence çiftleriini sözlükle eşleştirir
    commit etmez çağıran katman işlemin tamamını tek transactionda kapatmalı"""
    tablo= get_lookup(db)
    sonuclar: list[MatchResult] = []
    for ham, guven in items: 
        norm = normalize_text(ham)
        if not norm:
            continue
        eslesme, yontem = _eslestir(norm, tablo)
        if eslesme is not None:
            canocical, display = eslesme
            carpan = 0.9 if yontem == "fuzzy" else 1.0
            sonuclar.append(MatchResult(
                raw_name=ham,
                canonical_name=canocical,
                display_name=display,
                confidence=round(min(guven * carpan, 1.0), 3),
                matched_by=yontem,
            ))
        else: 
            if record_unmatched:
                kaydet_eslesmeyen(db, ham, norm, source)
            sonuclar.append(MatchResult(
                raw_name=ham,
                canonical_name=None,
                display_name=_insan_okunur(ham),
                confidence=round(guven, 3),
                matched_by="none",
            ))
    return sonuclar

def match_one(db: Session, ham: str, *, source:str = "manual") -> MatchResult :
    "tek ad için kısayol"
    return match_ingredients(db, [(ham, 1.0)], source=source)[0]