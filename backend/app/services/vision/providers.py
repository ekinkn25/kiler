"""Gorme modeli saglayici uygulamalari."""
"""openai ve groq aynı api sözleşmelerini kullanıyor """
import asyncio
import json
import logging
import random
import time

import httpx

from app.core.config import settings

from .base import (
    VisionInvalidResponse, VisionProvider, VisionRateLimited, VisionResult,
    VisionTimeout, VisionUsage, VisionError, extract_json, to_data_uri,
)

logger = logging.getLogger(__name__)

_RETRY_KODLARI = {429, 500, 502, 503, 504}


class OpenAICompatibleProvider(VisionProvider):
    """OpenAI uyumlu chat/completions ucu kullanan saglayicilar icin taban.

    Groq ve OpenAI ayni istek/yanit bicimini kullaniyor; farklari yalnizca
    taban adres ve model kimligi. Bu yuzden tek gerceklestirim yeterli.
    """

    base_url: str = ""
    default_model: str = ""

    def __init__(self) -> None:
        self.api_key = settings.VISION_API_KEY
        self.model = settings.VISION_MODEL or self.default_model
        if not self.api_key:
            logger.warning(
                "VISION_API_KEY bos - '%s' saglayicisi calismaz. "
                "Gelistirme icin VISION_PROVIDER=fake kullan.", self.name
            )

    # ------------------------------------------------------------------
    def _govde(self, image_bytes: bytes, prompt: str) -> dict: # istek gövdesi
        govde =  {
            "model": self.model,
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url",
                     "image_url": {"url": to_data_uri(image_bytes)}},
                ],
            }],
            # Modelin serbest metin yerine JSON dondurmesini zorlar.
            # "response_format": {"type": "json_object"},
            "temperature": 0.1,     # tanima gorevi - yaraticilik istemiyoruz
            "max_tokens": 1024,
        }
        if settings.VISION_JSON_MODE:
            govde["response_format"] = {"type": "json_object"}
        return govde

    async def analyze(self, image_bytes: bytes, prompt: str) -> VisionResult:
        baslangic = time.perf_counter()
        son_hata: Exception | None = None

        async with httpx.AsyncClient(timeout=settings.VISION_TIMEOUT_SECONDS) as istemci:
            for deneme in range(settings.VISION_MAX_RETRIES + 1):
                try:
                    yanit = await istemci.post(
                        f"{self.base_url}/chat/completions",
                        headers={"Authorization": f"Bearer {self.api_key}"},
                        json=self._govde(image_bytes, prompt),
                    )

                    if yanit.status_code in _RETRY_KODLARI:
                        if deneme < settings.VISION_MAX_RETRIES:
                            await self._bekle(deneme, yanit)
                            continue
                        if yanit.status_code == 429:
                            raise VisionRateLimited()
                        raise VisionError(
                            f"Saglayici {yanit.status_code} dondu: {yanit.text[:200]}")

                    yanit.raise_for_status()
                    return self._sonuca_cevir(yanit.json(), baslangic, len(image_bytes))

                except httpx.TimeoutException as exc:
                    son_hata = exc
                    if deneme < settings.VISION_MAX_RETRIES:
                        await self._bekle(deneme)
                        continue
                    raise VisionTimeout() from exc
                except httpx.HTTPStatusError as exc:
                    # 4xx gövdesi sorunun ne oldugunu SOYLER (yanlis model
                    # kimligi, desteklenmeyen istek bicimi vb.). Yutma.
                    govde = exc.response.text[:400]
                    logger.error(
                        "Gorme modeli %s hatasi | model=%s | govde=%s",
                        exc.response.status_code, self.model, govde,
                    )
                    raise VisionError(
                        f"Saglayici {exc.response.status_code}: {govde}"
                    ) from exc

        raise VisionError("Gorme modeline ulasilamadi.") from son_hata

    # ------------------------------------------------------------------
    @staticmethod
    async def _bekle(deneme: int, yanit: httpx.Response | None = None) -> None:
        """Ustel geri cekilme + jitter.

        Jitter (rastgele ek sure) es zamanli isteklerin ayni anda tekrar
        denemesini onler. Saglayici Retry-After basligi gonderdiyse ona uyulur.
        """
        if yanit is not None and (ra := yanit.headers.get("Retry-After")):
            try:
                await asyncio.sleep(min(float(ra), 10))
                return
            except ValueError:
                pass
        sure = (2 ** deneme) + random.uniform(0, 0.5)
        logger.info("Gorme modeli tekrar denenecek (%d. deneme, %.1f sn)", deneme + 1, sure)
        await asyncio.sleep(sure)

    def _sonuca_cevir(self, ham: dict, baslangic: float, boyut: int) -> VisionResult:
        try:
            secim = ham["choices"][0]
            metin = secim["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise VisionInvalidResponse("Yanit beklenen bicimde degil.") from exc
        
        if secim.get("finish_reason") == "length":
            logger.error(
                "Yanit token sinirinda kesildi (max_tokens=%s). Uretilen: %d karakter.",
                settings.VISION_MAX_TOKENS, len(metin),
            )
            raise VisionInvalidResponse(
                "Model yaniti tamamlanamadan kesildi. max_tokens degerini artir."
            )

        kullanim = ham.get("usage") or {}
        return VisionResult(
            data=extract_json(metin),
            raw_text=metin,
            usage=VisionUsage(
                provider=self.name,
                model=ham.get("model") or self.model,
                prompt_tokens=kullanim.get("prompt_tokens"),
                completion_tokens=kullanim.get("completion_tokens"),
                latency_ms=int((time.perf_counter() - baslangic) * 1000),
                image_bytes=boyut,
            ),
        )

class GroqVisionProvider(OpenAICompatibleProvider):
    name = "groq"
    base_url = "https://api.groq.com/openai/v1"
    default_model = "qwen/qwen3.6-27b"

    def _govde(self, image_bytes: bytes, prompt: str) -> dict:
        """Groq'a ozgu akil yurutme parametrelerini ekler.

        Taban sinifa KOYMUYORUZ: bu alanlar OpenAI'nin sozlesmesinde yok,
        gonderirsek 400 alirdik.
        """
        govde = super()._govde(image_bytes, prompt)
        if settings.VISION_REASONING_EFFORT:
            govde["reasoning_effort"] = settings.VISION_REASONING_EFFORT
            # 'hidden' = dusunme metni yanitta hic gelmesin. extract_json'daki
            # <think> temizligi yine de dursun: emniyet kemeri.
            govde["reasoning_format"] = "hidden"
        return govde


class OpenAIVisionProvider(OpenAICompatibleProvider):
    name = "openai"
    base_url = "https://api.openai.com/v1"
    # DOGRULA: platform.openai.com model listesinden guncel gorme modelini al.
    default_model = ""


class FakeVisionProvider(VisionProvider):
    """Ag baglantisi ve API anahtari GEREKTIRMEYEN sahte saglayici.

    NEDEN VAR:
      - W2-T04'ten W3-T13'e kadar tum akis API cagirmadan gelistirilebilir
      - Birim testleri hizli, deterministik ve bedava calisir
      - Kota/gecikme sorunu yasandiginda gelistirme durmaz

    Istem metnindeki anahtar kelimeye gore iki farkli yanit uretir.
    """

    name = "fake"

    SAHTE_MALZEMELER = {
        "items": [
            {"name": "domates", "confidence": 0.95},
            {"name": "yumurta", "confidence": 0.91},
            {"name": "süt", "confidence": 0.84},
            {"name": "maydanoz", "confidence": 0.72},
            {"name": "kaşar peyniri", "confidence": 0.66},
            {"name": "salatalık", "confidence": 0.41},
            {"name": "zencefil kökü", "confidence": 0.28},
        ]
    }

    SAHTE_OGUN = {
        "dish_name": "mercimek çorbası",
        "portion": "orta",
        "estimated_grams": 250,
        "confidence": 0.78,
        "scale_reference_found": True,
        "notes": "Tabağın yanında kaşık görüldü, ölçek referansı olarak kullanıldı.",
    }

    @property
    def is_fake(self) -> bool:
        return True

    async def analyze(self, image_bytes: bytes, prompt: str) -> VisionResult:
        await asyncio.sleep(0.15)  # gercekci gecikme benzetimi
        malzeme_mi = '"items"' in prompt
        veri = self.SAHTE_MALZEMELER if malzeme_mi else self.SAHTE_OGUN
        return VisionResult(
            data=veri,
            raw_text=json.dumps(veri, ensure_ascii=False),
            usage=VisionUsage(
                provider=self.name, model="fake-1",
                prompt_tokens=0, completion_tokens=0,
                latency_ms=150, image_bytes=len(image_bytes),
            ),
        )