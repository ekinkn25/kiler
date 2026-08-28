"""PATCH /me/profile ve kilo gunlugu birim testleri.

Kapsam: kismi guncellemenin gercekten KISMI olmasi, hedeflerin yeniden
hesaplanmasi, kilo degisiminin gunluge dusmesi ve gecmise donuk
duzeltmelerin profili bozmamasi.
"""
from datetime import date, timedelta

import pytest
from sqlalchemy import create_engine, func, select
from sqlalchemy.orm import sessionmaker

from app.core.exceptions import NotFoundError, PermissionDeniedError
from app.db.base import Base
from app.models import User, WeightLog
from app.models.enums import ActivityLevel, Gender, Goal
from app.schemas import UserProfileCreate, UserProfileUpdate, WeightLogCreate
from app.services import profile_service, weight_service


@pytest.fixture()
def db():
    motor = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(motor)
    oturum = sessionmaker(bind=motor)()
    yield oturum
    oturum.close()


@pytest.fixture()
def user(db):
    k = User(email="profil_test@example.com", hashed_password="x")
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@pytest.fixture()
def profilli_user(db, user):
    """Anketi tamamlamis kullanici: 80 kg, 180 cm, koruma hedefi."""
    profile_service.upsert_profile(db, user, UserProfileCreate(
        birth_year=1995,
        gender=Gender.ERKEK,
        height_cm=180,
        weight_kg=80,
        activity_level=ActivityLevel.ORTA,
        goal=Goal.KORUMA,
        household_size=2,
    ))
    db.commit()
    db.refresh(user)
    return user


def _kilo_kayit_sayisi(db, user_id: int) -> int:
    return db.execute(
        select(func.count()).select_from(WeightLog).where(WeightLog.user_id == user_id)
    ).scalar()


# ------------------------------------------------------------------ PATCH
def test_kismi_guncelleme_gonderilmeyen_alani_silmez(db, profilli_user):
    profile_service.update_profile(
        db, profilli_user, UserProfileUpdate(weight_kg=78),
    )

    p = profilli_user.profile
    assert p.weight_kg == 78
    # Gonderilmeyen alanlar AYNEN durmali - exclude_unset'in tum meselesi bu.
    assert p.height_cm == 180
    assert p.birth_year == 1995
    assert p.gender == Gender.ERKEK
    assert p.household_size == 2


def test_kilo_degisince_hedefler_yeniden_hesaplanir(db, profilli_user):
    eski_hedef = profilli_user.profile.daily_calorie_target
    eski_protein = profilli_user.profile.protein_target_g

    profile_service.update_profile(
        db, profilli_user, UserProfileUpdate(weight_kg=90),
    )

    p = profilli_user.profile
    assert p.daily_calorie_target > eski_hedef      # 10 kg fazla -> daha yuksek TDEE
    assert p.protein_target_g == pytest.approx(90 * 1.6, abs=0.1)
    assert p.protein_target_g > eski_protein


def test_hedef_degisince_kalori_dusuyor(db, profilli_user):
    koruma = profilli_user.profile.daily_calorie_target

    profile_service.update_profile(
        db, profilli_user, UserProfileUpdate(goal=Goal.KILO_VERME),
    )

    assert profilli_user.profile.daily_calorie_target == pytest.approx(koruma - 500, abs=0.2)


def test_acik_null_zorunlu_alani_bozmaz(db, profilli_user):
    """`goal: null` gonderilse bile NOT NULL kolon bosaltilmaz."""
    profile_service.update_profile(
        db, profilli_user,
        UserProfileUpdate.model_validate({"goal": None, "household_size": None}),
    )

    assert profilli_user.profile.goal == Goal.KORUMA
    assert profilli_user.profile.household_size == 2


def test_null_gonderilen_nullable_alan_temizlenir(db, profilli_user):
    """gender gercekten nullable: acik null 'temizle' demektir."""
    profile_service.update_profile(
        db, profilli_user, UserProfileUpdate.model_validate({"gender": None}),
    )

    assert profilli_user.profile.gender is None


def test_profil_yoksa_404(db, user):
    with pytest.raises(NotFoundError):
        profile_service.update_profile(db, user, UserProfileUpdate(weight_kg=70))


# ------------------------------------------------------------------ kilo gunlugu
def test_anket_kilosu_gunlugun_ilk_noktasi(db, profilli_user):
    kayitlar = weight_service.kilo_gecmisi(db, profilli_user)
    assert len(kayitlar) == 1
    assert kayitlar[0].weight_kg == 80
    assert kayitlar[0].logged_date == date.today()


def test_profil_guncellemesi_gunluge_dusuyor(db, profilli_user):
    profile_service.update_profile(db, profilli_user, UserProfileUpdate(weight_kg=77.5))

    kayitlar = weight_service.kilo_gecmisi(db, profilli_user)
    # Ayni gun: yeni satir ACILMAZ, var olan guncellenir.
    assert _kilo_kayit_sayisi(db, profilli_user.id) == 1
    assert kayitlar[-1].weight_kg == 77.5


def test_ayni_gune_ikinci_kayit_gunceller(db, profilli_user):
    weight_service.kilo_kaydet(db, profilli_user, WeightLogCreate(weight_kg=79))
    weight_service.kilo_kaydet(db, profilli_user, WeightLogCreate(weight_kg=78))

    assert _kilo_kayit_sayisi(db, profilli_user.id) == 1
    assert profilli_user.profile.weight_kg == 78


def test_gecmise_donuk_kayit_profili_degistirmez(db, profilli_user):
    weight_service.kilo_kaydet(db, profilli_user, WeightLogCreate(
        logged_date=date.today() - timedelta(days=10), weight_kg=95,
    ))

    # Profil "SU ANKI kilo"yu tutar: 10 gun onceki bir duzeltme onu bozmamali.
    assert profilli_user.profile.weight_kg == 80
    assert _kilo_kayit_sayisi(db, profilli_user.id) == 2


def test_gecmis_eskiden_yeniye_sirali(db, profilli_user):
    for gun_once, kilo in [(5, 82), (20, 84), (1, 81)]:
        weight_service.kilo_kaydet(db, profilli_user, WeightLogCreate(
            logged_date=date.today() - timedelta(days=gun_once), weight_kg=kilo,
        ))

    tarihler = [k.logged_date for k in weight_service.kilo_gecmisi(db, profilli_user)]
    assert tarihler == sorted(tarihler)


def test_pencere_disindaki_kayit_gelmiyor(db, profilli_user):
    weight_service.kilo_kaydet(db, profilli_user, WeightLogCreate(
        logged_date=date.today() - timedelta(days=100), weight_kg=99,
    ))

    kilolar = [k.weight_kg for k in weight_service.kilo_gecmisi(db, profilli_user, 30)]
    assert 99 not in kilolar


def test_baskasinin_kaydi_silinemez(db, profilli_user):
    yabanci = User(email="yabanci@example.com", hashed_password="x")
    db.add(yabanci)
    db.commit()

    kayit = weight_service.kilo_gecmisi(db, profilli_user)[0]
    with pytest.raises(PermissionDeniedError):
        weight_service.kilo_sil(db, yabanci, kayit.id)

    assert _kilo_kayit_sayisi(db, profilli_user.id) == 1


def test_olmayan_kayit_silinince_404(db, profilli_user):
    with pytest.raises(NotFoundError):
        weight_service.kilo_sil(db, profilli_user, 99999)
