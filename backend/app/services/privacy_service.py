"""KVKK veri disa aktarma ve hesap silme. W4-T14.

IKI ILKE:
  1) EKSIKSIZLIK - export, user_id tasiyan HER tabloyu icermeli. Eksik
     export, fazla export'tan daha buyuk bir uyumsuzluktur.
  2) ASGARI VERI - parola ozeti (hash) hicbir kosulda disa aktarilmaz.
     Kullanicinin kendi hesabi bile olsa hash'i eline vermek gereksiz risk.

FOTOGRAF NOTU: yuklenen fotograflar HICBIR YERDE saklanmiyor. vision_requests
yalnizca SHA-256 ozeti, boyut ve gecikme tutar; goruntunun kendisi bellekte
islenip atilir. Bu yuzden export'ta fotograf YOKTUR - olmadigi icin.
"""
from __future__ import annotations

import enum
import logging
from datetime import date, datetime
from typing import Any

from sqlalchemy import func, inspect as sa_inspect, select, text
from sqlalchemy.orm import Session

from app.core.exceptions import UnauthorizedError
from app.core.security import verify_password
from app.models import (
    ChatConversation, MealLog, PantryEvent, PantryItem, RecipeFavorite,
    RecipeFeedback, ShoppingListItem, User, UserProfile, VisionRequest,
    WeightLog,
)
from app.models.recipe import SwipeSession, UserTasteWeight

logger = logging.getLogger(__name__)

# Disa aktarilmayan sutunlar.
GIZLI_SUTUNLAR = {"hashed_password"}

# user_id tasiyan TUM modeller. Silme ozeti ve testler bunu okur.
# YENI KULLANICI TABLOSU EKLERKEN BURAYA DA EKLE - tests/test_kvkk.py
# semayi tarayip bu listeyle karsilastiriyor, unutursan test kirilir.
KULLANICI_MODELLERI = (
    UserProfile, PantryItem, PantryEvent, ShoppingListItem, MealLog,
    WeightLog, SwipeSession, RecipeFeedback, RecipeFavorite,
    UserTasteWeight, ChatConversation, VisionRequest,
)

ILISKI_TABLOLARI = ("user_diet_tags", "user_allergens")


def _satir(nesne) -> dict[str, Any]:
    """ORM nesnesini duz sozluge cevirir.

    Sutunlari ELLE saymiyoruz: modele yeni bir alan eklendiginde export
    kendiliginden onu da icerir. Elle yazsaydik her sema degisikliginde
    export sessizce eksilirdi.
    """
    cikti: dict[str, Any] = {}
    for sutun in sa_inspect(nesne).mapper.column_attrs:
        ad = sutun.key
        if ad in GIZLI_SUTUNLAR:
            continue
        deger = getattr(nesne, ad)
        if isinstance(deger, (datetime, date)):
            deger = deger.isoformat()
        elif isinstance(deger, enum.Enum):
            deger = deger.value
        cikti[ad] = deger
    return cikti


def export_user_data(db: Session, user: User) -> dict[str, Any]:
    """Kullanicinin tum verisini tek sozlukte toplar."""
    uid = user.id

    def hepsi(model) -> list[dict]:
        return [_satir(k) for k in db.scalars(
            select(model).where(model.user_id == uid)
        )]

    sohbetler = list(db.scalars(
        select(ChatConversation).where(ChatConversation.user_id == uid)
    ))

    veri = {
        "_aciklama": (
            "KVKK 11. madde kapsaminda uretilen kisisel veri disa aktarimidir. "
            "Parola ozeti guvenlik geregi DAHIL DEGILDIR. Yuklenen fotograflar "
            "sunucuda saklanmadigi icin export'ta yer almaz; yalnizca islenen "
            "isteklerin ozet (hash) kaydi bulunur."
        ),
        "_uretim_tarihi": datetime.now().astimezone().isoformat(),
        "_surum": 1,

        "hesap": _satir(user),
        "profil": _satir(user.profile) if user.profile else None,
        "diyet_etiketleri": [d.code for d in user.diet_tags],
        "alerjenler": [a.code for a in user.allergens],

        "kiler": hepsi(PantryItem),
        "kiler_gecmisi": hepsi(PantryEvent),
        "alisveris_listesi": hepsi(ShoppingListItem),
        "ogun_kayitlari": hepsi(MealLog),
        "kilo_kayitlari": hepsi(WeightLog),

        "swipe_oturumlari": hepsi(SwipeSession),
        "tarif_geri_bildirimleri": hepsi(RecipeFeedback),
        "tarif_favorileri": hepsi(RecipeFavorite),
        "ogrenilen_zevk_agirliklari": hepsi(UserTasteWeight),

        # Mesajlar sohbetin ICINE gomuluyor: duz liste verilseydi kullanici
        # hangi mesajin hangi sohbete ait oldugunu goremezdi.
        "sohbetler": [
            {**_satir(s), "mesajlar": [_satir(m) for m in s.messages]}
            for s in sohbetler
        ],
        "gorme_modeli_istekleri": hepsi(VisionRequest),
    }

    logger.info(
        "Veri disa aktarimi | kullanici=%s | bolum=%d",
        uid, sum(1 for k in veri if not k.startswith("_")),
    )
    return veri


def kayit_sayilari(db: Session, uid: int) -> dict[str, int]:
    """Kullaniciya ait satir sayilari. Silme oncesi/sonrasi karsilastirma icin."""
    return {
        m.__tablename__: db.scalar(
            select(func.count()).select_from(m).where(m.user_id == uid)
        ) or 0
        for m in KULLANICI_MODELLERI
    }


def delete_user_account(db: Session, user: User, password: str) -> dict[str, int]:
    """Hesabi ve bagli TUM veriyi kalici olarak siler.

    PAROLA TEYIDI SART: calinmis bir access token ile hesap silinememeli.
    Token 30 dakika gecerli; parola ise yalnizca kullanicinin bildigi seydir.

    Silme DB'nin ON DELETE CASCADE zincirine birakilir (bkz. passive_deletes).
    """
    if not verify_password(password, user.hashed_password):
        # Hangi alanin yanlis oldugunu soylemiyoruz; zaten kimlik dogrulanmis
        # durumda, tek eksik parola teyidi.
        raise UnauthorizedError("Parola hatali. Hesap silinmedi.")

    uid = user.id
    silinecek = kayit_sayilari(db, uid)

    db.delete(user)
    db.commit()

    # E-POSTA LOGLANMIYOR: silinen hesabin kimligini loglarda yasatmak
    # silme talebinin amacina aykiri olurdu. Yalnizca kimlik numarasi.
    logger.warning("HESAP SILINDI | kullanici=%s | silinen satirlar=%s", uid, silinecek)
    return silinecek

def kayit_sayilari(db: Session, uid: int) -> dict[str, int]:
    """Kullaniciya ait satir sayilari. Silme oncesi/sonrasi karsilastirma icin."""
    ozet = {
        m.__tablename__: db.scalar(
            select(func.count()).select_from(m).where(m.user_id == uid)
        ) or 0
        for m in KULLANICI_MODELLERI
    }
    for tablo in ILISKI_TABLOLARI:
        ozet[tablo] = db.execute(
            text(f"SELECT COUNT(*) FROM {tablo} WHERE user_id = :u"), {"u": uid}
        ).scalar() or 0
    return ozet