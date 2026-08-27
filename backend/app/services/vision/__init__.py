"""Gorme modeli servisi.

Kullanim:
    from app.services.vision import get_vision_provider, prepare_image

    islenmis, ozet = prepare_image(ham_bytes)
    sonuc = await get_vision_provider().analyze(islenmis, PROMPT)
"""
from functools import lru_cache

from app.core.config import settings

from .base import (
    ImageTooLarge, InvalidImage, VisionError, VisionInvalidResponse,
    VisionProvider, VisionRateLimited, VisionResult, VisionTimeout, VisionUsage,
    extract_json, prepare_image, to_data_uri,
    ALLOWED_IMAGE_TYPES, EmptyImage, UnsupportedImageType
)
from .providers import FakeVisionProvider, GroqVisionProvider, OpenAIVisionProvider, BrokenVisionProvider

_SAGLAYICILAR: dict[str, type[VisionProvider]] = {
    "fake": FakeVisionProvider,
    "groq": GroqVisionProvider,
    "openai": OpenAIVisionProvider,
    "broken": BrokenVisionProvider,
}


@lru_cache(maxsize=1)
def get_vision_provider() -> VisionProvider:
    """Ayarda secili saglayiciyi doner. Bir kez olusturulup onbelleklenir.

    Tanimsiz bir saglayici adi yazilirsa uygulama COKMEZ; sahte saglayiciya
    duser ve hata loglar. Gerekce: yanlis yazilmis bir ayar yuzunden
    kilerin ve kalorinin de calismamasi orantisiz olurdu.
    """
    ad = (settings.VISION_PROVIDER or "fake").lower().strip()
    sinif = _SAGLAYICILAR.get(ad)
    if sinif is None:
        import logging
        logging.getLogger(__name__).error(
            "Bilinmeyen VISION_PROVIDER='%s'. Gecerli degerler: %s. "
            "Sahte saglayiciya dusuluyor.", ad, ", ".join(_SAGLAYICILAR)
        )
        sinif = FakeVisionProvider
    return sinif()


def reset_vision_provider() -> None:
    """Onbellegi temizler. Testlerde saglayici degistirmek icin."""
    get_vision_provider.cache_clear()


__all__ = [
    "VisionProvider", "VisionResult", "VisionUsage",
    "VisionError", "VisionTimeout", "VisionRateLimited",
    "VisionInvalidResponse", "ImageTooLarge", "InvalidImage",
    "get_vision_provider", "reset_vision_provider",
    "prepare_image", "to_data_uri", "extract_json",
    "FakeVisionProvider", "GroqVisionProvider", "OpenAIVisionProvider",
    "ALLOWED_IMAGE_TYPES", "EmptyImage", "UnsupportedImageType",
    "BrokenVisionProvider"
]