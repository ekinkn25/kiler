"""master data management ve data pipeline tasarımı"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean, DateTime, Float, ForeignKey, Index, Integer, String, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ProductSource, UnitCode, UnitType
from app.models.mixins import TimestampMixin, enum_col

if TYPE_CHECKING:
    from app.models.pantry import PantryItem


class Category(Base):
    """taxonomy(kategori) yönetimi: ürün ve malzemeleri süt ürünleri bakliyatlar gibi gruplara ayırır
    sort_ortder kolonu frontendde veya mobilde kategorilerin alfebatik değil benim belirlediğim bir sıraya göre dizilmesini sağlar"""
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)
    icon: Mapped[str | None] = mapped_column(String(50))
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    ingredients: Mapped[list["Ingredient"]] = relationship(back_populates="category")
    products: Mapped[list["Product"]] = relationship(back_populates="category")


class Ingredient(Base):
    """Normalize malzeme sozlugu. SISTEMIN KALBI.
    canonical_name, SQLite ile MongoDB arasindaki birlestirme anahtaridir.
    Format: yalnizca [a-z0-9_], Turkce karakter YOK. Ornek: kirmizi_mercimek
    """

    """
    Modern sistemlerde SQLite/PostgreSQL gibi ilişkisel veritabanları yapısal veriyi tutarken, MongoDB gibi NoSQL veritabanları karmaşık tarif ağaçlarını veya logları tutabilir. 
    canonical_name, bu iki farklı veritabanı paradigması arasında sarsılmaz bir Doğal Anahtar (Natural Key) görevi görür. ID'ler (1, 2, 3) sistemler arası taşınırken değişebilir, ancak "kirmizi_mercimek" metni evrenseldir.
    """
    __tablename__ = "ingredients"
    __table_args__ = (Index("ix_ingredients_category", "category_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    canonical_name: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True
    )
    display_name: Mapped[str] = mapped_column(String(120), nullable=False)
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))

    default_unit_type = enum_col(UnitType, nullable=False, default=UnitType.MASS)
    default_unit = enum_col(UnitCode, nullable=False, default=UnitCode.G)

    grams_per_piece: Mapped[float | None] = mapped_column(Float)
    ml_to_gram_factor: Mapped[float | None] = mapped_column(Float)
    cooked_yield_factor: Mapped[float | None] = mapped_column(Float)

    calories_per_100g: Mapped[float | None] = mapped_column(Float)
    protein_per_100g: Mapped[float | None] = mapped_column(Float)
    carb_per_100g: Mapped[float | None] = mapped_column(Float)
    fat_per_100g: Mapped[float | None] = mapped_column(Float)
    fiber_per_100g: Mapped[float | None] = mapped_column(Float)
    sugar_per_100g: Mapped[float | None] = mapped_column(Float)
    sodium_mg_per_100g: Mapped[float | None] = mapped_column(Float)

    avg_shelf_life_days: Mapped[int | None] = mapped_column(Integer)
    season_months: Mapped[str | None] = mapped_column(String(30))
    avg_price_per_100g: Mapped[float | None] = mapped_column(Float)
    is_staple: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    category: Mapped["Category | None"] = relationship(back_populates="ingredients")
    aliases: Mapped[list["IngredientAlias"]] = relationship(
        back_populates="ingredient", cascade="all, delete-orphan"
    )
    products: Mapped[list["Product"]] = relationship(back_populates="ingredient")
    pantry_items: Mapped[list["PantryItem"]] = relationship(back_populates="ingredient")

    def __repr__(self) -> str:
        return f"<Ingredient {self.canonical_name!r}>"


class IngredientAlias(Base):
    """'k.mercimek', 'MGRS KRMZ MRCMK' gibi varyantlari canonical ada baglar."""
    """İşlevi: Bu tablo bir sözlük (dictionary) haritalaması yapar. Dışarıdan gelen bozuk metinleri alır ve hepsini Ingredient tablosundaki o tertemiz kirmizi_mercimek ID'sine bağlar."""
    __tablename__ = "ingredient_aliases"
    __table_args__ = (Index("ix_alias_ingredient", "ingredient_id"),)

    """Optimizasyon: Index("ix_alias_ingredient", "ingredient_id") ve index=True kullanımları, arama işlemlerinin (metin eşleştirmenin) anında gerçekleşmesini sağlar. Uygulama, kullanıcının yazdığı metni önce bu tabloda arar."""

    id: Mapped[int] = mapped_column(primary_key=True)
    ingredient_id: Mapped[int] = mapped_column(
        ForeignKey("ingredients.id", ondelete="CASCADE"), nullable=False
    )
    alias: Mapped[str] = mapped_column(String(150), unique=True, nullable=False, index=True)
    source: Mapped[str | None] = mapped_column(String(30))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    ingredient: Mapped["Ingredient"] = relationship(back_populates="aliases")


class UnmatchedIngredient(Base):
    """Eslestirilemeyen malzeme metinleri. Sozlugun kendini buyutme motoru."""
    """Mekanizma: Kullanıcı sisteme bir ürün girdiğinde veya bir fiş okutulduğunda sistem bu kelimeyi IngredientAlias içinde bulamazsa hata fırlatıp çökmek yerine kelimeyi bu tabloya atar."""
    """occurrence_count (görülme sıklığı) alanına konan indeks (ix_unmatched_count) çok stratejiktir. Veritabanı yöneticisi veya arka plandaki bir görev (job), bu tabloyu "en çok karşılaşılan kelimelere göre" sıralar. "Kullanıcılar 500 defa 'yulaf ezm' yazmış, ben bunu hemen sisteme tanıtayım" dersin. Bu tablo büyüdükçe, gelecekte bir Doğal Dil İşleme (NLP) modelini eğitmek için elinde kusursuz bir etiketli veri seti oluşur."""
    __tablename__ = "unmatched_ingredients"
    __table_args__ = (
        Index("ix_unmatched_count", "occurrence_count"),
        Index("ix_unmatched_resolved", "resolved_ingredient_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    raw_text: Mapped[str] = mapped_column(String(255), nullable=False)
    normalized_text: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    source: Mapped[str | None] = mapped_column(String(30))
    occurrence_count: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    resolved_ingredient_id: Mapped[int | None] = mapped_column(ForeignKey("ingredients.id"))
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime)
    first_seen_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    resolved_ingredient: Mapped["Ingredient | None"] = relationship()


class Product(Base):
    """Barkod katalogu ve Open Food Facts onbellegi."""
    """ her product bir ingrediente bağlanır"""
    """Önbellek (Cache) Mantığı: ProductSource.OPENFOODFACTS gibi dış API'lerden çekilen veriler bu tabloda saklanır. fetched_at (çekilme zamanı) kolonu, verinin ne kadar bayat olduğunu takip eder. 3 ay önce çekilmiş bir veriyi gördüğünde, sistemin bunu yeniden API'den güncellemesini sağlayacak mantığı bu zaman damgası üzerine kurarsın."""
    __tablename__ = "products"
    __table_args__ = (
        Index("ix_products_ingredient", "ingredient_id"),
        Index("ix_products_name", "name"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    barcode: Mapped[str | None] = mapped_column(String(20), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    brand: Mapped[str | None] = mapped_column(String(120))

    ingredient_id: Mapped[int | None] = mapped_column(ForeignKey("ingredients.id"))
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))

    package_quantity: Mapped[float | None] = mapped_column(Float)
    package_unit = enum_col(UnitCode, nullable=True)
    serving_size_g: Mapped[float | None] = mapped_column(Float)
    serving_description: Mapped[str | None] = mapped_column(String(100))

    calories_per_100g: Mapped[float | None] = mapped_column(Float)
    protein_per_100g: Mapped[float | None] = mapped_column(Float)
    carb_per_100g: Mapped[float | None] = mapped_column(Float)
    fat_per_100g: Mapped[float | None] = mapped_column(Float)
    fiber_per_100g: Mapped[float | None] = mapped_column(Float)
    sugar_per_100g: Mapped[float | None] = mapped_column(Float)
    sodium_mg_per_100g: Mapped[float | None] = mapped_column(Float)

    image_url: Mapped[str | None] = mapped_column(String(500))
    source = enum_col(ProductSource, nullable=False, default=ProductSource.OPENFOODFACTS)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    fetched_at: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    ingredient: Mapped["Ingredient | None"] = relationship(back_populates="products")
    category: Mapped["Category | None"] = relationship(back_populates="products")