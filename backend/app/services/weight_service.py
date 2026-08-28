"""Kilo gunlugu: kayit, gecmis ve silme.

NEDEN AYRI SERVIS: profile_service "su anki kilo"yu ve ondan turetilen
hedefleri yonetir; burasi ZAMAN SERISINI yonetir. Ikisi farkli sorular
soruyor - "bugun kac kilosun" ve "uc ayda ne oldu".

Bagimlilik TEK YONLU: weight_service -> profile_service. Tersi yok.
"""
from __future__ import annotations

import logging
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundError, PermissionDeniedError
from app.models import User, WeightLog
from app.schemas.nutrition import WeightLogCreate
from app.services import profile_service

logger = logging.getLogger(__name__)

# Grafik icin makul ust sinir. Daha uzun aralik istenirse uc `days`
# parametresiyle acilir; sinirsiz sorgu ACILMAZ (tek kullanicinin 10 yillik
# kaydi bile tek ekrana sigmaz, bosuna bant genisligi).
VARSAYILAN_GUN = 90
EN_FAZLA_GUN = 730


def kilo_kaydet(db: Session, user: User, data: WeightLogCreate) -> WeightLog:
    """Bir gunun kilosunu yazar ve gerekiyorsa profildeki kiloyu senkronlar."""
    # Ekleme YAPILMADAN once soruyoruz: yazdiktan sonra sorsaydik cevap her
    # zaman "evet, bu en yeni" olurdu.
    en_son_tarih = db.execute(
        select(func.max(WeightLog.logged_date)).where(WeightLog.user_id == user.id)
    ).scalar()

    kayit = profile_service.kilo_gunlugune_yaz(
        db, user.id, data.weight_kg, data.logged_date,
    )

    # Profildeki weight_kg "SU ANKI kilo"dur. Kullanici gecmise donuk bir gunu
    # duzeltirse (orn. gecen hafta tartilmayi unuttum) profil ve kalori hedefi
    # DEGISMEZ - yalnizca en yeni tarih guncel kiloyu temsil eder.
    en_yeni_mi = en_son_tarih is None or data.logged_date >= en_son_tarih
    if en_yeni_mi and user.profile is not None:
        user.profile.weight_kg = data.weight_kg
        profile_service.hedefleri_yenile(user.profile)

    db.commit()
    db.refresh(kayit)
    logger.info(
        "Kilo kaydi | kullanici=%s tarih=%s kilo=%s guncel=%s",
        user.id, data.logged_date, data.weight_kg, en_yeni_mi,
    )
    return kayit


def kilo_gecmisi(
    db: Session, user: User, gun_sayisi: int = VARSAYILAN_GUN,
) -> list[WeightLog]:
    """Son `gun_sayisi` gunun kayitlari, ESKIDEN YENIYE siralanmis.

    Siralama grafik icin: istemci ters cevirmek zorunda kalmasin, x ekseni
    dogal yonde ilerlesin.
    """
    gun_sayisi = max(1, min(gun_sayisi, EN_FAZLA_GUN))
    baslangic = date.today() - timedelta(days=gun_sayisi)
    return list(db.scalars(
        select(WeightLog)
        .where(WeightLog.user_id == user.id, WeightLog.logged_date >= baslangic)
        .order_by(WeightLog.logged_date)
    ))


def kilo_sil(db: Session, user: User, log_id: int) -> None:
    """Yanlis girilen bir gunu siler. Profildeki kilo GERI ALINMAZ.

    NEDEN: profil kilosunu "bir onceki kayda" dondurmek, kullanicinin kalori
    hedefini o bilmeden degistirir. Yanlis kiloyu duzeltmenin dogru yolu
    dogru degeri yeniden kaydetmektir.
    """
    kayit = db.get(WeightLog, log_id)
    if kayit is None:
        raise NotFoundError("Kilo kaydi bulunamadi.")
    if kayit.user_id != user.id:
        raise PermissionDeniedError("Bu kilo kaydi size ait degil.")
    db.delete(kayit)
    db.commit()
    logger.info("Kilo kaydi silindi | kullanici=%s id=%s", user.id, log_id)
