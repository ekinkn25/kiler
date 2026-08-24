"""Alisveris listesi uclari. W3-T09.

Sprint planinda bu API'yi yazan bir gorev YOK: W3-T21 yalnizca ekrani
yapiyor, W4-T05 ise toplu eklemenin var oldugunu varsayiyor. Swipe'taki
'malzemem yok' akisi calisabilsin diye burada aciliyor.
"""
import logging

from fastapi import APIRouter, Query, status

from app.core.deps import ActiveUser, DbSession
from app.schemas import (
    ErrorResponse, ShoppingBulkAdd, ShoppingItemRead, ShoppingManualAdd,
    ShoppingTransferRequest, ShoppingTransferResponse,
)
from app.services import shopping_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get(
    "",
    response_model=list[ShoppingItemRead],
    summary="Alisveris listesi",
    description="En yeni kayit ustte doner.",
)
def list_shopping(
    db: DbSession,
    current_user: ActiveUser,
    include_checked: bool = Query(
        default=True, description="Alinmis (isaretli) olanlar da donsun mu?"
    ),
) -> list[ShoppingItemRead]:
    kayitlar = shopping_service.list_items(
        db, current_user, include_checked=include_checked
    )
    return [ShoppingItemRead.model_validate(k) for k in kayitlar]


@router.post(
    "/bulk",
    response_model=list[ShoppingItemRead],
    status_code=status.HTTP_201_CREATED,
    summary="Tariften toplu ekleme",
    description=(
        "Swipe kartinda 'Malzemem yok' denen malzemeleri listeye yazar "
        "(`source='tarif'`).\n\n"
        "Zaten listede olan malzeme icin YENI satir acilmaz; var olan "
        "guncellenir ve 'alindi' isareti kaldirilir."
    ),
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
def bulk_add(
    data: ShoppingBulkAdd, db: DbSession, current_user: ActiveUser,
) -> list[ShoppingItemRead]:
    kayitlar = shopping_service.add_from_recipe(
        db, current_user, recipe_id=data.recipe_id, items=data.items,
    )
    return [ShoppingItemRead.model_validate(k) for k in kayitlar]

@router.post(
    "",
    response_model=ShoppingItemRead,
    status_code=status.HTTP_201_CREATED,
    summary="Elle tek oge ekle",
    description=(
        "W3-T21: yazilan adi sozlukle eslestirir. Eslesirse kilere "
        "aktarilabilir; eslesmezse serbest metin olarak saklanir."
    ),
)
def add_manual_item(
    data: ShoppingManualAdd, db: DbSession, current_user: ActiveUser,
) -> ShoppingItemRead:
    kayit = shopping_service.add_manual(db, current_user, data.name)
    return ShoppingItemRead.model_validate(kayit)


@router.patch(
    "/{item_id}",
    response_model=ShoppingItemRead,
    summary="Isaretle / kaldir",
    responses={status.HTTP_404_NOT_FOUND: {"model": ErrorResponse}},
)
def toggle_checked(
    item_id: int,
    db: DbSession,
    current_user: ActiveUser,
    checked: bool = Query(description="true -> alindi isareti"),
) -> ShoppingItemRead:
    kayit = shopping_service.set_checked(db, current_user, item_id, checked=checked)
    return ShoppingItemRead.model_validate(kayit)


@router.post(
    "/transfer-to-pantry",
    response_model=ShoppingTransferResponse,
    summary="Isaretlenenleri kilere aktar",
    description=(
        "W3-T21: isaretli ogeleri kilere 'var' olarak yazar ve listeden "
        "siler. item_ids bos gonderilirse TUM isaretliler aktarilir."
    ),
)
def transfer_to_pantry(
    data: ShoppingTransferRequest, db: DbSession, current_user: ActiveUser,
) -> ShoppingTransferResponse:
    sonuc = shopping_service.transfer_to_pantry(
        db, current_user, item_ids=data.item_ids or None
    )
    return ShoppingTransferResponse(**sonuc)