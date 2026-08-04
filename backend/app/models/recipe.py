"""artık sadece veri kaydeden bir uygulamadan çıkıp "Öğrenen ve Karar Veren" (AI-Driven) bir akıllı asistan. Sistemin tavsite motorunun(recomandation engine) veri altyapısıdır
kullanıcının tariflerle olan her türlü etkileşimini kayıt altına alan event logdur(olay günlüğü)"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    CheckConstraint, DateTime, Float, ForeignKey, Index, Integer, String,
    UniqueConstraint, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import FeedbackAction, TasteDimension
from app.models.mixins import enum_col

if TYPE_CHECKING:
    from app.models.user import User


class RecipeFeedback(Base):
    """APPEND-ONLY olay gunlugu. Ogrenen AI'nin egitim sinyali.

    recipe_id, MongoDB recipes._id degerinin str() hali (24 karakter hex).
    """
    __tablename__ = "recipe_feedback"
    __table_args__ = (
        CheckConstraint("rating IS NULL OR (rating BETWEEN 1 AND 5)", name="rating_range"),
        Index("ix_feedback_user_recipe", "user_id", "recipe_id"),
        Index("ix_feedback_user_time", "user_id", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    recipe_id: Mapped[str] = mapped_column(String(24), nullable=False) #polygot persistence
    #normalde rdbms'temlerde recipe_id Integer olur ve recipes tablosuna ForeignKey ile bağlanır.
    #tarifler karmaşık ve iç içe geçmiş (nested) yapılar oldukları için MongoDB'de (NoSQL) tutuluyor. MongoDB'nin ürettiği varsayılan ID'ler (ObjectId) 24 karakterlik Hex (onaltılık) string'lerdir. Bu kolon sayesinde SQLite/PostgreSQL dünyası ile MongoDB dünyası arasında  bir köprü kuruldu.
    action = enum_col(FeedbackAction, nullable=False)
    rating: Mapped[int | None] = mapped_column(Integer)
    servings_cooked: Mapped[float | None] = mapped_column(Float)
    comment: Mapped[str | None] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="recipe_feedback")


class RecipeFavorite(Base): #kullanıcının favorilerim listesi
    __tablename__ = "recipe_favorites"
    __table_args__ = (
        UniqueConstraint("user_id", "recipe_id", name="uq_favorite_user_recipe"),
    ) #user bir yemeği birden fazla kez beğenemez

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    recipe_id: Mapped[str] = mapped_column(String(24), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="recipe_favorites")


class UserTasteWeight(Base):
    """Ogrenilen zevk vektoru (-1 .. +1).

    KURAL: Bu tablo user_diet_tags / user_allergens kisitlarini ASLA ezemez.
    Ogrenilen tercih, beyan edilen kisitin uzerine cikamaz (alerjen guvenligi).
    """
    __tablename__ = "user_taste_weights"
    __table_args__ = (
        UniqueConstraint("user_id", "dimension", "taste_key", name="uq_taste_user_dim_key"),
        CheckConstraint("weight BETWEEN -1 AND 1", name="weight_range"), #makine öğrenmesi modelinde işimize yarayacak 
        #ayrıca kullanıcı bir tarife önceden puan verip vermediğini anında bulur ve kullanıcının zaman içindeki davranış değişimini (trend) analiz etmek için (user_id, recipe_id) ve (user_id, crated_at) indeksleri yerleştirildi.
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    dimension = enum_col(TasteDimension, nullable=False)
    taste_key: Mapped[str] = mapped_column(String(100), nullable=False)
    weight: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    event_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="taste_weights")