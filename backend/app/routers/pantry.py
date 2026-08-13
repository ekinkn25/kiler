"""Kiler uclari. Su an SADECE W2-T10 kapsami: gorme tespitlerinin onayi.

DIKKAT: Kiler listeleme/elle ekleme/silme (W2-T01/T02) BURADA DEGIL -
bu dosya yalnizca /confirm-detected'i icerir.
"""
import logging

from fastapi import APIRouter, status

from app.services import barcode_service
from app.core.deps import ActiveUser, DbSession
from app.schemas import (
    ErrorResponse, IngredientRead, PantryConfirmDetectedRequest,
    PantryConfirmDetectedResponse, PantryConfirmScannedRequest, PantryScanRequest,
    ProductCreate, ProductRead, ProductScanResponse, ScannedConfirmResponse,
    )
from app.services.pantry_service import confirm_detected_ingredients

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/confirm-detected",
    response_model=PantryConfirmDetectedResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Gorme modeli tespitlerini onayla",
    description=(
        "W2-T04/T08/T10'da fotograftan tespit edilen malzemelerden "
        "kullanicinin SECTIKLERINI kilere yazar. availability='var', "
        "confidence_expires_at=simdi+7 gun (PANTRY_CONFIDENCE_DAYS)."
    ),
    responses={status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse}},
)
def confirm_detected(
    data: PantryConfirmDetectedRequest, db: DbSession, current_user: ActiveUser,
) -> PantryConfirmDetectedResponse:
    sonuc = confirm_detected_ingredients(
        db, current_user, data.canonical_name, data.source,
    )
    return PantryConfirmDetectedResponse(
        confirmed=sonuc.confirmed, skipped_unknown=sonuc.skipped_unknown,
    )


@router.post(
    "/scan",
    response_model=ProductScanResponse,
    summary="Barkod tara",
    description=(
        "Once products onbellegine bakilir, yoksa Open Food Facts'e "
        "gidilir. Sonuc ONAY EKRANINA doner - kilere HICBIR SEY "
        "YAZILMAZ. found=false ise POST /pantry/products ile manuel "
        "urun eklenmeli."
    ),
    responses={status.HTTP_502_BAD_GATEWAY: {"model": ErrorResponse}},
)
async def scan(
    data: PantryScanRequest, db: DbSession, current_user: ActiveUser,
) -> ProductScanResponse:
    sonuc = await barcode_service.scan_barcode(db, data.barcode)
    if not sonuc.found:
        return ProductScanResponse(
            found=False,
            message="Bu barkod veritabaninda bulunamadi. Urunu elle ekleyebilirsin.",
        )
    return ProductScanResponse(
        found=True,
        product=ProductRead.model_validate(sonuc.product),
        matched_ingredient=(
            IngredientRead.model_validate(sonuc.matched_ingredient)
            if sonuc.matched_ingredient else None
        ),
        from_cache=sonuc.from_cache,
    )


@router.post(
    "/products",
    response_model=ProductRead,
    status_code=status.HTTP_201_CREATED,
    summary="Manuel urun ekle (barkod bulunamadiginda)",
)
def create_product(
    data: ProductCreate, db: DbSession, current_user: ActiveUser,
) -> ProductRead:
    urun = barcode_service.create_manual_product(db, data)
    return ProductRead.model_validate(urun)


@router.post(
    "/confirm-scanned",
    response_model=ScannedConfirmResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Taranan/eklenen urunu onayla",
    description=(
        "product_id'nin bagli oldugu malzemeyi kilere yazar: "
        "availability='var', source='barkod', confidence_expires_at=+7 gun. "
        "Urun sozlukte hicbir malzemeyle eslesmediyse ingredient_id ZORUNLU."
    ),
    responses={
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_422_UNPROCESSABLE_ENTITY: {"model": ErrorResponse},
    },
)
def confirm_scanned(
    data: PantryConfirmScannedRequest, db: DbSession, current_user: ActiveUser,
) -> ScannedConfirmResponse:
    sonuc = barcode_service.confirm_scanned_product(
        db, current_user, data.product_id, data.ingredient_id,
    )
    return ScannedConfirmResponse(**sonuc)