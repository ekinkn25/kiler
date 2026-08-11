from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Date, DateTime, Float, ForeignKey, Index, String, UniqueConstraint, func, Integer, Text, CheckConstraint
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import LogSource, MealType
from app.models.mixins import enum_col

if TYPE_CHECKING:
    from app.models.user import User


class MealLog(Base):
    """Ogun kaydi.

    ANLIK GORUNTU ILKESI: item_name, calories ve makrolar kayit aninda
    KOPYALANIR. Urun 3 ay sonra duzeltilse bile gecmis gunlerin toplami
    degismez. product_id / recipe_id yalnizca izlenebilirlik icindir.
    """
    """Sorun: Eğer MealLog tablosunda sadece product_id tutsaydın ve "Bu kullanıcının bugünkü toplam kalorisi nedir?" sorusunu bir JOIN ile Product tablosundan çekseydin büyük bir risk alırdın. Çünkü 3 ay sonra bir üretici ürünün içeriğini değiştirirse veya sistemdeki bir admin o ürünün kalorisini güncellerse, kullanıcının 3 ay önceki günlük raporu da aniden değişirdi."""
    """Ürün yendiği anda (kayıt anında) o ürünün item_name, calories, protein_g gibi tüm değerleri MealLog tablosuna "sabit (hard-copied)" olarak kopyalanır. Makroların bu şekilde dondurularak saklanması, özellikle günlük 110-120 gram gibi spesifik protein hedeflerini katı bir şekilde takip eden kullanıcılar için veri tutarlılığını ömür boyu garanti altına alır."""
    __tablename__ = "meal_logs"
    __table_args__ = (
        #Buraya koyduğun bu bileşik indeksler (Composite Index) sayesinde veritabanı motoru tüm tabloyu baştan sona taramak (Full Table Scan) yerine, doğrudan indeks ağacına (B-Tree) giderek veriyi milisaniyeler içinde bulur. Bu, sunucu maliyetlerini (CPU/RAM) inanılmaz derecede düşüren usta işi bir dokunuştur.
        Index("ix_meals_user_date", "user_id", "logged_date"),
        Index("ix_meals_user_date_type", "user_id", "logged_date", "meal_type"),
        CheckConstraint(
            "local_hour IS NULL OR (local_hour BETWEEN 0 AND 23)", 
            name="local_hour_range",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    logged_date: Mapped[date] = mapped_column(Date, nullable=False)
    meal_type = enum_col(MealType, nullable=False)
    source = enum_col(LogSource, nullable=False, default=LogSource.MANUEL)

    product_id: Mapped[int | None] = mapped_column(ForeignKey("products.id"))
    ingredient_id: Mapped[int | None] = mapped_column(ForeignKey("ingredients.id"))
    recipe_id: Mapped[str | None] = mapped_column(String(24))

    item_name: Mapped[str] = mapped_column(String(200), nullable=False)
    servings: Mapped[float] = mapped_column(Float, default=1, nullable=False)
    quantity_g: Mapped[float | None] = mapped_column(Float)

    calories: Mapped[float] = mapped_column(Float, nullable=False)
    protein_g: Mapped[float | None] = mapped_column(Float)
    carb_g: Mapped[float | None] = mapped_column(Float)
    fat_g: Mapped[float | None] = mapped_column(Float)
    fiber_g: Mapped[float | None] = mapped_column(Float)
    sugar_g: Mapped[float | None] = mapped_column(Float)
    sodium_mg: Mapped[float | None] = mapped_column(Float)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    ingredients_json: Mapped[str | None] = mapped_column(Text)
    local_hour: Mapped[int | None] = mapped_column(Integer)

    user: Mapped["User"] = relationship(back_populates="meal_logs")

    @property
    def ingredients(self) -> list[str]:
        return json.loads(self.ingredients_json) if self.ingredients_json else []

    def set_ingredients(self, isimler: list[str]) -> None:
        self.ingredients_json = json.dumps(isimler, ensure_ascii=False) if isimler else None


class WeightLog(Base):
    __tablename__ = "weight_logs"
    __table_args__ = (
        UniqueConstraint("user_id", "logged_date", name="uq_weight_user_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    logged_date: Mapped[date] = mapped_column(Date, nullable=False)
    weight_kg: Mapped[float] = mapped_column(Float, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="weight_logs")