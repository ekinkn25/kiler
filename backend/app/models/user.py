from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Table, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ActivityLevel, Gender, Goal
from app.models.mixins import TimestampMixin, enum_col

if TYPE_CHECKING:
    from app.models.chat import ChatConversation
    from app.models.nutrition import MealLog, WeightLog
    from app.models.pantry import PantryEvent, PantryItem, ShoppingListItem
    from app.models.recipe import RecipeFavorite, RecipeFeedback, UserTasteWeight, SwipeSession
    from app.models.recipe import RecipeFavorite, RecipeFeedback, SwipeSession, UserTasteWeight


# ----------------------------------------------------------------- N:N tablolari
user_diet_tags = Table( #neden sınıf değil de table? normalde N:N ilişkisi tablosunda sadece iki fk var ise bu bir table olur ama ara tabloda severity gibi ekstra veriler(payload) var ise sql alchemy dokümantasyonu bunu association object pattern yapmayı önerir
    #ilk versiyonunda (MVP) alerjinin şiddetine göre kolda bir mantık (iş kuralı) işletilmiyor; alerji varsa o yemek filtreleniyor. Eğer bunu sınıfa çevirseydin, kullanıcıya alerji eklerken user.allergens.append(Allergen(..)) gibi basit bir liste işlemi yapamayacaktın.
    #Veritabanı seviyesinde veri kaybolmuyor (kolon orada), ancak ORM seviyesinde karmaşıklıktan kaçınılmış.
    "user_diet_tags",
    Base.metadata,
    Column("user_id", ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("diet_tag_id", ForeignKey("diet_tags.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime, server_default=func.now(), nullable=False),
)

user_allergens = Table(
    "user_allergens",
    Base.metadata,
    Column("user_id", ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
    Column("allergen_id", ForeignKey("allergens.id", ondelete="CASCADE"), primary_key=True),
    Column("severity", String(20)),
    Column("created_at", DateTime, server_default=func.now(), nullable=False),
)


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    #index=True verilmesi kritik. Giriş yaparken her seferinde bu e-posta adresi aranacak. İndeksleme yapılmasaydı, 1 milyon kullanıcıda veritabanı her girişte "Full Table Scan" (tüm tabloyu tarama) yapmak zorunda kalırdı.
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(120))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    
    # W4-T14 / KVKK: asagidaki ILISKILERIN HEPSINDE passive_deletes=True var.
    # Olmadiginda SQLAlchemy hesap silinirken tum cocuk satirlari BELLEGE
    # yukleyip tek tek DELETE atiyor - bir kullanicida ~1200 SQL ifadesi.
    # Veritabaninda zaten ON DELETE CASCADE tanimli (14 tablonun 14'unde) ve
    # session.py'de PRAGMA foreign_keys=ON aciliyor; silme isini ona
    # birakiyoruz, tek DELETE yetiyor.

    # 1:1
    profile: Mapped["UserProfile | None"] = relationship(
        back_populates="user", uselist=False,
        cascade="all, delete-orphan", passive_deletes=True,
    )
    # N:N
    diet_tags: Mapped[list["DietTag"]] = relationship(
        secondary=user_diet_tags, back_populates="users", passive_deletes=True,
    )
    allergens: Mapped[list["Allergen"]] = relationship(
        secondary=user_allergens, back_populates="users", passive_deletes=True,
    )
    # 1:N - kullanici silinince hepsi silinir (KVKK)
    pantry_items: Mapped[list["PantryItem"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    #cascade="all, delete-orphan":Eğer bir User silinirse (hesabını kapatırsa), SQLAlchemy o kullanıcıya bağlı olan kiler eşyalarını, yemek loglarını, favori tariflerini ve sohbet geçmişini acımasızca temizler. Bu sayede veritabanında "sahipsiz" (orphan) veri kalmaz ve yasal veri imha yükümlülüğünü teknik düzeyde otomatikleştirmiş olursun.
    pantry_events: Mapped[list["PantryEvent"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    shopping_list_items: Mapped[list["ShoppingListItem"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    meal_logs: Mapped[list["MealLog"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    weight_logs: Mapped[list["WeightLog"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    recipe_feedback: Mapped[list["RecipeFeedback"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    recipe_favorites: Mapped[list["RecipeFavorite"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    taste_weights: Mapped[list["UserTasteWeight"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    conversations: Mapped[list["ChatConversation"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )
    swipe_sessions: Mapped[list["SwipeSession"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True,
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"


class UserProfile(TimestampMixin, Base): #1:1
    #Boy, kilo, günlük kalori hedefi gibi bilgileri neden User tablosuna koymadık da ayrı bir tablo yaptık? performans olarak sadece kullanıcı girişi doğrulanacakken(jwt token üretirken) dbde devasa bir kullanıcı satırı çekmek rami yorar
    __tablename__ = "user_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    birth_year: Mapped[int | None] = mapped_column(Integer)
    gender = enum_col(Gender, nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float)
    weight_kg: Mapped[float | None] = mapped_column(Float)
    activity_level = enum_col(ActivityLevel, nullable=False, default=ActivityLevel.ORTA)
    goal = enum_col(Goal, nullable=False, default=Goal.KORUMA)

    bmr: Mapped[float | None] = mapped_column(Float)
    tdee: Mapped[float | None] = mapped_column(Float)
    daily_calorie_target: Mapped[float] = mapped_column(Float, default=2000, nullable=False)
    protein_target_g: Mapped[float | None] = mapped_column(Float)
    carb_target_g: Mapped[float | None] = mapped_column(Float)
    fat_target_g: Mapped[float | None] = mapped_column(Float)

    household_size: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    user: Mapped["User"] = relationship(back_populates="profile")


class DietTag(Base): 
    #tablolar sistmeindeki sözlük(lookup) tablolarıdır
    #code(vegan, gluten_free) alanı makinenin/kodun anlayacağı değişmez anahtardır
    #display name: vegan diyet, glütensiz metnidr
    #İleride sisteme çoklu dil (i18n) desteği getirdiğinde, code üzerinden eşleştirme yapıp farklı dillerde çeviriler sunmanı inanılmaz kolaylaştıracaktır.
    __tablename__ = "diet_tags"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[str | None] = mapped_column(String(255))

    users: Mapped[list["User"]] = relationship(
        secondary=user_diet_tags, back_populates="diet_tags"
    )


class Allergen(Base):
    __tablename__ = "allergens"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(80), nullable=False)

    users: Mapped[list["User"]] = relationship(
        secondary=user_allergens, back_populates="allergens"
    )