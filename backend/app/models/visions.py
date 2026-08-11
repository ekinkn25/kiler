"""Gorme modeli cagri kayitlari.

DIKKAT: Fotografin KENDISI saklanmaz. Yalnizca SHA-256 ozeti tutulur.
Gerekce: (a) KVKK - kullanici mutfaginin/tabaginin goruntusu kisisel veridir,
(b) depolama maliyeti, (c) ozet sayesinde ayni fotografin tekrar analiz
edilmesi onlenebilir (onbellekleme).
"""
from __future__ import annotations

import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import enum_col

if TYPE_CHECKING:
    from app.models.user import User


class VisionRequestType(str, enum.Enum):
    MALZEME = "malzeme"   # mutfak/buzdolabi fotografi -> malzeme listesi
    OGUN = "ogun"         # tabak fotografi -> yemek + porsiyon tahmini


class VisionRequest(Base):
    """Tek bir gorme modeli cagrisinin kaydi.

    Iki ise yarar:
      1) Maliyet takibi (token ve gecikme) - W4-T13
      2) Dogruluk olcumu (eslesen/eslesmeyen malzeme sayisi) - W4-T11
    """

    __tablename__ = "vision_requests"
    __table_args__ = (
        Index("ix_vision_user_time", "user_id", "created_at"),
        Index("ix_vision_image_hash", "image_hash"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    # NULL olabilir: test ve olcum betikleri kullanicisiz cagri yapar
    user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE")
    )

    request_type = enum_col(VisionRequestType, nullable=False)
    image_hash: Mapped[str] = mapped_column(String(64), nullable=False)

    provider: Mapped[str] = mapped_column(String(20), nullable=False)
    model: Mapped[str | None] = mapped_column(String(80))

    prompt_tokens: Mapped[int | None] = mapped_column(Integer)
    completion_tokens: Mapped[int | None] = mapped_column(Integer)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    image_bytes: Mapped[int | None] = mapped_column(Integer)

    success: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    error_code: Mapped[str | None] = mapped_column(String(50))

    # W2-T04/T08'de doldurulacak: kac malzeme sozlukle eslesti
    matched_count: Mapped[int | None] = mapped_column(Integer)
    unmatched_count: Mapped[int | None] = mapped_column(Integer)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User | None"] = relationship()