"""
Sogbet LLM sağlayıcısının ortak tipleri ve hataları.
app.services.vision.base ile aynı desen

"""
from __future__ import annotations

import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass

from app.core.exceptions import ExternalServiceError

logger = logging.getLogger(__name__)

# Aday tarif listesini prompt i.inde işaretlemek icin kullanılır. FakeChatProvider bu işaretleyiciler arasındaki JSON'u ayrıştırır; gercek sağlayıcıda ise modele 'bu aralığın dışına çıkma' der.
ADAYLAR_BASI = "===ADAYLAR_JSON_BASI==="
ADAYLAR_SONU = "===ADAYLAR_JSON_SONU==="


class ChatError(ExternalServiceError):
    code = "chat_error"
    message = "Sohbet asistanı şu anda yanıt veremiyor."


class ChatTimeout(ChatError):
    code = "chat_timeout"
    message = "Yanıt zaman aşımına uğradı. Tekrar dener misin?"


class ChatRateLimited(ChatError):
    code = "chat_rate_limited"
    message = "Şu anda çok yoğunuz. Birazdan tekrar dene."


class ChatInvalidResponse(ChatError):
    code = "chat_invalid_response"
    message = "Anlamlı bir yanıt oluşturamadim."


@dataclass(frozen=True, slots=True)
class ChatUsage:
    provider: str
    model: str | None
    prompt_tokens: int | None
    completion_tokens: int | None
    latency_ms: int


@dataclass(frozen=True, slots=True)
class ChatResult:
    data: dict
    raw_text: str
    usage: ChatUsage


class ChatProvider(ABC):
    """Sohbet LLM sağlayıcısının sözleşmesi. Çağıran kod (chat_rag.py)
    hangi sağlayıcının arkada oldugunu bilmiyor."""

    name: str = "abstract"

    @abstractmethod
    async def complete(self, system_prompt: str, user_prompt: str) -> ChatResult:
        """Sohbet isteğini modele gönderir, ayrıştırılmış JSON doner."""

    @property
    def is_fake(self) -> bool:
        return False