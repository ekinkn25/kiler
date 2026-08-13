"""Chatbot RAG ucu. W2-T09."""
import logging

from fastapi import APIRouter, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.schemas import ChatRequest, ErrorResponse, RagChatResponse
from app.services.chat_rag import chat_completion

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "",
    response_model=RagChatResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Sohbet - RAG destekli tarif onerisi",
    description=(
        "Mesajdan niyet ve kisitlar (hafif/doyurucu, malzeme, sure) cikarilir, "
        "kiler+profil+diyet/alerjen filtreleriyle GERCEK aday tarifler getirilir, "
        "LLM SADECE bu adaylar arasindan secim yapar. onerilen_tarif_idleri her "
        "zaman gercek MongoDB tarif kimlikleridir; model listede olmayan bir id "
        "uydurursa sunucu tarafinda elenir."
    ),
    responses={
        status.HTTP_403_FORBIDDEN: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_429_TOO_MANY_REQUESTS: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def chat(
    data: ChatRequest, db: DbSession, mongo_db: MongoDb, current_user: ActiveUser,
) -> RagChatResponse:
    sonuc = await chat_completion(
        db, mongo_db, current_user,
        message=data.message, conversation_id=data.conversation_id,
    )
    return RagChatResponse(**sonuc)