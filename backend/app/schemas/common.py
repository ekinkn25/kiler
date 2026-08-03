# data baseteki tablolar : models, dışarıya gönderdiğimiz/aldığımız veriler: schemas bu ikisi birbirinden ayrılmalı
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str
    version: str


class ErrorResponse(BaseModel):
    """Tum hata yanitlarinin ortak sozlesmesi."""

    code: str
    message: str
    detail: list | dict | None = None


class Page(BaseModel, Generic[T]):
    """Sayfalanmis liste yanitlari icin ortak sarmalayici."""

    items: list[T]
    total: int
    page: int
    size: int