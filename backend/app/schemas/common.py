# data baseteki tablolar : models, dışarıya gönderdiğimiz/aldığımız veriler: schemas bu ikisi birbirinden ayrılmalı
#DTO data transfer objects veya Seperation of concers olarak da geçiyor

from typing import Generic, TypeVar
from math import ceil

from pydantic import BaseModel, ConfigDict, Field

T = TypeVar("T")

class AppBaseModel(BaseModel):
    """projedeki tüm şemaların ata sınfı: tüm request ve response şemalarının miras alacağı temel sınıf
    from _attributes=True: SQLAlchemy nesnesinin doğrudan şema üretilmesini sağlar
    bu olmadan UserRead.model_validate(user_orm_nesnesi) çalışmaz
    """
    model_config = ConfigDict(
        from_attributes=True,
        str_strip_whitespace=True,
        populate_by_name=True,
    )


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str
    version: str


class ErrorResponse(BaseModel):
    """Tum hata yanitlarinin ortak sozlesmesi."""

    code: str = Field(examples=["validation_error"])
    message: str = Field(examples=["Gonderilen veri gecersiz."])
    detail: list | dict | None = None

class Message(AppBaseModel):
    """içeriği olmayan başarılı işlemler için(silme, onaylama vb.)"""
    message: str

class PageParams(AppBaseModel):
    """sayfalama sorgu parametreleri. FastAPI'de Depends() ile kullanılır"""
    page: int = Field(default=1, ge=1, description="1'den başlar")
    size: int = Field(default=20, ge=1, le=100, description="sayfa basina kayit") 
    #ge: greater than or equal , le: less than or equal

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


class Page(BaseModel, Generic[T]):
    """Sayfalanmis liste yanitlari icin ortak sarmalayici."""

    model_config = ConfigDict(from_attributes=True)

    items: list[T]
    total: int
    page: int
    size: int
    pages:int

    @classmethod
    def create(cls, items: list[T], total: int, params: PageParams) -> "Page[T]":
        return cls(
            items=items,
            total=total,
            page=params.page,
            size=params.size,
            pages=ceil(total / params.size) if params.size else 0,
        )