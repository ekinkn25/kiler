"""FastAPI bagimliliklari (dependencies)."""
from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import PermissionDeniedError, UnauthorizedError
from app.core.security import decode_token
from app.db.session import get_db
from app.models import User
from app.services import user_service
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.db.mongodb import get_database

# tokenUrl, Swagger'daki "Authorize" butonunun hangi uca istek atacagini soyler.
# Buradaki yol GERCEK login ucuyla birebir ayni olmali, yoksa Authorize calismaz.
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_PREFIX}/auth/token")

DbSession = Annotated[Session, Depends(get_db)]
TokenStr = Annotated[str, Depends(oauth2_scheme)]
MongoDb = Annotated[AsyncIOMotorDatabase, Depends(get_database)]


def get_current_user(db: DbSession, token: TokenStr) -> User:
    """Authorization basligindaki token'dan kullaniciyi cozer.

    Token yok / gecersiz / suresi dolmus / kullanici silinmis -> 401
    """
    user_id = decode_token(token, expected_type="access")
    if user_id is None:
        raise UnauthorizedError("Token gecersiz veya suresi dolmus.")

    user = user_service.get_by_id(db, int(user_id))
    if user is None:
        raise UnauthorizedError("Kullanici bulunamadi.")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def get_current_active_user(current_user: CurrentUser) -> User:
    """Ek kontrol: hesap pasiflestirilmis mi? (403, 401 degil)

    401 = "kim oldugunu bilmiyorum"
    403 = "kim oldugunu biliyorum ama izin yok"
    """
    if not current_user.is_active:
        raise PermissionDeniedError("Hesabiniz pasif durumda.")
    return current_user


ActiveUser = Annotated[User, Depends(get_current_active_user)]