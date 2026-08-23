"""Alisveris listesi uclari. W3-T09.

Sprint planinda bu API'yi yazan bir gorev YOK: W3-T21 yalnizca ekrani
yapiyor, W4-T05 ise toplu eklemenin var oldugunu varsayiyor. Swipe'taki
'malzemem yok' akisi calisabilsin diye burada aciliyor.
"""
import logging

from fastapi import APIRouter, Query, status

from app.core.deps import ActiveUser, DbSession
from app.schemas import ErrorResponse, ShoppingBulkAdd, ShoppingItemRead
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