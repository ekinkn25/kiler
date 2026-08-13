"""Chatbot RAG ucu. W2-T09 + W2-T10 (foto destegi)."""
import logging
from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.schemas import ErrorResponse, RagChatResponse
from app.services.chat_rag import chat_completion
from app.services.vision import ALLOWED_IMAGE_TYPES, EmptyImage, UnsupportedImageType

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "",
    response_model=RagChatResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Sohbet - RAG destekli tarif onerisi ve foto ile malzeme tespiti",
    description=(
        "multipart/form-data. Foto EKLENMEZSE duz form-post olarak da "
        "gonderilebilir (file alani opsiyonel).\n\n"
        "Foto eklenirse W2-T04 malzeme tespiti calisir; donen malzemeler "
        "ONAY BEKLER, DOGRUDAN KILEYE YAZILMAZ. Onaylamak icin "
        "POST /pantry/confirm-detected kullan."
    ),
    responses={
        status.HTTP_403_FORBIDDEN: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_415_UNSUPPORTED_MEDIA_TYPE: {"model": ErrorResponse},
        status.HTTP_429_TOO_MANY_REQUESTS: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def chat(
    db: DbSession,
    mongo_db: MongoDb,
    current_user: ActiveUser,
    message: Annotated[str, Form(min_length=1, max_length=500)],
    conversation_id: Annotated[int | None, Form()] = None,
    file: Annotated[UploadFile | None, File()] = None,
) -> RagChatResponse:
    ham_gorsel = None
    if file is not None:
        if file.content_type not in ALLOWED_IMAGE_TYPES:
            raise UnsupportedImageType(
                f"'{file.content_type}' desteklenmiyor. JPEG, PNG veya WEBP gonder."
            )
        ham_gorsel = await file.read()
        if not ham_gorsel:
            raise EmptyImage()

    sonuc = await chat_completion(
        db, mongo_db, current_user,
        message=message, conversation_id=conversation_id, raw_image=ham_gorsel,
    )
    return RagChatResponse(**sonuc)