"""KVKK uclarinin istek/yanit semalari. W4-T14."""
from typing import Literal

from pydantic import Field

from app.schemas.common import AppBaseModel


class AccountDeleteRequest(AppBaseModel):
    password: str = Field(
        min_length=1, description="Hesap parolasi. Teyit icin zorunlu."
    )
    # Yanlis baglanmis bir istemcinin kazara hesap silmesini engeller.
    # Literal: baska bir metin gelirse Pydantic 422 doner, is mantigi hic calismaz.
    confirm: Literal["HESABIMI SIL"] = Field(
        description="Birebir 'HESABIMI SIL' gonderilmeli."
    )


class AccountDeleteResponse(AppBaseModel):
    deleted: bool
    deleted_rows: dict[str, int] = Field(
        description="Tablo adi -> silinen satir sayisi. Denetim izi."
    )