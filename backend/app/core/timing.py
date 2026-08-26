"""W4-T13: yavas sorgu ve yavas istek loglamasi.

IKI KATMAN:
  1) SQLAlchemy olay dinleyicisi -> her SQL sorgusunun suresi
  2) HTTP ara katmani -> her istegin toplam suresi + o istekteki SORGU SAYISI

Sorgu sayaci N+1'in ROTGENIDIR: kiler listesinde 3 kayit varken 8 sorgu,
30 kayit varken 62 sorgu goruyorsan iliski tembel yukleniyor demektir.
Sure olcmek yetmez - yavaslamanin SEBEBINI sayi soyler.
"""
from __future__ import annotations

import logging
import time
from contextvars import ContextVar

from fastapi import FastAPI, Request
from sqlalchemy import event
from sqlalchemy.engine import Engine

from app.core.config import settings

logger = logging.getLogger("app.perf")


class IstekOlcumu:
    """Tek istegin sayaclari.

    ContextVar'a sayi degil NESNE koyuyoruz. Sebep: FastAPI senkron uc
    fonksiyonlarini is parcacigi havuzunda calistirir ve o parcacik
    context'in bir KOPYASINI alir. Kopyada .set() yapmak disariya yansimaz;
    ama ayni nesnenin alanini degistirmek yansir (referans paylasilir).
    """

    __slots__ = ("sorgu", "sorgu_ms", "yavas_sorgu")

    def __init__(self) -> None:
        self.sorgu = 0
        self.sorgu_ms = 0.0
        self.yavas_sorgu = 0


_olcum: ContextVar[IstekOlcumu | None] = ContextVar("perf_olcum", default=None)
_kuruldu = False


def _tek_satir(sql: str, tavan: int = 300) -> str:
    """Cok satirli SQL'i loga sigacak tek satira indirir."""
    return " ".join(sql.split())[:tavan]


def _sorgu_dinleyicilerini_kur() -> None:
    """SQLAlchemy'nin resmi 'query timer' tarifi.

    Baslangic zamani conn.info uzerinde YIGIN olarak tutulur; ic ice
    calisan sorgularda esleme bozulmasin diye liste kullaniliyor.
    """

    @event.listens_for(Engine, "before_cursor_execute")
    def _once(conn, cursor, statement, parameters, context, executemany):
        conn.info.setdefault("perf_baslangic", []).append(time.perf_counter())

    @event.listens_for(Engine, "after_cursor_execute")
    def _sonra(conn, cursor, statement, parameters, context, executemany):
        yigin = conn.info.get("perf_baslangic")
        if not yigin:
            return
        sure_ms = (time.perf_counter() - yigin.pop()) * 1000

        olcum = _olcum.get()
        if olcum is not None:
            olcum.sorgu += 1
            olcum.sorgu_ms += sure_ms

        if sure_ms >= settings.SLOW_QUERY_MS:
            if olcum is not None:
                olcum.yavas_sorgu += 1
            logger.warning(
                "YAVAS SORGU | %.1f ms | %s | parametre=%r",
                sure_ms, _tek_satir(statement), parameters,
            )


def install_perf_logging(application: FastAPI) -> None:
    """main.py'den BIR KEZ cagrilir."""
    global _kuruldu
    if not settings.PERF_LOG_ENABLED or _kuruldu:
        return
    _kuruldu = True
    _sorgu_dinleyicilerini_kur()

    @application.middleware("http")
    async def _olc(request: Request, call_next):
        olcum = IstekOlcumu()
        _olcum.set(olcum)
        basla = time.perf_counter()

        try:
            yanit = await call_next(request)
        except Exception:
            sure_ms = (time.perf_counter() - basla) * 1000
            logger.warning(
                "%s %s -> HATA | %.1f ms | %d sorgu",
                request.method, request.url.path, sure_ms, olcum.sorgu,
            )
            raise

        sure_ms = (time.perf_counter() - basla) * 1000

        # Olcum betigi bu basliklari okuyor. Uretimde de zararsiz;
        # istemci gormezden gelir, ama sahadaki yavasligi teshis ettirir.
        yanit.headers["X-Process-Time-Ms"] = f"{sure_ms:.1f}"
        yanit.headers["X-Query-Count"] = str(olcum.sorgu)
        yanit.headers["X-Query-Time-Ms"] = f"{olcum.sorgu_ms:.1f}"

        yavas = sure_ms >= settings.SLOW_REQUEST_MS
        cok_sorgu = olcum.sorgu >= settings.QUERY_COUNT_WARN
        logger.log(
            logging.WARNING if (yavas or cok_sorgu) else logging.INFO,
            "%s %s -> %s | %.1f ms | %d sorgu (%.1f ms)%s%s",
            request.method, request.url.path, yanit.status_code,
            sure_ms, olcum.sorgu, olcum.sorgu_ms,
            "  <-- YAVAS ISTEK" if yavas else "",
            "  <-- N+1 SUPHESI" if cok_sorgu else "",
        )
        return yanit