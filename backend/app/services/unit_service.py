"""Birim donusum servisi.

TEMEL BIRIM ILKESI: mass -> g, volume -> ml, count -> adet.
Tum miktarlar veritabaninda temel birimde saklanir; gosterimde cevrilir.
"""
from app.models.enums import UnitCode, UnitType
import re
from app.models.enums import UnitCode, UnitType

# Hacim birimlerinin mililitre karsiligi
VOLUME_TO_ML: dict[str, float] = {
    UnitCode.ML.value: 1.0,
    UnitCode.L.value: 1000.0,
    UnitCode.SU_BARDAGI.value: 200.0,
    UnitCode.YEMEK_KASIGI.value: 15.0,
    UnitCode.TATLI_KASIGI.value: 10.0,
    UnitCode.CAY_KASIGI.value: 5.0,
}

# Kutle birimlerinin gram karsiligi
MASS_TO_G: dict[str, float] = {
    UnitCode.G.value: 1.0,
    UnitCode.KG.value: 1000.0,
}

COUNT_UNITS: set[str] = {
    UnitCode.ADET.value,
    UnitCode.PAKET.value,
    UnitCode.DEMET.value,
    UnitCode.DILIM.value,
}


class UnitConversionError(ValueError):
    """Birim donusumu yapilamadiginda firlatilir."""


def to_grams(
    quantity: float | None,
    unit: str | None,
    *,
    grams_per_piece: float | None = None,
    ml_to_gram: float | None = None,
) -> float:
    """Herhangi bir miktari GRAM'a cevirir.

    Kalori hesabi her zaman gram uzerinden yapilir; bu yuzden hacim ve adet
    birimleri de grama indirgenir.

    grams_per_piece : 1 sogan ~ 150 g   (adet -> gram)
    ml_to_gram      : yogunluk, 1 ml zeytinyagi ~ 0.92 g  (ml -> gram)
    """
    if quantity is None or unit is None:
        return 0.0
    if quantity < 0: 
        raise UnitConversionError("Miktar negatif olamaz.")

    if unit in MASS_TO_G:
        return quantity * MASS_TO_G[unit]

    if unit in VOLUME_TO_ML:
        ml = quantity * VOLUME_TO_ML[unit]
        # Yogunluk bilinmiyorsa su kabul edilir (1 ml = 1 g)
        return ml * (ml_to_gram if ml_to_gram is not None else 1.0)

    if unit in COUNT_UNITS:
        if grams_per_piece is None:
            raise UnitConversionError(
                f"'{unit}' birimi icin grams_per_piece tanimli degil."
            )
        return quantity * grams_per_piece

    raise UnitConversionError(f"Bilinmeyen birim: {unit}")


def to_base(quantity: float, unit: str, unit_type: str, **kwargs) -> float:
    """Miktari ilgili TEMEL birime cevirir (depolama icin)."""
    if unit_type == UnitType.MASS.value:
        return to_grams(quantity, unit, **kwargs)
    
    if unit_type == UnitType.VOLUME.value:
        if unit in VOLUME_TO_ML:
            return quantity * VOLUME_TO_ML[unit]
        if unit in MASS_TO_G:  # 1 kg su ~ 1000 ml
            yogunluk = kwargs.get("ml_to_gram") or 1.0
            return quantity * MASS_TO_G[unit] / yogunluk
        raise UnitConversionError(f"'{unit}' hacim birimine cevrilemiyor.")
    
    if unit_type == UnitType.COUNT.value:
        if unit in COUNT_UNITS:
            return quantity
        gpp = kwargs.get("grams_per_piece")
        if unit in MASS_TO_G and gpp:
            return quantity * MASS_TO_G[unit] / gpp
        raise UnitConversionError(f"'{unit}' adede cevrilemiyor.")
    
    raise UnitConversionError(f"Bilinmeyen birim tipi: {unit_type}")


def from_base(
    quantity_base: float, display_unit: str, **kwargs
) -> float:
    """Temel birimdeki degeri kullaniciya gosterilecek birime cevirir."""
    if display_unit in MASS_TO_G:
        return quantity_base / MASS_TO_G[display_unit]
    if display_unit in VOLUME_TO_ML:
        return quantity_base / VOLUME_TO_ML[display_unit]
    if display_unit in COUNT_UNITS:
        gpp = kwargs.get("grams_per_piece")
        return quantity_base / gpp if gpp else quantity_base
    raise UnitConversionError(f"Bilinmeyen gosterim birimi: {display_unit}")

def cooked_to_raw(cooked_grams: float, yield_factor: float | None) -> float:
    """Pismis agirligi CIG karsiligina cevirir.

    Kullanici '150 g pilav yedim' dediginde, kalori hesabi icin bunun kac gram
    CIG pirince karsilik geldigini bilmemiz gerekir (pirinc kcal degeri cig
    agirlik uzerinden tanimlidir).
        pirinc yield = 2.9  ->  150 g pilav = 150 / 2.9 = 51.7 g cig pirinc
    """
    if not yield_factor or yield_factor <= 0:
        return cooked_grams
    return cooked_grams / yield_factor


def raw_to_cooked(raw_grams: float, yield_factor: float | None) -> float:
    """Cig agirligi pismis karsiligina cevirir (porsiyon gosterimi icin)."""
    if not yield_factor or yield_factor <= 0:
        return raw_grams
    return raw_grams * yield_factor


# ---------------------------------------------------------------- metin normalizasyonu
_TR_MAP = str.maketrans("çğöşüÇĞÖŞÜ", "cgosuCGOSU")


def normalize_text(text: str) -> str:
    """Malzeme adini eslestirme icin normalize eder.

    'Kırmızı Mercimek (1 KG)' -> 'kirmizi mercimek 1 kg'

    Turkce 'I/İ/ı/i' harflerinin tamami ASCII 'i'ye katlanir. Python'un
    varsayilan lower() metodu Turkce kurallarini bilmez ('I'.lower() == 'i'
    ama Turkce'de 'ı' olmalidir); bu belirsizligi tek yone katlayarak
    ortadan kaldiriyoruz.
    """
    if not text:
        return ""
    text = text.replace("İ", "i").replace("I", "i").replace("ı", "i")
    text = text.translate(_TR_MAP).lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def to_canonical_form(text: str) -> str:
    """Normalize metni canonical_name bicimine cevirir: bosluk -> alt cizgi."""
    return normalize_text(text).replace(" ", "_")