"""Birim donusum servisi.

TEMEL BIRIM ILKESI: mass -> g, volume -> ml, count -> adet.
Tum miktarlar veritabaninda temel birimde saklanir; gosterimde cevrilir.
"""
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


class UnitConversionError(ValueError):
    """Birim donusumu yapilamadiginda firlatilir."""


def to_grams(
    quantity: float,
    unit: str,
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
    if quantity is None:
        return 0.0

    if unit in MASS_TO_G:
        return quantity * MASS_TO_G[unit]

    if unit in VOLUME_TO_ML:
        ml = quantity * VOLUME_TO_ML[unit]
        # Yogunluk bilinmiyorsa su kabul edilir (1 ml = 1 g)
        return ml * (ml_to_gram if ml_to_gram is not None else 1.0)

    if unit in (UnitCode.ADET.value, UnitCode.PAKET.value,
                UnitCode.DEMET.value, UnitCode.DILIM.value):
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
            return quantity * MASS_TO_G[unit]
        raise UnitConversionError(f"'{unit}' hacim birimine cevrilemiyor.")
    if unit_type == UnitType.COUNT.value:
        return quantity
    raise UnitConversionError(f"Bilinmeyen birim tipi: {unit_type}")


def from_base(quantity_base: float, display_unit: str, **kwargs) -> float:
    """Temel birimdeki degeri kullaniciya gosterilecek birime cevirir."""
    if display_unit in MASS_TO_G:
        return quantity_base / MASS_TO_G[display_unit]
    if display_unit in VOLUME_TO_ML:
        return quantity_base / VOLUME_TO_ML[display_unit]
    gpp = kwargs.get("grams_per_piece")
    if gpp:
        return quantity_base / gpp
    return quantity_base