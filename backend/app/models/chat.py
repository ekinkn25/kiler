from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean, DateTime, ForeignKey, Index, Integer, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ChatRole
from app.models.mixins import enum_col

if TYPE_CHECKING:
    from app.models.user import User


    """
    class ... diye yaptıklarımız sqlalchemy tarafından Base sınıfı bu python sınfıını alıtr ve dbde bir tabloya dönüştürür(orm : object relational mapping)

    __table_args__: tablo seviyesindeki metadatakar ve kurallarıdır fonksiyon argümanı gibi düşünebiliriz db motoruna tablo oluşturulurken ekstra emirler verir buradaki (Index("ix_conv_user_last", "user_id", "last_message_at"),) şu demektir db bu iki sütunu kullanarak arka planda bir arama fihristi(B-tree Index) oluşturur ki, kullanıcı en son mesajlaştığı sohbetleri çekerken tabloyu baştan sona aramak yerine anında bulabileyim

    Mapped[int]: tip belirleyicidir bu sayı kesinlikle int olacak demektir
    mapped_column(primary_key=True) db komutu bu ise sql alchemynin asıl motorudur bu alanı bir sütun yap bunu pk yap demektir

    back-populates: python sqlalchemye bu iki model birbiriyle konuşuyor birine bir şey eklersem diğerinin listesini de otomatik güncelle demektir 

    cascade = "all, delete-orphan": eğer conversationu silersen o sohbetin içindeki mesajlarını da sil demek(all)
    """


class ChatConversation(Base):
    __tablename__ = "chat_conversations"
    __table_args__ = (Index("ix_conv_user_last", "user_id", "last_message_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    title: Mapped[str | None] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime)

    user: Mapped["User"] = relationship(back_populates="conversations")
    messages: Mapped[list["ChatMessage"]] = relationship(
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="ChatMessage.created_at",
    )


class ChatMessage(Base):
    __tablename__ = "chat_messages"
    __table_args__ = (Index("ix_msg_conv_time", "conversation_id", "created_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    conversation_id: Mapped[int] = mapped_column(
        ForeignKey("chat_conversations.id", ondelete="CASCADE"), nullable=False
    )
    role = enum_col(ChatRole, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    # JSON dizi: LLM'in onerdigi MongoDB tarif _id'leri
    suggested_recipe_ids: Mapped[str | None] = mapped_column(Text)
    prompt_tokens: Mapped[int | None] = mapped_column(Integer)
    completion_tokens: Mapped[int | None] = mapped_column(Integer)
    from_cache: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    conversation: Mapped["ChatConversation"] = relationship(back_populates="messages")


class LlmCache(Base):
    """LLM yanit onbellegi. Ayni baglamda ayni soru API'ye gitmeden yanitlanir."""
    __tablename__ = "llm_cache"
    __table_args__ = (Index("ix_cache_expires", "expires_at"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    # sha256(normalize_soru + kiler_parmak_izi + profil_parmak_izi)
    cache_key: Mapped[str] = mapped_column(
        String(64), unique=True, nullable=False, index=True
    )
    response_json: Mapped[str] = mapped_column(Text, nullable=False)
    model: Mapped[str | None] = mapped_column(String(80))
    hit_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    expires_at: Mapped[datetime | None] = mapped_column(DateTime)