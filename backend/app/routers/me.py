import json
import logging
from datetime import date
from fastapi import APIRouter, Query, Response, status
from app.core.deps import ActiveUser, DbSession
from app.schemas import (
    AccountDeleteRequest, AccountDeleteResponse, ErrorResponse,
    UserProfileRead, UserProfileUpdate, WeightLogCreate, WeightLogRead,
)
from app.services import privacy_service, profile_service, weight_service

logger = logging.getLogger(__name__)
router = APIRouter()


# ------------------------------------------------------------------ profil
@router.patch(
    "/profile",
    response_model=UserProfileRead,
    summary="Profil olculerini guncelle",
    description=(
        "PATCH semantigi: YALNIZCA gonderilen alanlar degisir. Gonderilmeyen "
        "alanlar oldugu gibi kalir.\n\n"
        "Her guncellemeden sonra BMR, TDEE, gunluk kalori ve makro hedefleri "
        "YENIDEN HESAPLANIR - kilo, boy, aktivite ve hedef dortlusunun hepsi "
        "kalori hedefini etkiler.\n\n"
        "`weight_kg` gonderilirse ayni deger BUGUNUN kilo gunlugune de yazilir; "
        "kullanici ayrica 'kilo ekle' yapmadan gecmis grafigi olusur.\n\n"
        "Profil satiri yoksa (anket tamamlanmamis) **404** doner."
    ),
    responses={
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse},
    },
)
def update_my_profile(
    data: UserProfileUpdate, db: DbSession, current_user: ActiveUser,
) -> UserProfileRead:
    profil = profile_service.update_profile(db, current_user, data)
    return UserProfileRead.model_validate(profil)


# ------------------------------------------------------------------ kilo gunlugu
@router.get(
    "/weight",
    response_model=list[WeightLogRead],
    summary="Kilo gecmisi",
    description=(
        "Son `days` gunun kayitlari, ESKIDEN YENIYE siralanmis - grafik "
        "x ekseninde ters cevirmeye gerek kalmasin.\n\n"
        f"Varsayilan {weight_service.VARSAYILAN_GUN} gun, "
        f"en fazla {weight_service.EN_FAZLA_GUN} gun."
    ),
)
def list_my_weight(
    db: DbSession,
    current_user: ActiveUser,
    days: int = Query(
        default=weight_service.VARSAYILAN_GUN,
        ge=1, le=weight_service.EN_FAZLA_GUN,
    ),
) -> list[WeightLogRead]:
    kayitlar = weight_service.kilo_gecmisi(db, current_user, days)
    return [WeightLogRead.model_validate(k) for k in kayitlar]


@router.post(
    "/weight",
    response_model=WeightLogRead,
    status_code=status.HTTP_201_CREATED,
    summary="Kilo kaydet",
    description=(
        "Gun basina TEK kayit tutulur: ayni gune ikinci kez yazmak yeni satir "
        "acmaz, o gunun degerini gunceller.\n\n"
        "Kayit en yeni tarihe aitse profildeki `weight_kg` ve kalori hedefleri "
        "de guncellenir. GECMISE donuk duzeltmeler profili DEGISTIRMEZ."
    ),
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
def create_my_weight(
    data: WeightLogCreate, db: DbSession, current_user: ActiveUser,
) -> WeightLogRead:
    kayit = weight_service.kilo_kaydet(db, current_user, data)
    return WeightLogRead.model_validate(kayit)


@router.delete(
    "/weight/{log_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Kilo kaydini sil",
    description=(
        "Yanlis girilen bir gunu siler. Profildeki guncel kilo GERI ALINMAZ - "
        "duzeltmenin dogru yolu dogru degeri yeniden kaydetmektir."
    ),
    responses={
        status.HTTP_403_FORBIDDEN: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
    },
)
def delete_my_weight(log_id: int, db: DbSession, current_user: ActiveUser) -> None:
    weight_service.kilo_sil(db, current_user, log_id)


# ------------------------------------------------------------------ KVKK
@router.get(
    "/export",
    tags=["kvkk"],
    summary="Verilerimi indir (KVKK)",
    description=(
        "Hesaba ait TUM kisisel veriyi tek JSON dosyasi olarak doner: profil, "
        "tercihler, kiler ve kiler gecmisi, alisveris listesi, ogun ve kilo "
        "kayitlari, swipe oturumlari, tarif geri bildirimleri, ogrenilen zevk "
        "agirliklari, sohbetler (mesajlariyla) ve gorme modeli istek kayitlari.\n\n"
        "**Parola ozeti dahil DEGILDIR.**\n\n"
        "**Fotograflar dahil degildir** - sunucuda saklanmiyorlar; yalnizca "
        "islenen isteklerin ozet kaydi vardir."
    ),
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
def export_me(db: DbSession, current_user: ActiveUser) -> Response:
    veri = privacy_service.export_user_data(db, current_user)

    # response_model yerine ham Response: (1) ensure_ascii=False ile Turkce
    # karakterler \u kacislari olarak degil duz metin cikar, (2) Content-
    # Disposition ile istemci dosyayi KAYDEDER, ekrana basmaz.
    dosya_adi = f"kalori-verilerim-{current_user.id}-{date.today().isoformat()}.json"
    return Response(
        content=json.dumps(veri, ensure_ascii=False, indent=2),
        media_type="application/json",
        headers={"Content-Disposition": f'attachment; filename="{dosya_adi}"'},
    )


@router.delete(
    "",
    response_model=AccountDeleteResponse,
    tags=["kvkk"],
    summary="Hesabimi kalici olarak sil (KVKK)",
    description=(
        "Hesabi ve bagli TUM veriyi geri donusu olmadan siler.\n\n"
        "**Parola teyidi zorunludur** - calinmis bir token ile hesap silinemesin. "
        "Ayrica `confirm` alanina birebir `HESABIMI SIL` yazilmalidir.\n\n"
        "Silme sonrasi mevcut access/refresh token'lar otomatik gecersizlesir: "
        "token yalnizca kimlik numarasi tasir, o kullanici artik yok."
    ),
    responses={status.HTTP_401_UNAUTHORIZED: {"model": ErrorResponse}},
)
def delete_me(
    data: AccountDeleteRequest, db: DbSession, current_user: ActiveUser,
) -> AccountDeleteResponse:
    silinen = privacy_service.delete_user_account(db, current_user, data.password)
    return AccountDeleteResponse(deleted=True, deleted_rows=silinen)
