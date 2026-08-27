import logging

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from app.core.request_id import istek_kimligi

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------- hata siniflari
class AppError(StarletteHTTPException):
    """Uygulamaya ozel tum hatalarin ata sinifi.

    HTTPException'dan turetildi: Starlette bu sinifi her surumde ve her
    baglamda (router ici, bagimlilik ici) guvenilir sekilde yakalar.
    'code' alani, istemcinin hatayi programatik ayirt etmesini saglar.
    """

    status_code: int = status.HTTP_400_BAD_REQUEST
    code: str = "app_error"
    message: str = "Beklenmeyen bir hata olustu."
    headers: dict[str, str] | None = None

    def __init__(
        self,
        message: str | None = None,
        code: str | None = None,
        status_code: int | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        self.code = code or type(self).code
        super().__init__(
            status_code=status_code or type(self).status_code,
            detail=message or type(self).message,
            headers=headers or type(self).headers,
        )

    @property
    def message_text(self) -> str:
        return str(self.detail)


class NotFoundError(AppError):
    status_code = status.HTTP_404_NOT_FOUND
    code = "not_found"
    message = "Kayit bulunamadi."


class ConflictError(AppError):
    status_code = status.HTTP_409_CONFLICT
    code = "conflict"
    message = "Kayit zaten mevcut."


class UnauthorizedError(AppError):
    status_code = status.HTTP_401_UNAUTHORIZED
    code = "unauthorized"
    message = "Kimlik dogrulanamadi."
    headers = {"WWW-Authenticate": "Bearer"}


class PermissionDeniedError(AppError):
    status_code = status.HTTP_403_FORBIDDEN
    code = "permission_denied"
    message = "Bu islem icin yetkiniz yok."


class ExternalServiceError(AppError):
    """Open Food Facts veya Groq gibi dis servisler yanit vermediginde."""

    status_code = status.HTTP_502_BAD_GATEWAY
    code = "external_service_error"
    message = "Dis servise su anda ulasilamiyor."


# ---------------------------------------------------------------- yardimci
def _error_response(status_code, code, message, detail=None, headers=None) -> JSONResponse:
    body: dict = {"code": code, "message": message}
    if detail is not None:
        body["detail"] = detail
    return JSONResponse(status_code=status_code, content=body, headers=headers)


# ---------------------------------------------------------------- kayit
def register_exception_handlers(app: FastAPI) -> None:
    """Tum global hata yakalayicilari uygulamaya baglar."""

    @app.exception_handler(StarletteHTTPException)
    async def http_error_handler(request: Request, exc: StarletteHTTPException):
        # AppError alt siniflari kendi 'code' degerini tasir; digerleri icin
        # (404 Not Found, 405 Method Not Allowed vb.) genel bir kod kullanilir.
        code = getattr(exc, "code", "http_error")
        if exc.status_code >= 500:
            logger.error("HTTP %s [%s] %s", exc.status_code, code, request.url.path)
        else:
            logger.warning("HTTP %s [%s] %s", exc.status_code, code, request.url.path)
        return _error_response(
            exc.status_code, code, str(exc.detail), headers=getattr(exc, "headers", None)
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(request: Request, exc: RequestValidationError):
        return _error_response(
            422,
            "validation_error",
            "Gonderilen veri gecersiz.",
            jsonable_encoder(exc.errors()),
        )

    @app.exception_handler(Exception)
    async def unhandled_error_handler(request: Request, exc: Exception):
        logger.exception("Beklenmeyen hata | id=%s | %s %s | %s: %s",
            istek_kimligi.get(), request.method, request.url.path,
            type(exc).__name__, exc,)
        return _error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "internal_error",
            "Sunucuda beklenmeyen bir hata olustu.",
        )

def _error_response(status_code, code, message, detail=None, headers=None) -> JSONResponse:
    body: dict = {"code": code, "message": message, "request_id": istek_kimligi.get()}
    if detail is not None:
        body["detail"] = detail
    return JSONResponse(status_code=status_code, content=body, headers=headers)