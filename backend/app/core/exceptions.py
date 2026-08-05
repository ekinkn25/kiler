# import logging
# from fastapi import FastAPI, Request, status
# from fastapi.encoders import jsonable_encoder
# from fastapi.exceptions import RequestValidationError
# from fastapi.responses import JSONResponse
# from starlette.exceptions import HTTPException as StarletteHTTPException

# logger = logging.getLogger(__name__)

# #------------------------hata sınıfları
# class AppError(Exception):
#     """uygulamaya özel tüm hataların ata sınıfı"""
#     status_code: int = status.HTTP_400_BAD_REQUEST
#     code: str = "app_error"
#     message: str = "Beklenmeyen bir hata olustu"

#     def  __init_(
#             self, 
#             message: str | None = None,
#             code: str | None = None,
#             status_code: int | None = None,
#     ) -> None:
#         self.message = message or self.message
#         self.code = code or self.code
#         self.status_code = status_code or self.status_code
#         super().__init__(self.message)

# class NotFoundError(AppError): 
#     status_code = status.HTTP_404_NOT_FOUND
#     code = "not_found"
#     message = "Kayit bulunamadi."

# class UnauthorizedError(AppError):
#     """Kimlik dogrulanamadi: token yok, gecersiz veya suresi dolmus."""

#     status_code = status.HTTP_401_UNAUTHORIZED
#     code = "unauthorized"
#     message = "Kimlik dogrulanamadi."
#     headers = {"WWW-Authenticate": "Bearer"}


# class ConflictError(AppError):
#     status_code = status.HTTP_409_CONFLICT
#     code = "conflict"
#     message = "Kayit zaten mevcut."


# class PermissionDeniedError(AppError):
#     status_code = status.HTTP_403_FORBIDDEN
#     code = "permission_denied"
#     message = "Bu islem icin yetkiniz yok."


# class ExternalServiceError(AppError):
#     """Open Food Facts veya Groq gibi dis servisler yanit vermediginde."""

#     status_code = status.HTTP_502_BAD_GATEWAY
#     code = "external_service_error"
#     message = "Dis servise su anda ulasilamiyor."

# class AppError(Exception):
#     """Uygulamaya ozel tum hatalarin ata sinifi."""

#     status_code: int = status.HTTP_400_BAD_REQUEST
#     code: str = "app_error"
#     message: str = "Beklenmeyen bir hata olustu."
#     headers: dict[str, str] | None = None

#     def __init__(
#         self,
#         message: str | None = None,
#         code: str | None = None,
#         status_code: int | None = None,
#         headers: dict[str, str] | None = None,
#     ) -> None:
#         self.message = message or self.message
#         self.code = code or self.code
#         self.status_code = status_code or self.status_code
#         self.headers = headers or self.headers
#         super().__init__(self.message)


# # ---------------------------------------------------------------- yardimci: Ne tür bir hata olursa olsun, mobil uygulamaya gidecek olan JSON (veri) paketinin şeklini belirler.
# # Mobil geliştirici, backend'den bir hata geldiğinde her zaman şunu bilecek: "Gelen paketin içinde kesinlikle bir code ve bir message alanı olacak." Böylece mobil tarafta if error.code == 'not_found': gibi son derece temiz, çökme riski sıfır olan kodlar yazılabilecek.
# def _error_response(status_code: int, code: str, message: str, detail=None, headers=None) -> JSONResponse:
#     body: dict = {"code": code, "message": message}
#     if detail is not None:
#         body["detail"] = detail
#     return JSONResponse(status_code=status_code, content=body, headers=headers)


# # ---------------------------------------------------------------- kayit
# def register_exception_handlers(app: FastAPI) -> None:
#     """Tum global hata yakalayicilari uygulamaya baglar."""

#     @app.exception_handler(AppError) #Bizim kendi yazdığımız (yukarıdaki) hataları yakalar ve usulca formata sokar.
#     async def app_error_handler(request: Request, exc: AppError):
#         logger.warning("AppError [%s] %s %s", exc.code, request.url.path, exc.message)
#         return _error_response(exc.status_code, exc.code, exc.message, headers=exc.headers)

#     @app.exception_handler(StarletteHTTPException) 
#     async def http_error_handler(request: Request, exc: StarletteHTTPException): #FastAPI'nin kendi ürettiği standart web hatalarını yakalar.
#         return _error_response(exc.status_code, "http_error", str(exc.detail))

#     @app.exception_handler(RequestValidationError)
#     async def validation_error_handler(request: Request, exc: RequestValidationError):
#         return _error_response(
#             status.HTTP_422_UNPROCESSABLE_ENTITY,
#             "validation_error",
#             "Gonderilen veri gecersiz.",
#             jsonable_encoder(exc.errors()),
#         )

#     @app.exception_handler(Exception)
#     async def unhandled_error_handler(request: Request, exc: Exception):
#         # Traceback sadece sunucu logunda kalir, istemciye sizmaz.
#         logger.exception("Beklenmeyen hata: %s %s", request.method, request.url.path)
#         return _error_response(
#             status.HTTP_500_INTERNAL_SERVER_ERROR,
#             "internal_error",
#             "Sunucuda beklenmeyen bir hata olustu.",
#         )


import logging

from fastapi import FastAPI, Request, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

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
        logger.exception("Beklenmeyen hata: %s %s", request.method, request.url.path)
        return _error_response(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "internal_error",
            "Sunucuda beklenmeyen bir hata olustu.",
        )