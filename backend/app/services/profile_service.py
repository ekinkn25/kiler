"""Profil hesaplamaları: BMR TDEE makro hedefleri ve profil güncelleme"""
from __future__ import annotations
from datetime import date, datetime
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundError
from app.models import User, UserProfile, WeightLog
from app.models.enums import ActivityLevel, Gender, Goal
from app.schemas.user import UserProfileCreate, UserProfileUpdate

_AKTIVITE_CARPANI : dict[ActivityLevel, float] = {
    ActivityLevel.SEDANTER: 1.2,
    ActivityLevel.HAFIF: 1.375,
    ActivityLevel.ORTA: 1.55,
    ActivityLevel.YUKSEK: 1.725,
    ActivityLevel.COK_YUKSEK: 1.9,
}

_HEDEF_KCAL_FARK: dict[Goal, float] = {
    Goal.KILO_VERME : -500.0,
    Goal.KORUMA : 0.0,
    Goal.KILO_ALMA : 300.0,
}

_VARSAYILAN_KALORI = 2000.0

# PATCH ile ACIKCA null gonderilse bile bosaltilamayan alanlar: veritabaninda
# NOT NULL tanimlilar. gender gibi gercekten nullable alanlarda null gondermek
# "temizle" demektir ve gecerlidir - o yuzden liste dar tutuldu.
_BOSALTILAMAZ = frozenset({"activity_level", "goal", "household_size"})


def _bmr_hesapla(profil: UserProfile) -> float | None:
    """Mifflin-St Jeor. Boy/kilo/dogum yilindan biri eksikse hesaplanamaz."""
    if profil.birth_year is None or profil.height_cm is None or profil.weight_kg is None:
        return None

    yas = datetime.now().year - profil.birth_year
    taban = 10 * profil.weight_kg + 6.25 * profil.height_cm - 5 * yas

    if profil.gender == Gender.ERKEK:
        return taban + 5
    if profil.gender == Gender.KADIN:
        return taban - 161
    return taban - 78  #belirtilmedi veya None


def hedefleri_yenile(profil: UserProfile) -> None:
    """BMR/TDEE/kalori/makro alanlarini profildeki OLCULERDEN yeniden yazar.

    NEDEN AYRI FONKSIYON: hem onboarding (upsert_profile) hem de sonraki
    duzenlemeler (update_profile, kilo kaydi) ayni hesabi yapmak zorunda.
    Iki kopya olsaydi biri duzeltilip digeri unutuldugunda kullanici
    "kilomu degistirdim ama hedefim degismedi" derdi.
    """
    bmr = _bmr_hesapla(profil)
    if bmr is None:
        profil.bmr = None
        profil.tdee = None
        profil.daily_calorie_target = _VARSAYILAN_KALORI
        profil.protein_target_g = None
        profil.carb_target_g = None
        profil.fat_target_g = None
        return

    tdee = bmr * _AKTIVITE_CARPANI[profil.activity_level]
    hedef = tdee + _HEDEF_KCAL_FARK[profil.goal]
    protein = profil.weight_kg * 1.6
    yag = hedef * 0.25 / 9
    karbonhidrat = (hedef - protein * 4 - yag * 9) / 4

    profil.bmr = round(bmr, 1)
    profil.tdee = round(tdee, 1)
    profil.daily_calorie_target = round(hedef, 1)
    profil.protein_target_g = round(protein, 1)
    profil.fat_target_g = round(yag, 1)
    profil.carb_target_g = round(karbonhidrat, 1)


def upsert_profile(db: Session, user: User, data: UserProfileCreate) -> UserProfile:
    """profili oluşturur ya da günceller ayrıca kalori-mikro hedeflerini hesaplar"""
    profil = user.profile or UserProfile(user_id = user.id)

    profil.birth_year = data.birth_year
    profil.gender = data.gender
    profil.height_cm = data.height_cm
    profil.weight_kg = data.weight_kg
    profil.activity_level = data.activity_level
    profil.goal = data.goal
    profil.household_size = data.household_size

    hedefleri_yenile(profil)

    db.add(profil)

    # Anketteki kilo ayni zamanda gecmisin ILK noktasidir. Olmasaydi grafik
    # kullanici ilk duzenlemesini yapana kadar bos kalirdi.
    if data.weight_kg is not None:
        kilo_gunlugune_yaz(db, user.id, data.weight_kg)

    return profil


def kilo_gunlugune_yaz(
    db: Session, user_id: int, kilo: float, gun: date | None = None,
) -> WeightLog:
    """Gunun kilo kaydini yazar; ayni gune ikinci kayit UPDATE'tir.

    (user_id, logged_date) veritabaninda BENZERSIZ (uq_weight_user_date):
    kullanici gun icinde uc kez tartilirsa grafikte uc nokta degil,
    o gunun SON degeri gorunur.
    """
    gun = gun or date.today()
    kayit = db.execute(
        select(WeightLog).where(
            WeightLog.user_id == user_id, WeightLog.logged_date == gun,
        )
    ).scalar_one_or_none()

    if kayit is None:
        kayit = WeightLog(user_id=user_id, logged_date=gun, weight_kg=kilo)
        db.add(kayit)
    else:
        kayit.weight_kg = kilo
    return kayit


def update_profile(db: Session, user: User, data: UserProfileUpdate) -> UserProfile:
    """PATCH /me/profile: yalnizca GONDERILEN alanlari degistirir.

    Her degisiklikten sonra hedefler yeniden hesaplanir - kilo/boy/aktivite/
    hedef dortlusunun hepsi kalori hedefini etkiler.
    """
    profil = user.profile
    if profil is None:
        # Anket tamamlanmadan profil satiri yok. 404 dogru cevap: istemci
        # kullaniciyi onboarding'e yonlendirsin, bos bir profil YARATMAYALIM.
        raise NotFoundError("Profil bulunamadi - once tanima anketini tamamlayin.")

    # exclude_unset PATCH'in TAM ANLAMI: model_dump() olsaydi gonderilmeyen
    # her alan None gelir ve mevcut degerleri SILERDI.
    degisenler = data.model_dump(exclude_unset=True)

    for alan, deger in degisenler.items():
        if deger is None and alan in _BOSALTILAMAZ:
            continue
        setattr(profil, alan, deger)

    hedefleri_yenile(profil)

    # Kilo degistiyse gunluge de dusuyor: kullanici ayri bir "kilo ekle"
    # adimi yapmadan gecmis grafigi kendiliginden olusur.
    yeni_kilo = degisenler.get("weight_kg")
    if yeni_kilo is not None:
        kilo_gunlugune_yaz(db, user.id, yeni_kilo)

    db.commit()
    db.refresh(profil)
    return profil
