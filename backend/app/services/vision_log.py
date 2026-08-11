"""Gorme modeli cagrilarinin kaydi. Maliyet takibi ve dogruluk olcumu icin."""
import logging

from sqlalchemy.orm import Session

from app.models import VisionRequest, VisionRequestType
from app.services.vision import VisionResult

logger = logging.getLogger(__name__)


def log_vision_call(
    db: Session,
    *,
    request_type: VisionRequestType,
    image_hash: str,
    result: VisionResult | None = None,
    error_code: str | None = None,
    user_id: int | None = None,
    image_bytes: int | None = None,
    provider: str = "bilinmiyor",
) -> VisionRequest:
    """Basarili ve basarisiz cagrilarin ikisini de kaydeder.

    Basarisiz cagrilar da kaydedilmeli: hata orani, maliyet analizinin ve
    W4-T11 dogruluk olcumunun parcasi.
    """
    kayit = VisionRequest(
        user_id=user_id,
        request_type=request_type,
        image_hash=image_hash,
        provider=result.usage.provider if result else provider,
        model=result.usage.model if result else None,
        prompt_tokens=result.usage.prompt_tokens if result else None,
        completion_tokens=result.usage.completion_tokens if result else None,
        latency_ms=result.usage.latency_ms if result else None,
        image_bytes=result.usage.image_bytes if result else image_bytes,
        success=error_code is None,
        error_code=error_code,
    )
    db.add(kayit)
    db.commit()
    db.refresh(kayit)

    logger.info(
        "Gorme cagrisi: tip=%s saglayici=%s sure=%sms token=%s durum=%s",
        request_type.value, kayit.provider, kayit.latency_ms,
        (kayit.prompt_tokens or 0) + (kayit.completion_tokens or 0),
        "OK" if kayit.success else error_code,
    )
    return kayit