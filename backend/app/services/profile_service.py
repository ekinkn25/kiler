"""Profil hesaplamaları: BMR TDEE makro hedefleri"""
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from app.models import User, UserProfile
from app.models.enums import ActivityLevel, Gender, Goal
from app.schemas.user import UserProfileCreate

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

def _bmr_hesapla(data: UserProfileCreate) -> float | None:
    if data.birth_year is None or data.height_cm is None or data.weight_kg is None:
        return None 

    yas = datetime.now().year - data.birth_year
    taban = 10 * data.weight_kg + 6.25 * data.height_cm - 5 * yas

    if data.gender == Gender.ERKEK:
        return taban + 5
    if data.gender == Gender.KADIN:
        return taban - 161
    return taban - 78  #belirtilmedi veya None

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

    bmr = _bmr_hesapla(data)
    if bmr is None:
        profil.bmr = None
        profil.tdee = None
        profil.daily_calorie_target = _VARSAYILAN_KALORI
        profil.protein_target_g = None
        profil.carb_target_g = None
        profil.fat_target_g = None
    else: 
        tdee = bmr * _AKTIVITE_CARPANI[data.activity_level]
        hedef = tdee + _HEDEF_KCAL_FARK[data.goal]
        protein = data.weight_kg *1.6
        yag = hedef * 0.25 / 9
        karbonhidrat = (hedef - protein * 4 - yag * 9) / 4

        profil.bmr = round(bmr, 1)
        profil.tdee = round(tdee, 1)
        profil.daily_calorie_target = round(hedef, 1)
        profil.protein_target_g = round(protein, 1)
        profil.fat_target_g = round(yag, 1)
        profil.carb_target_g = round(karbonhidrat, 1)

    db.add(profil)
    return profil