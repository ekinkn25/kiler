from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, Float, ForeignKey, Index,
    String, UniqueConstraint, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import PantryEventType, ShoppingSource, UnitCode, UnitType
from app.models.mixins import TimestampMixin, enum_col

if TYPE_CHECKING:
    from app.models.catalog import Ingredient, Product
    from app.models.user import User


class PantryItem(TimestampMixin, Base):
    """Kiler envanteri. Miktarlar TEMEL birimde saklanir (mass->g, volume->ml, count->adet).
    Bu sınıf kullanıcının kilerinde ŞU AN ne olduğunu temsil eder
    Veritabanı Seviyesinde Güvenlik (CheckConstraint ve UniqueConstraint):
    UniqueConstraint("user_id", "ingredient_id"): Bir kullanıcının kilerinde iki tane ayrı "Kırmızı Mercimek" kaydı olamaz. Eğer kullanıcı tekrar mercimek eklerse, sistem yeni bir satır oluşturmak yerine var olan satırın miktarını (quantity) güncellemelidir. Bu kısıtlama, veritabanında veri tekrarını (duplication) kesin olarak engeller."""
    __tablename__ = "pantry_items"
    __table_args__ = (
        UniqueConstraint("user_id", "ingredient_id", name="uq_pantry_user_ingredient"),
        CheckConstraint("quantity_base >= 0", name="ck_pantry_quantity_nonnegative"),
        Index("ix_pantry_user_active", "user_id", "is_active"),
        Index("ix_pantry_expiry", "expiry_date"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"), nullable=False)
    product_id: Mapped[int | None] = mapped_column(ForeignKey("products.id"))
    custom_name: Mapped[str | None] = mapped_column(String(150))

    quantity_base: Mapped[float] = mapped_column(Float, nullable=False, default=0) #dbde mercimek gram cinsinden yazacak
    unit_type = enum_col(UnitType, nullable=False)
    display_unit = enum_col(UnitCode, nullable=False)
    min_threshold_base: Mapped[float] = mapped_column(Float, default=0, nullable=False)

    expiry_date: Mapped[date | None] = mapped_column(Date)
    opened_at: Mapped[date | None] = mapped_column(Date)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    last_restocked_at: Mapped[datetime | None] = mapped_column(DateTime)

    user: Mapped["User"] = relationship(back_populates="pantry_items")
    ingredient: Mapped["Ingredient"] = relationship(back_populates="pantry_items")
    product: Mapped["Product | None"] = relationship()
    events: Mapped[list["PantryEvent"]] = relationship(back_populates="pantry_item")

    @property
    def is_low(self) -> bool:
        """Kritik esigin altina dustu mu? API yanitina hesaplanan alan olarak eklenir."""
        """Bu bir veritabanı kolonu değildir, Python seviyesinde anlık hesaplanan bir fonksiyondur. Kilerdeki miktar, kullanıcının belirlediği kritik eşiğin (min_threshold_base) altına düştüğünde True döner. FastAPI bu modeli JSON'a çevirirken bu fonksiyonu çalıştırıp arayüze anında "Bu ürün azalmış, uyarı göster" bilgisini geçer."""
        return self.quantity_base <= self.min_threshold_base

    def __repr__(self) -> str:
        return f"<PantryItem user={self.user_id} ing={self.ingredient_id} qty={self.quantity_base}>"


class PantryEvent(Base):
    """APPEND-ONLY kiler hareket gunlugu. Bu tabloda UPDATE/DELETE YAPILMAZ.

    Israf raporu, tuketim hizi tahmini, akilli esik ve ongorulu alisveris
    listesinin veri kaynagidir. Gecmis kayit tutulmazsa bu ozellikler
    geriye donuk uretilemez.
    """
    """Kullanıcı "200 gram un harcadım" dediğinde, PantryItem içindeki un 200 gram azalır, ancak PantryEvent tablosuna quantity_base_delta = -200 şeklinde bir olay (event) yazılır."""

    """ondelete="SET NULL" Stratejisi:
    User silinirse her şey siliniyordu (CASCADE), bunu daha önce konuşmuştuk. Ancak burada, kilerdeki bir eşya (PantryItem) silinirse, olay günlüğündeki o eşyaya ait geçmişin silinmemesi (SET NULL) emredilmiş. Neden? Çünkü kullanıcı o ürünü bitirip kilerinden silse bile, senin algoritmalarının o kullanıcının aylık tüketim hızını (velocity) hesaplayabilmesi için bu geçmişe ihtiyacı var."""
    __tablename__ = "pantry_events"
    __table_args__ = (
        Index("ix_events_user_time", "user_id", "created_at"),
        Index("ix_events_user_ing_time", "user_id", "ingredient_id", "created_at"),
        Index("ix_events_user_type", "user_id", "event_type"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"), nullable=False)
    # Kiler satiri silinse bile gecmis kalmali -> SET NULL
    pantry_item_id: Mapped[int | None] = mapped_column(
        ForeignKey("pantry_items.id", ondelete="SET NULL")
    )

    event_type = enum_col(PantryEventType, nullable=False)
    quantity_base_delta: Mapped[float] = mapped_column(Float, nullable=False)
    unit_type = enum_col(UnitType, nullable=False)

    recipe_id: Mapped[str | None] = mapped_column(String(24))
    estimated_cost: Mapped[float | None] = mapped_column(Float)
    event_note: Mapped[str | None] = mapped_column(String(255))

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="pantry_events")
    ingredient: Mapped["Ingredient"] = relationship()
    pantry_item: Mapped["PantryItem | None"] = relationship(back_populates="events")


class ShoppingListItem(Base):
    """hibrit bağlantı vardır kullanıcı sistemde olmayan bir şey eklerse de sistem buna izin verir"""
    __tablename__ = "shopping_list_items"
    __table_args__ = (
        UniqueConstraint("user_id", "ingredient_id", name="uq_shopping_user_ingredient"),
        Index("ix_shopping_user_checked", "user_id", "is_checked"),
    )
    """Uygulama açıldığında kullanıcının alışveriş listesini çekerken, sadece henüz alınmamış (is_checked=False) ürünleri getirmek istersin. Veritabanına koyduğun bu bileşik indeks (composite index), milyonlarca satır olsa bile "Şu kullanıcının alınmamış ürünlerini getir" sorgusunun milisaniyeler içinde sonuçlanmasını garanti eder."""

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    ingredient_id: Mapped[int | None] = mapped_column(ForeignKey("ingredients.id"))
    custom_name: Mapped[str | None] = mapped_column(String(150))

    quantity: Mapped[float | None] = mapped_column(Float)
    unit = enum_col(UnitCode, nullable=True)

    source = enum_col(ShoppingSource, nullable=False, default=ShoppingSource.MANUEL)
    source_recipe_id: Mapped[str | None] = mapped_column(String(24))

    is_checked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    checked_at: Mapped[datetime | None] = mapped_column(DateTime)
    item_note: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(back_populates="shopping_list_items")
    ingredient: Mapped["Ingredient | None"] = relationship()