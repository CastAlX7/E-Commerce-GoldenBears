from pathlib import Path
from fastapi import APIRouter, Depends, Query, UploadFile, File, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_admin
from app.models.user import User
from app.schemas.product import ProductOut, ProductCreate, ProductUpdate, ProductListResponse, CategoryOut, BrandOut
from app.services import product_service

IMAGES_DIR = Path(__file__).parent.parent.parent / "static" / "images"
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}

router = APIRouter(prefix="/api", tags=["products"])


@router.get("/products", response_model=ProductListResponse)
async def list_products(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    search: str | None = Query(None),
    category_id: int | None = Query(None),
    brand_id: int | None = Query(None),
    enabled_only: bool = Query(True),
    db: AsyncSession = Depends(get_db),
):
    return await product_service.list_products(db, page, size, search, category_id, brand_id, enabled_only)


@router.get("/products/{product_id}", response_model=ProductOut)
async def get_product(product_id: str, db: AsyncSession = Depends(get_db)):
    return await product_service.get_product(db, product_id)


@router.post("/products", response_model=ProductOut, status_code=201)
async def create_product(
    body: ProductCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await product_service.create_product(db, body)


@router.put("/products/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: str,
    body: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await product_service.update_product(db, product_id, body)


@router.delete("/products/{product_id}", status_code=204)
async def delete_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await product_service.delete_product(db, product_id)


@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    return await product_service.list_categories(db)


@router.get("/brands", response_model=list[BrandOut])
async def list_brands(
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    return await product_service.list_brands(db, category_id)


@router.post("/products/{product_id}/upload-image", response_model=ProductOut)
async def upload_product_image(
    product_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Solo se permiten imágenes (jpeg, png, webp, gif)")

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "jpg"

    # Eliminar imagen anterior del mismo producto si existe
    for old in IMAGES_DIR.glob(f"{product_id}.*"):
        old.unlink()

    dest = IMAGES_DIR / f"{product_id}.{ext}"
    dest.write_bytes(await file.read())

    image_url = f"/static/images/{product_id}.{ext}"
    return await product_service.update_product(db, product_id, ProductUpdate(image_url=image_url))
