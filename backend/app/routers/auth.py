"""Kimlik dogrulama uclari."""
from fastapi import APIRouter, status
from fastapi.security import OAuth2PasswordRequestForm
from typing import Annotated

from fastapi import Depends

from app.core.deps import ActiveUser, DbSession
from app.core.exceptions import UnauthorizedError
from app.core.security import create_access_token, create_refresh_token, decode_token
from app.schemas import (
    ErrorResponse, LoginRequest, RefreshRequest, RegisterRequest, Token, UserRead,
)
from app.services import user_service

router = APIRouter()


@router.post(
    "/register",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED,
    summary="Yeni kullanici kaydi",
    responses={status.HTTP_409_CONFLICT: {"model": ErrorResponse}},
)
def register(data: RegisterRequest, db: DbSession) -> UserRead:
    user = user_service.create_user(db, data)
    return UserRead.model_validate(user)


@router.post(
    "/login",
    response_model=Token,
    summary="Giris (JSON) - mobil uygulama bunu kullanir",
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
def login(data: LoginRequest, db: DbSession) -> Token:
    user = user_service.authenticate(db, data.email, data.password)
    if user is None:
        # E-posta mi sifre mi yanlis SOYLENMEZ: hangi e-postalarin kayitli
        # oldugunu deneyerek ogrenmeyi (user enumeration) engeller.
        raise UnauthorizedError("E-posta veya sifre hatali.")

    return Token(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post(
    "/token",
    response_model=Token,
    summary="Giris (form) - Swagger 'Authorize' butonu bunu kullanir",
    include_in_schema=True,
)
def login_form(
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: DbSession,
) -> Token:
    """OAuth2 standardi 'username' alani bekler; biz oraya E-POSTA giriyoruz."""
    user = user_service.authenticate(db, form.username, form.password)
    if user is None:
        raise UnauthorizedError("E-posta veya sifre hatali.")

    return Token(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post(
    "/refresh",
    response_model=Token,
    summary="Access token yenileme",
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
def refresh(data: RefreshRequest, db: DbSession) -> Token:
    user_id = decode_token(data.refresh_token, expected_type="refresh")
    if user_id is None:
        raise UnauthorizedError("Refresh token gecersiz veya suresi dolmus.")

    user = user_service.get_by_id(db, int(user_id))
    if user is None or not user.is_active:
        raise UnauthorizedError("Kullanici bulunamadi veya pasif.")

    return Token(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.get(
    "/me",
    response_model=UserRead,
    summary="Oturum acmis kullanicinin bilgileri",
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
def read_me(current_user: ActiveUser) -> UserRead:
    return UserRead.model_validate(current_user)