"""Sohbet LLM sağlayıcı uygulamaları

NOT: Bu dosyanin istek/yeniden-deneme mantigi vision/providers.py ile
neredeyse birebir ayni. Bilerek AYRI tutuldu: T03/T04'un test edilmis
davranisini riske atmadan chat gelistirilebilsin. Ileride ortak bir
'llm_http.py' katmanina tasinabilir (kucuk bir refactor gorevi).
"""
import asyncio
import json
import logging
import random
import re
import time

import httpx

from app.core.config import settings
from app.services.llm_json import extract_json

from .base import (
    ADAYLAR_BASI, ADAYLAR_SONU, ChatError, ChatInvalidResponse, ChatProvider,
    ChatRateLimited, ChatResult, ChatTimeout, ChatUsage,
)

logger = logging.getLogger(__name__)

_RETRY_KODLARI = {429, 500, 502, 503, 504}


class OpenAICompatibleChatProvider(ChatProvider):
    base_url: str = ""
    default_model: str = ""

    def __init__(self) -> None:
        self.api_key = settings.GROQ_API_KEY
        self.model = settings.CHAT_MODEL or settings.GROQ_MODEL or self.default_model
        if not self.api_key:
            logger.warning(
                "GROQ_API_KEY boş - '%s' sağlayıcısı çalışmaz. "
                "Geliştirme için CHAT_PROVIDER=fake", self.name
            )

    def _govde(self, system_prompt: str, user_prompt: str) -> dict:
        govde = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": 0.3,
            "max_tokens": settings.CHAT_MAX_TOKENS,
        }
        if settings.CHAT_JSON_MODE:
            govde["response_format"] = {"type": "json_object"}
        if settings.CHAT_REASONING_EFFORT:
            govde["reasoning_effort"] = settings.CHAT_REASONING_EFFORT
            govde["reasoning_format"] = "hidden"
        return govde

    async def complete(self, system_prompt: str, user_prompt: str) -> ChatResult:
        baslangic = time.perf_counter()
        son_hata: Exception | None = None

        async with httpx.AsyncClient(timeout=settings.CHAT_TIMEOUT_SECONDS) as istemci:
            for deneme in range(settings.CHAT_MAX_RETRIES + 1):
                try:
                    yanit = await istemci.post(
                        f"{self.base_url}/chat/completions",
                        headers={"Authorization": f"Bearer {self.api_key}"},
                        json=self._govde(system_prompt, user_prompt),
                    )
                    if yanit.status_code in _RETRY_KODLARI:
                        if deneme < settings.CHAT_MAX_RETRIES:
                            await self._bekle(deneme, yanit)
                            continue
                        if yanit.status_code == 429:
                            raise ChatRateLimited()
                        raise ChatError(f"Sağlayıcı {yanit.status_code} döndü: {yanit.text[:200]}")

                    yanit.raise_for_status()
                    return self._sonuca_cevir(yanit.json(), baslangic)

                except httpx.TimeoutException as exc:
                    son_hata = exc
                    if deneme < settings.CHAT_MAX_RETRIES:
                        await self._bekle(deneme)
                        continue
                    raise ChatTimeout() from exc
                except httpx.HTTPStatusError as exc:
                    govde = exc.response.text[:400]
                    logger.error(
                        "Sohbet modeli %s hatası | model=%s | gövde=%s",
                        exc.response.status_code, self.model, govde,
                    )
                    raise ChatError(f"Saglayici {exc.response.status_code}: {govde}") from exc

        raise ChatError("Sohbet modeline ulaşılamadı.") from son_hata

    @staticmethod
    async def _bekle(deneme: int, yanit: httpx.Response | None = None) -> None:
        if yanit is not None and (ra := yanit.headers.get("Retry-After")):
            try:
                await asyncio.sleep(min(float(ra), 10))
                return
            except ValueError:
                pass
        sure = (2 ** deneme) + random.uniform(0, 0.5)
        await asyncio.sleep(sure)

    def _sonuca_cevir(self, ham: dict, baslangic: float) -> ChatResult:
        try:
            secim = ham["choices"][0]
            metin = secim["message"]["content"]
        except (KeyError, IndexError, TypeError) as exc:
            raise ChatInvalidResponse("Yanıt beklenen biçimde değil.") from exc

        if secim.get("finish_reason") == "length":
            raise ChatInvalidResponse(
                "Model yanıtı tamamlanamadan kesildi. CHAT_MAX_TOKENS'i arttır."
            )

        kullanim = ham.get("usage") or {}
        return ChatResult(
            data=extract_json(metin, error_cls=ChatInvalidResponse),
            raw_text=metin,
            usage=ChatUsage(
                provider=self.name, model=ham.get("model") or self.model,
                prompt_tokens=kullanim.get("prompt_tokens"),
                completion_tokens=kullanim.get("completion_tokens"),
                latency_ms=int((time.perf_counter() - baslangic) * 1000),
            ),
        )


class GroqChatProvider(OpenAICompatibleChatProvider):
    name = "groq"
    base_url = "https://api.groq.com/openai/v1"
    default_model = "llama-3.1-8b-instant"


# Sahte saglayici
_ADAYLAR_DESENI = re.compile(
    re.escape(ADAYLAR_BASI) + r"\s*(\{.*?\})\s*" + re.escape(ADAYLAR_SONU), re.DOTALL
)


class FakeChatProvider(ChatProvider):
    """Ag baglantisi GEREKTIRMEYEN sahte saglayici.

    Prompt'a gomulu ADAYLAR_BASI/ADAYLAR_SONU isaretleyicileri arasindaki
    JSON'u okur ve icinden secim yapar. Boylece 'uydurma tarif yok'
    davranisi ag baglantisi olmadan da uctan uca dogrulanabilir.
    """
    name = "fake"

    @property
    def is_fake(self) -> bool:
        return True

    async def complete(self, system_prompt: str, user_prompt: str) -> ChatResult:
        await asyncio.sleep(0.1)

        adaylar = []
        if m := _ADAYLAR_DESENI.search(user_prompt):
            try:
                adaylar = json.loads(m.group(1)).get("adaylar", [])
            except json.JSONDecodeError:
                adaylar = []

        # 'mercimek' geçiyorsa öne çıkar
        secilenler = sorted(
            adaylar, key=lambda a: "mercimek" not in a.get("title", "").lower()
        )[:3]
        ids = [a["id"] for a in secilenler]
        veri = {
            "mesaj": (
                f"{len(ids)} tarif buldum, umarim begenirsin!"
                if ids else "Uygun bir tarif bulamadim, kilerini genisletmeyi dener misin?"
            ),
            "onerilen_tarif_idleri": ids,
        }
        return ChatResult(
            data=veri, raw_text=json.dumps(veri, ensure_ascii=False),
            usage=ChatUsage(provider=self.name, model="fake-chat-1",
                           prompt_tokens=0, completion_tokens=0, latency_ms=100),
        )

class BrokenChatProvider(ChatProvider):
    """W4-T15: LLM çöktüğünde kural tabalı öneriye düşüldüğünü kanıtlar"""
    name = "broken"
    @property
    def is_fake(self) -> bool:
        return True

    async def complete(self, system_prompt: str, user_prompt: str) -> ChatResult:
        await asyncio.sleep(0.05)
        raise ChatTimeout("Bozuk saglayici: kasten basarisiz (W4-T15 testi).")
