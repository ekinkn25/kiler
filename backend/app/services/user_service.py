"""Kullanici islemlerinin is mantigi."""
"""iş mantığı router'a değil, servise yazılır. Router HTTP'yi bilir, servis kuralları bilir."""
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import ConflictError
from app.core.security import hash_password, verify_password
from app.models import User
from app.schemas import RegisterRequest


def get_by_email(db: Session, email: str) -> User | None:
    return db.scalar(select(User).where(User.email == email.lower()))


def get_by_id(db: Session, user_id: int) -> User | None:
    """Iliskili profil, diyet ve alerjen kayitlarini tek sorguda yukler.

    selectinload olmadan UserRead serilestirilirken 3 ayri sorgu daha atilir (N+1).
    """
    return db.scalar(
        select(User)
        .where(User.id == user_id)
        .options(
            selectinload(User.profile),
            selectinload(User.diet_tags),
            selectinload(User.allergens),
        )
    )


def create_user(db: Session, data: RegisterRequest) -> User:
    if get_by_email(db, data.email):
        raise ConflictError("Bu e-posta adresi zaten kayitli.")

    user = User(
        email=data.email,                       # sema zaten kucuk harfe cevirdi
        hashed_password=hash_password(data.password),
        full_name=data.full_name,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate(db: Session, email: str, password: str) -> User | None:
    """E-posta + sifre dogruysa kullaniciyi, degilse None doner.

    GUVENLIK: Kullanici bulunamasa bile sahte bir hash dogrulanir. Boylece
    "e-posta kayitli mi degil mi" bilgisi yanit suresinden sizdirilmaz
    (zamanlama saldirisi / user enumeration).
    """
    user = get_by_email(db, email)
    if user is None:
        verify_password(password, "$2b$12$" + "x" * 53)
        return None
    if not verify_password(password, user.hashed_password):
        return None
    if not user.is_active:
        return None
    return user