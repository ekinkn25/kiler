"""Chatbot semalari. W3-T12'de RAG cikti sozlesmesi bunlara oturur."""
from datetime import datetime
from app.schemas.common import AppBaseModel, UtcDatetime

from pydantic import Field

from app.models.enums import ChatRole
from app.schemas.common import AppBaseModel


class ChatRequest(AppBaseModel):
    message: str = Field(
        min_length=1, max_length=500,
        examples=["Bugun hafif bir sey yemek istiyorum, ne onerirsin?"],
    )
    conversation_id: int | None = Field(
        default=None, description="Bos birakilirsa yeni sohbet baslatilir"
    )


class ChatMessageRead(AppBaseModel):
    id: int
    role: ChatRole
    content: str
    suggested_recipe_ids: list[str] = []
    from_cache: bool = False
    created_at: UtcDatetime


class ChatResponse(AppBaseModel):
    conversation_id: int
    message: ChatMessageRead