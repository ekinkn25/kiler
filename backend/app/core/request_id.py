"""W4-T15: her istege izlenebilir bir kimlik.

NEDEN: Kullanici 'uygulama hata verdi' dediginde elimizde tek ipucu ekran
goruntusu oluyor. Istek kimligi hem yanit govdesinde hem logda gecerse,
kullanicinin okudugu 8 karakter dogrudan log satirina goturur.
"""
from __future__ import annotations

import uuid
from contextvars import ContextVar

from fastapi import FastAPI, Request

istek_kimligi: ContextVar[str] = ContextVar("istek_kimligi", default="-")


def install_request_id(application: FastAPI) -> None:
    @application.middleware("http")
    async def _kimlik(request: Request, call_next):
        # Istemci kendi kimligini gonderdiyse ona saygi duy (mobil tarafta
        # ayni kimlikle loglayabilelim); yoksa uret.
        kimlik = request.headers.get("X-Request-ID") or uuid.uuid4().hex[:8]
        istek_kimligi.set(kimlik)
        yanit = await call_next(request)
        yanit.headers["X-Request-ID"] = kimlik
        return yanit