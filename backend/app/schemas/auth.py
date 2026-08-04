"""kimlik doğrulama şemaları. TO-DO:W1-T08"""
from pydantic import EmailStr, Field, field_validator

from app.schemas.common import AppBaseModel

class RegisterRequest(AppBaseModel):
    email: EmailStr= Field(examples=["ekin@ornek.com"])
    password: str = Field(min_length=8, max_length=72, examples=["GucluSifre123"]) 
    #max length 72 çünkü bcrypt algoritması 72 bayttan uzun şifreleri sessizce kırpar
    full_name: str | None = Field(default=None, max_length=120)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        """e postayı küçük harflere çevirir"""
        return v.lower()

    @field_validator("password")
    @classmethod
    def password_strength(cla, v: str) -> str:
        if v.isdigit() or v.isalpha():
            raise ValueError("Sifre hem harf hem rakam icermelidir!")
        return v

class LoginRequest(AppBaseModel):
    email: EmailStr
    password: str

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower()


class Token(AppBaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"


class TokenPayload(AppBaseModel):
    """JWT icindeki veri. decode_access_token ciktisini dogrulamak icin."""

    sub: str
    exp: int