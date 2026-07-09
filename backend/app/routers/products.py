from pathlib import Path
from fastapi import APIRouter, Depends, Query, Response, UploadFile, File, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_admin
from app.models.user import User
from app.redis_client import cache_get, cache_set, cache_delete
from app.schemas.product import (
    ProductOut, ProductCreate, ProductUpdate, ProductListResponse,
    CategoryOut, BrandOut, CategoryCreate, CategoryUpdate, BrandCreate, BrandUpdate,
)
from app.services import product_service

CACHE_TTL = 60

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
    cache_key = f"products:list:{page}:{size}:{search}:{category_id}:{brand_id}:{enabled_only}"
    cached = await cache_get(cache_key)
    if cached:
        return Response(content=cached, media_type="application/json")

    result = await product_service.list_products(db, page, size, search, category_id, brand_id, enabled_only)
    body = ProductListResponse.model_validate(result)
    await cache_set(cache_key, body.model_dump_json(), CACHE_TTL)
    return body


@router.get("/products/{product_id}", response_model=ProductOut)
async def get_product(product_id: str, db: AsyncSession = Depends(get_db)):
    cache_key = f"product:{product_id}"
    cached = await cache_get(cache_key)
    if cached:
        return Response(content=cached, media_type="application/json")

    product = await product_service.get_product(db, product_id)
    body = ProductOut.model_validate(product)
    await cache_set(cache_key, body.model_dump_json(), CACHE_TTL)
    return body


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
    product = await product_service.update_product(db, product_id, body)
    await cache_delete(f"product:{product_id}")
    return product


@router.patch("/products/{product_id}/disable", status_code=204)
async def disable_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await product_service.delete_product(db, product_id)
    await cache_delete(f"product:{product_id}")


@router.delete("/products/{product_id}", status_code=204)
async def hard_delete_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await product_service.hard_delete_product(db, product_id)
    await cache_delete(f"product:{product_id}")


@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    cache_key = "categories:all"
    cached = await cache_get(cache_key)
    if cached:
        return Response(content=cached, media_type="application/json")

    categories = await product_service.list_categories(db)
    body = [CategoryOut.model_validate(c) for c in categories]
    payload = f"[{','.join(c.model_dump_json() for c in body)}]"
    await cache_set(cache_key, payload, CACHE_TTL)
    return body


@router.get("/brands", response_model=list[BrandOut])
async def list_brands(
    category_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    cache_key = f"brands:{category_id}"
    cached = await cache_get(cache_key)
    if cached:
        return Response(content=cached, media_type="application/json")

    brands = await product_service.list_brands(db, category_id)
    body = [BrandOut.model_validate(b) for b in brands]
    payload = f"[{','.join(b.model_dump_json() for b in body)}]"
    await cache_set(cache_key, payload, CACHE_TTL)
    return body


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def create_category(
    body: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    category = await product_service.create_category(db, body)
    await cache_delete("categories:all")
    return category


@router.put("/categories/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    body: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    category = await product_service.update_category(db, category_id, body)
    await cache_delete("categories:all")
    return category


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await product_service.delete_category(db, category_id)
    await cache_delete("categories:all")


@router.post("/brands", response_model=BrandOut, status_code=201)
async def create_brand(
    body: BrandCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await product_service.create_brand(db, body)


@router.put("/brands/{brand_id}", response_model=BrandOut)
async def update_brand(
    brand_id: int,
    body: BrandUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await product_service.update_brand(db, brand_id, body)


@router.delete("/brands/{brand_id}", status_code=204)
async def delete_brand(
    brand_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await product_service.delete_brand(db, brand_id)


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
    product = await product_service.update_product(db, product_id, ProductUpdate(image_url=image_url))
    await cache_delete(f"product:{product_id}")
    return product
