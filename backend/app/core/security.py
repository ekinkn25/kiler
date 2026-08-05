from datetime import datetime, timedelta, timezone
from typing import Literal

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
TokenType = Literal["access", "refresh"]


def hash_password(password: str) -> str:
    """Duz metin sifreyi bcrypt ile hash'ler."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Girilen sifrenin hash ile eslesip eslesmedigini kontrol eder."""
    return pwd_context.verify(plain_password, hashed_password)

def _create_token(subject: str, token_type: TokenType, expires_delta: timedelta) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(subject),          # JWT standardi: sub METIN olmali
        "type": token_type,           # access token refresh yerine kullanilamasin
        "iat": int(now.timestamp()),
        "exp": int((now + expires_delta).timestamp()),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_access_token(subject: str | int) -> str:
    return _create_token(
        str(subject), "access",
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )

def create_refresh_token(subject: str | int) -> str:
    return _create_token(
        str(subject), "refresh",
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def decode_token(token: str, expected_type: TokenType = "access") -> str | None:
    """Token gecerliyse icindeki kullanici kimligini (sub) doner, degilse None.

    Suresi dolmus, imzasi bozuk veya YANLIS TIPTE token None doner.
    Tip kontrolu onemli: refresh token ile korumali uclara erisilememelidir.
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError:
        return None

    if payload.get("type") != expected_type:
        return None
    return payload.get("sub")