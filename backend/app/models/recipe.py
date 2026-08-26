"""artık sadece veri kaydeden bir uygulamadan çıkıp "Öğrenen ve Karar Veren" (AI-Driven) bir akıllı asistan. Sistemin tavsite motorunun(recomandation engine) veri altyapısıdır
kullanıcının tariflerle olan her türlü etkileşimini kayıt altına alan event logdur(olay günlüğü)"""
from __future__ import annotations
import json

from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING

from sqlalchemy import (
    CheckConstraint, DateTime, Float, ForeignKey, Index, Integer, String,
    UniqueConstraint, func, Text, and_, select
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import FeedbackAction, TasteDimension, FeedbackReason
from app.models.mixins import enum_col

if TYPE_CHECKING:
    from app.models.catalog import Ingredient
    from app.models.user import User

def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class SwipeSession(Base):
    __tablename__ = "swipe_sessions"
    __table_args__ = (Index("ix_swipe_user_started", "user_id", "started_at"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    ended_at: Mapped[datetime | None] = mapped_column(DateTime)
    filters_json: Mapped[str | None] = mapped_column(Text)
    shown_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    user: Mapped["User"] = relationship(back_populates="swipe_sessions")
    feedbacks: Mapped[list["RecipeFeedback"]] = relationship(back_populates="session")

    @property
    def filters(self)-> dict:
        return json.loads(self.filters_json) if self.filters_json else {}
    
    def set_filter(self, key:str, value) -> None:
        mevcut = self.filters
        mevcut[key] = value
        self.filters_json = json.dumps(mevcut, ensure_ascii=False)

    def tighten_time_limit(self, minutes: int = 30) -> None:
        simdiki = self.filters.get("max_total_time")
        self.set_filter("max_total_time", min(simdiki, minutes) if simdiki else minutes)

    def __repr__(self) -> str:
        return f"<SwipeSession id={self.id} user={self.user_id} shown={self.shown_count}>"

class RecipeFeedback(Base):
    """APPEND-ONLY olay gunlugu. Ogrenen AI'nin egitim sinyali.

    recipe_id, MongoDB recipes._id degerinin str() hali (24 karakter hex).
    """
    __tablename__ = "recipe_feedback"
    __table_args__ = (
        CheckConstraint("rating IS NULL OR (rating BETWEEN 1 AND 5)", name="rating_range"),
        CheckConstraint("reason IS NULL OR action = 'begenmedim'", name="reason_only_on_dislike"),
        CheckConstraint("missing_ingredient_id IS NULL OR reason = 'malzeme_yok'", name="missing_needs_reason"),
        Index("ix_feedback_user_recipe", "user_id", "recipe_id"),
        Index("ix_feedback_session", "session_id", "recipe_id"),
        Index("ix_feedback_user_reason_time", "user_id", "reason", "created_at"),    
        Index("ix_feedback_user_action_time", "user_id", "action", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    recipe_id: Mapped[str] = mapped_column(String(24), nullable=False) #polygot persistence
    #normalde rdbms'temlerde recipe_id Integer olur ve recipes tablosuna ForeignKey ile bağlanır.
    #tarifler karmaşık ve iç içe geçmiş (nested) yapılar oldukları için MongoDB'de (NoSQL) tutuluyor. MongoDB'nin ürettiği varsayılan ID'ler (ObjectId) 24 karakterlik Hex (onaltılık) string'lerdir. Bu kolon sayesinde SQLite/PostgreSQL dünyası ile MongoDB dünyası arasında  bir köprü kuruldu.

    session_id: Mapped[int | None] = mapped_column(
        ForeignKey("swipe_sessions.id", ondelete="SET NULL")
    )
    missing_ingredient_id: Mapped[int | None] = mapped_column(
        ForeignKey("ingredients.id", ondelete="SET NULL")
    )

    action = enum_col(FeedbackAction, nullable=False)
    reason = enum_col(FeedbackReason, nullable=True)

    rating: Mapped[int | None] = mapped_column(Integer)
    servings_cooked: Mapped[float | None] = mapped_column(Float)
    comment: Mapped[str | None] = mapped_column(String(500))

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="recipe_feedback")
    session:Mapped["SwipeSession | None"] = relationship(back_populates="feedbacks")


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

def _recipe_ids(kosul) -> select:
    return select(RecipeFeedback.recipe_id).where(kosul)


def ids_seen_in_session(session_id: int) -> select:
    """Bu oturumda gosterilmis tum tarifler - tekrar gelmemeli."""
    return _recipe_ids(RecipeFeedback.session_id == session_id)


def ids_permanently_disliked(user_id: int) -> select:
    """'Sevmedim' denenler - bir daha HIC onerilmez."""
    return _recipe_ids(and_(
        RecipeFeedback.user_id == user_id,
        RecipeFeedback.reason == FeedbackReason.SEVMEDIM,
    ))


def ids_missing_ingredient_recent(user_id: int, days: int = 7) -> select:
    """'Malzemem yok' denenler - 7 gun elenir, sonra tekrar denenir."""
    return _recipe_ids(and_(
        RecipeFeedback.user_id == user_id,
        RecipeFeedback.reason == FeedbackReason.MALZEME_YOK,
        RecipeFeedback.created_at > utcnow() - timedelta(days=days),
    ))


def ids_already_planned(user_id: int, days: int = 3) -> select:
    """'Yapacagim' veya 'kaydetti' denenler - kisa sure tekrar gosterme."""
    return _recipe_ids(and_(
        RecipeFeedback.user_id == user_id,
        RecipeFeedback.action.in_([FeedbackAction.YAPACAGIM, FeedbackAction.KAYDETTI]),
        RecipeFeedback.created_at > utcnow() - timedelta(days=days),
    ))