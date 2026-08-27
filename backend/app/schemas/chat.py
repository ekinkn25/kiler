"""Chatbot semalari. W3-T12'de RAG cikti sozlesmesi bunlara oturur."""
from datetime import datetime
from app.schemas.common import AppBaseModel, UtcDatetime

from pydantic import Field

from app.models.enums import ChatRole
from app.schemas.common import AppBaseModel
from app.schemas.pantry import DetectedIngredient


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

class RagChatResponse(AppBaseModel):
    """POST /chat çıktı sözleşmesi"""
    conversation_id: int
    mesaj: str
    onerilen_tarif_idleri: list[str] = []
    uygulanan_filtreler: list[str] = []
    from_cache: bool = False
    detected_ingredients: list[DetectedIngredient] = []
    degraded: bool = False
    degraded_reason: str | None = None