"""Sohbet LLM servisi. app.services.vision ile ayni desen.

Kullanim:
    from app.services.chat import get_chat_provider
    sonuc = await get_chat_provider().complete(system_prompt, user_prompt)
"""
import logging
from functools import lru_cache

from app.core.config import settings

from .base import (
    ADAYLAR_BASI, ADAYLAR_SONU, ChatError, ChatInvalidResponse, ChatProvider,
    ChatRateLimited, ChatResult, ChatTimeout, ChatUsage,
)
from .providers import FakeChatProvider, GroqChatProvider, BrokenChatProvider

_SAGLAYICILAR: dict[str, type[ChatProvider]] = {
    "fake": FakeChatProvider,
    "groq": GroqChatProvider,
    "broken": BrokenChatProvider,
}


@lru_cache(maxsize=1)
def get_chat_provider() -> ChatProvider:
    ad = (settings.CHAT_PROVIDER or "fake").lower().strip()
    sinif = _SAGLAYICILAR.get(ad)
    if sinif is None:
        logging.getLogger(__name__).error(
            "Bilinmeyen CHAT_PROVIDER='%s'. Gecerli degerler: %s. "
            "Sahte saglayiciya dusuluyor.", ad, ", ".join(_SAGLAYICILAR)
        )
        sinif = FakeChatProvider
    return sinif()


def reset_chat_provider() -> None:
    get_chat_provider.cache_clear()


__all__ = [
    "ChatProvider", "ChatResult", "ChatUsage",
    "ChatError", "ChatTimeout", "ChatRateLimited", "ChatInvalidResponse",
    "get_chat_provider", "reset_chat_provider",
    "ADAYLAR_BASI", "ADAYLAR_SONU",
    "FakeChatProvider", "GroqChatProvider",
]