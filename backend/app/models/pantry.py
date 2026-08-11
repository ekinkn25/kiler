from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, Float, ForeignKey, Index,
    String, UniqueConstraint, func, and_, or_,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.config import settings
from app.db.base import Base
from app.models.enums import PantryEventType, ShoppingSource, UnitCode, UnitType, Availability, PantrySource, UnitCode, UnitType
from app.models.mixins import TimestampMixin, enum_col

if TYPE_CHECKING:
    from app.models.catalog import Ingredient, Product
    from app.models.user import User

def utcnow() -> datetime:
    """SQLite naive UTC ile karsilastirilabilir 'simdi' degeri.
    """
    return datetime.now(timezone.utc).replace(tzinfo=None)


# ====================================================================
# Sorgu yardimcilari
# ====================================================================
def filter_confirmed():
    """SQL seviyesinde 'kesin var' filtresi.

    Python'daki effective_availability tek bir nesne icin calisir;
    liste sorgularinda bu ifadeyi kullan:
        db.scalars(select(PantryItem).where(PantryItem.user_id == uid, filter_confirmed()))
    """
    simdi = utcnow()
    return and_(
        PantryItem.availability == Availability.VAR,
        or_(
            PantryItem.confidence_expires_at.is_(None),
            PantryItem.confidence_expires_at > simdi,
        ),
    )


def filter_unknown():
    """'Emin degiliz' filtresi: suresi dolmus veya zaten bilinmiyor."""
    simdi = utcnow()
    return or_(
        PantryItem.availability == Availability.BILINMIYOR,
        and_(
            PantryItem.availability == Availability.VAR,
            PantryItem.confidence_expires_at.isnot(None),
            PantryItem.confidence_expires_at <= simdi,
        ),
    )


class PantryItem(TimestampMixin, Base):
    """Kullanicinin kilerinde OLDUGUNU DUSUNDUGUMUZ malzemeler.

    Bu tablo bir ENVANTER DEGILDIR. Kesin miktar takibi yapmiyoruz;
    'su an elimizdeki kanita gore bu sende var' inancini sakliyoruz.
    Kayitlar yalnizca barkod okutma ve fotograf tanima ile olusur.
    """

    __tablename__ = "pantry_items"
    __table_args__ = (
        UniqueConstraint("user_id", "ingredient_id", name="uq_pantry_user_ingredient"),
        CheckConstraint("quantity_base IS NULL OR quantity_base >= 0",
                        name="quantity_nonnegative"),
        CheckConstraint("detected_confidence IS NULL OR "
                        "(detected_confidence BETWEEN 0 AND 1)",
                        name="confidence_range"),
        Index("ix_pantry_user_availability", "user_id", "availability"),
        Index("ix_pantry_confidence_expiry", "confidence_expires_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    ingredient_id: Mapped[int] = mapped_column(ForeignKey("ingredients.id"), nullable=False)
    product_id: Mapped[int | None] = mapped_column(ForeignKey("products.id"))

    # ---------- YENI: inanc durumu ----------
    availability = enum_col(Availability, nullable=False, default=Availability.VAR)
    source = enum_col(PantrySource, nullable=False, default=PantrySource.FOTO)

    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime)
    confidence_expires_at: Mapped[datetime | None] = mapped_column(DateTime)
    detected_confidence: Mapped[float | None] = mapped_column(Float)

    # ---------- Miktar: artik OPSIYONEL ----------
    # Barkod okutuldugunda paket buyuklugu doldurulur (1 kg mercimek gibi).
    # Fotograftan gelen kayitlarda NULL kalir - fotograf gramaj soyleyemez.
    # Oneri algoritmasi bu alanlari KULLANMAZ; yalnizca gosterim icindir.
    quantity_base: Mapped[float | None] = mapped_column(Float)
    unit_type = enum_col(UnitType, nullable=True)
    display_unit = enum_col(UnitCode, nullable=True)

    # ---------- Iliskiler ----------
    user: Mapped["User"] = relationship(back_populates="pantry_items")
    ingredient: Mapped["Ingredient"] = relationship(back_populates="pantry_items")
    product: Mapped["Product | None"] = relationship()
    events: Mapped[list["PantryEvent"]] = relationship(back_populates="pantry_item")

    # ================================================================
    # Hesaplanan alanlar
    # ================================================================
    @property
    def effective_availability(self) -> Availability:
        """Guven suresi dikkate alinmis GERCEK durum.

        Gunluk temizlik gorevi (W4-T05) henuz calismamis olsa bile
        API her zaman dogru degeri doner. Iki katmanli guvenlik:
        bu ozellik anlik dogruluk, temizlik gorevi ise veri hijyeni saglar.
        """
        if self.availability == Availability.BITTI:
            return Availability.BITTI
        if self.confidence_expires_at and self.confidence_expires_at <= utcnow():
            return Availability.BILINMIYOR
        return self.availability

    @property
    def days_remaining(self) -> int | None:
        """Guven suresinin bitmesine kac gun kaldi. Arayuzde '5 gün' olarak gosterilir."""
        if not self.confidence_expires_at:
            return None
        fark = (self.confidence_expires_at - utcnow()).days
        return max(fark, 0)

    # ================================================================
    # Durum degistirme yardimcilari
    # ================================================================
    def confirm(self, source: PantrySource, confidence: float | None = None) -> None:
        """'Bu bende var' der: sureyi bugunden itibaren yeniden baslatir."""
        simdi = utcnow()
        self.availability = Availability.VAR
        self.source = source
        self.confirmed_at = simdi
        self.confidence_expires_at = simdi + timedelta(days=settings.PANTRY_CONFIDENCE_DAYS)
        if confidence is not None:
            self.detected_confidence = confidence

    def mark_unknown(self) -> None:
        """Tarif yapildiginda cagrilir: miktar dusmuyoruz, GUVEN dusuyoruz."""
        if self.availability == Availability.VAR:
            self.availability = Availability.BILINMIYOR
            self.confidence_expires_at = utcnow()

    def mark_finished(self) -> None:
        """Kullanici 'bitti' dedi."""
        self.availability = Availability.BITTI
        self.confidence_expires_at = None

    def __repr__(self) -> str:
        return (f"<PantryItem user={self.user_id} ing={self.ingredient_id} "
                f"{self.effective_availability.value}>")



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