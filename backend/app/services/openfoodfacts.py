"""Open Food Facts API istemcisi. W2-T12.

Vision/chat saglayicilarindaki karmasik mesaj govdesi/JSON-mode gerekmiyor,
sadece httpx + timeout + retry ile duz bir GET/JSON istemcisi.
"""
from __future__ import annotations

import asyncio
import logging
import random
import re
import time
from dataclasses import dataclass

import httpx

from app.core.config import settings
from app.core.exceptions import ExternalServiceError

logger = logging.getLogger(__name__)

_RETRY_KODLARI = {429, 500, 502, 503, 504}


class OpenFoodFactsError(ExternalServiceError):
    code = "off_error"
    message = "Urun veritabanina su anda ulasilamiyor."


@dataclass(frozen=True, slots=True)
class OffProduct:
    """OFF'tan gelen ham veri, PROJENIN birimlerine cevrilmis."""
    name: str
    brand: str | None
    calories_per_100g: float | None
    protein_per_100g: float | None
    carb_per_100g: float | None
    fat_per_100g: float | None
    fiber_per_100g: float | None
    sugar_per_100g: float | None
    sodium_mg_per_100g: float | None
    image_url: str | None
    serving_size_g: float | None


def _sayi(deger) -> float | None:
    try:
        return float(deger)
    except (TypeError, ValueError):
        return None


def _serving_size_g(ham: str | None) -> float | None:
    """OFF 'serving_size' alani serbest metin: '30 g', '1 adet (250g)'.

    Sadece basit 'N g' bicimini cozuyoruz; digerlerinde None doner -
    kullanici onay ekraninda quantity_g'yi elle girer.
    """
    if not ham:
        return None
    if m := re.search(r"(\d+(?:[.,]\d+)?)\s*g\b", ham.lower()):
        return float(m.group(1).replace(",", "."))
    return None


def _off_to_product(ham: dict) -> OffProduct:
    n = ham.get("nutriments") or {}
    return OffProduct(
        name=(ham.get("product_name") or ham.get("product_name_tr") or "").strip(),
        brand=(ham.get("brands") or "").split(",")[0].strip() or None,
        calories_per_100g=_sayi(n.get("energy-kcal_100g")),
        protein_per_100g=_sayi(n.get("proteins_100g")),
        carb_per_100g=_sayi(n.get("carbohydrates_100g")),
        fat_per_100g=_sayi(n.get("fat_100g")),
        fiber_per_100g=_sayi(n.get("fiber_100g")),
        sugar_per_100g=_sayi(n.get("sugars_100g")),
        # DIKKAT: OFF sodyumu GRAM doner, proje MG kullaniyor - *1000.
        # Bu donusum atlanirsa sodyum degeri 1000 kat yanlis kaydedilir.
        sodium_mg_per_100g=(
            _sayi(n.get("sodium_100g")) * 1000 if n.get("sodium_100g") is not None else None
        ),
        image_url=ham.get("image_url") or ham.get("image_front_url"),
        serving_size_g=_serving_size_g(ham.get("serving_size")),
    )


async def fetch_product(barcode: str) -> OffProduct | None:
    """Barkodu OFF'ta arar. Urun yoksa None doner (hata FIRLATMAZ).

    Ag/saglayici hatasinda OpenFoodFactsError firlatir (502) - bu ikisi
    BILEREK ayri: 'urun yok' normal bir durum, 'saglayiciya ulasilamadi'
    gercek bir hata.
    """
    url = f"{settings.OPENFOODFACTS_BASE_URL}/api/v2/product/{barcode}.json"
    son_hata: Exception | None = None

    async with httpx.AsyncClient(timeout=settings.OFF_TIMEOUT_SECONDS) as istemci:
        for deneme in range(settings.OFF_MAX_RETRIES + 1):
            baslangic = time.perf_counter()
            try:
                yanit = await istemci.get(url)

                if yanit.status_code == 404:
                    return None  # OFF bazi surumlerde urun yoksa 404 doner

                if yanit.status_code in _RETRY_KODLARI:
                    if deneme < settings.OFF_MAX_RETRIES:
                        await _bekle(deneme, yanit)
                        continue
                    raise OpenFoodFactsError(f"OFF {yanit.status_code} dondu.")

                yanit.raise_for_status()
                govde = yanit.json()

                # Diger surumlerde 'bulunamadi' HTTP 200 + status=0 ile gelir.
                if govde.get("status") != 1 or "product" not in govde:
                    return None

                logger.info(
                    "OFF sorgusu | barkod=%s sure=%dms",
                    barcode, int((time.perf_counter() - baslangic) * 1000),
                )
                return _off_to_product(govde["product"])

            except httpx.TimeoutException as exc:
                son_hata = exc
                if deneme < settings.OFF_MAX_RETRIES:
                    await _bekle(deneme)
                    continue
                raise OpenFoodFactsError("OFF zaman asimina ugradi.") from exc
            except httpx.HTTPStatusError as exc:
                raise OpenFoodFactsError(f"OFF {exc.response.status_code} dondu.") from exc

    raise OpenFoodFactsError("OFF'a ulasilamadi.") from son_hata


async def _bekle(deneme: int, yanit: httpx.Response | None = None) -> None:
    if yanit is not None and (ra := yanit.headers.get("Retry-After")):
        try:
            await asyncio.sleep(min(float(ra), 10))
            return
        except ValueError:
            pass
    await asyncio.sleep((2 ** deneme) + random.uniform(0, 0.5))