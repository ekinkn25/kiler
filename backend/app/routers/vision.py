"""görme modeli uçları"""
import logging
from typing import Annotated
from fastapi import APIRouter, File, UploadFile, status

from app.core.deps import ActiveUser, DbSession, MongoDb
from app.core.exceptions import AppError
from app.schemas import DetectedIngredient, ErrorResponse, MealEstimate
from app.services.vision_ingredients import detect_ingredients
from app.services.meal_estimation import estimate_meal
from app.services.vision import ALLOWED_IMAGE_TYPES, EmptyImage, UnsupportedImageType

logger = logging.getLogger(__name__)

router = APIRouter()

class UnsupportedImageType(AppError):
    status_code = status.HTTP_415_UNSUPPORTED_MEDIA_TYPE
    code = "unsupported_image_type"
    message = "Yalnizca JPEG, PNG ve WEBP fotograflar kabul ediliyor."


class EmptyImage(AppError):
    status_code = status.HTTP_400_BAD_REQUEST
    code = "empty_image"
    message = "Bos dosya gonderildi."


@router.post(
    "/ingredients",
    response_model=list[DetectedIngredient],
    summary="Fotograftan malzeme cikarma",
    description=(
        "Buzdolabi/mutfak fotografini analiz eder ve sozlukle eslestirilmis "
        "malzeme listesi doner. canonical_name null ise malzeme sozlukte yok; "
        "istemci bunlari gri gosterip kilere eklemeyi devre disi birakmali."
    ),
    responses={
        status.HTTP_413_CONTENT_TOO_LARGE: {"model": ErrorResponse},
        status.HTTP_415_UNSUPPORTED_MEDIA_TYPE: {"model": ErrorResponse},
        status.HTTP_429_TOO_MANY_REQUESTS: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def vision_ingredients(
    db: DbSession,
    current_user: ActiveUser,
    file: Annotated[UploadFile, File(description="Buzdolabi veya mutfak fotografi")],
) -> list[DetectedIngredient]:
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise UnsupportedImageType(
            f"'{file.content_type}' desteklenmiyor. JPEG, PNG veya WEBP gonder."
        )

    ham = await file.read()
    if not ham:
        raise EmptyImage()

    logger.info(
        "Malzeme fotografi alindi | kullanici=%s | dosya=%s | %d KB",
        current_user.id, file.filename, len(ham) // 1024,
    )
    sonuc = await detect_ingredients(db, raw_image=ham, user_id=current_user.id)
    return sonuc.items


@router.post(
    "/meal",
    response_model=MealEstimate,
    summary="Fotoğraftan öğün ve kalori tahmini",
    description=(
        "Tabaktan fotoğrafını analiz eder; yemek adı, porsiyon büyüklüğü, gram ve kalori tahmini döner.\n\n"
        "Bu bir kayıt değildir; `is_estimate` ve `requires_confirmation` her zaman `true` döner; "
        "öğün günlüğe ancak kullanıcı onayladıktan sonra yazılır.\n\n"
    ),
    responses={
        status.HTTP_413_REQUEST_ENTITY_TOO_LARGE: {"model": ErrorResponse},
        status.HTTP_415_UNSUPPORTED_MEDIA_TYPE: {"model": ErrorResponse},
        status.HTTP_429_TOO_MANY_REQUESTS: {"model": ErrorResponse},
        status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse},
    },
)
async def vision_meal(
        db: DbSession,
        mongo_db: MongoDb,
        current_user: ActiveUser,
        file: Annotated[UploadFile, File(description="tabak fotoğrafı")],
) -> MealEstimate:
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise UnsupportedImageType(
            f"'{file.content_type}' desteklenemiyor. Jpeg png veya webp gönderebilirsin."
        )
    ham = await file.read()
    if not ham: 
        raise EmptyImage()

    logger.info("Öğün fotoğrafı alındı | kullanıcı=%s | dosya=%s | %d KB", current_user.id, file.filename, len(ham)//1024,)
    tahmin = await estimate_meal(
        db, mongo_db, raw_image=ham, user_id=current_user.id
    )
    return MealEstimate(**tahmin)