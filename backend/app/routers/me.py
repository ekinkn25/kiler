import json
import logging
from datetime import date
from fastapi import APIRouter, Response, status
from app.core.deps import ActiveUser, DbSession
from app.schemas import AccountDeleteRequest, AccountDeleteResponse, ErrorResponse
from app.services import privacy_service

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get(
    "/export",
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
