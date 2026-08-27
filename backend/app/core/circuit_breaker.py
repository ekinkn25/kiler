"""W4-T15: devre kesici (circuit breaker).

NEDEN: Saglayici tamamen kapaliyken her istek yeniden-deneme x zaman asimi
kadar bekliyor (2 deneme x 20 sn ~ 60 sn). Kullanici 200 yanit alsa bile
60 sn bekleyen ekran 'kullanilabilir' degildir.

UC DURUM:
  kapali    -> normal calisma, cagri gecer
  acik      -> cagri HIC yapilmaz, aninda dususe gidilir (hizli basarisizlik)
  yari_acik -> sure dolunca TEK bir deneme cagrisina izin verilir;
               basarili olursa devre kapanir, olmazsa yeniden acilir

Kilit KULLANILMIYOR: sayac ve zaman damgasindan ibaret; yaris durumunda en
kotu ihtimalle bir fazla deneme cagrisi yapilir - zararsiz.
"""
from __future__ import annotations

import logging
import time
from app.core.config import settings

logger = logging.getLogger(__name__)


class DevreKesici:
    __slots__ = ("ad", "hata_esigi", "acik_kalma", "_ardisik_hata", "_acilma_ani")

    def __init__(self, ad: str, *, hata_esigi: int = 3, acik_kalma_saniye: float = 60) -> None:
        self.ad = ad
        self.hata_esigi = hata_esigi
        self.acik_kalma = acik_kalma_saniye
        self._ardisik_hata = 0
        self._acilma_ani: float | None = None

    # ------------------------------------------------------------------
    @property
    def durum(self) -> str:
        if self._acilma_ani is None:
            return "kapali"
        if time.monotonic() - self._acilma_ani >= self.acik_kalma:
            return "yari_acik"
        return "acik"

    def izin_var_mi(self) -> bool:
        """False ise cagri YAPILMAZ; cagiran dogrudan dususe gecmeli."""
        return self.durum != "acik"

    def basarili(self) -> None:
        if self._ardisik_hata or self._acilma_ani is not None:
            logger.info("Devre '%s' kapandi (saglayici geri geldi).", self.ad)
        self._ardisik_hata = 0
        self._acilma_ani = None

    def basarisiz(self) -> None:
        self._ardisik_hata += 1
        if self._ardisik_hata >= self.hata_esigi:
            self._acilma_ani = time.monotonic()
            logger.error(
                "Devre '%s' ACILDI: %d ardisik hata. %.0f sn boyunca cagri yapilmayacak.",
                self.ad, self._ardisik_hata, self.acik_kalma,
            )

    def sifirla(self) -> None:
        """Testler icin."""
        self._ardisik_hata = 0
        self._acilma_ani = None


# Surec omru boyunca tek ornek: sayaclar istekler arasinda PAYLASILMALI.
gorme_devresi = DevreKesici(
    "gorme",
    hata_esigi=settings.CIRCUIT_FAILURE_THRESHOLD,
    acik_kalma_saniye=settings.CIRCUIT_OPEN_SECONDS,
)
sohbet_devresi = DevreKesici(
    "sohbet",
    hata_esigi=settings.CIRCUIT_FAILURE_THRESHOLD,
    acik_kalma_saniye=settings.CIRCUIT_OPEN_SECONDS,
)