import math
import re
import uuid
from pathlib import Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.models.product import Product, Category, Brand
from app.models.order import OrderItem
from app.schemas.product import ProductCreate, ProductUpdate, CategoryCreate, CategoryUpdate, BrandCreate, BrandUpdate


def _slugify(name: str) -> str:
    return re.sub(r'[^a-z0-9]+', '-', name.lower().strip()).strip('-')

_IMAGES_DIR = Path(__file__).parent.parent.parent / "static" / "images"

# IDs fijos de los 15 productos del seed — su imagen nunca se borra del disco
_SEED_PRODUCT_IDS = {
    "c9c10297-463b-4f6a-a144-9b523dadd969",  # iPhone 15 Pro
    "44012204-0874-44de-bd3e-c9e30805c51a",  # MacBook Air M2
    "e3e9a207-0954-447e-be3b-a90b21bd2b02",  # AirPods Pro 2
    "2193b55b-49f0-4647-8a71-38fb3e15f27b",  # Sony WH-1000XM5
    "28c1b8aa-97a9-443d-a03e-4de662acb5cd",  # Sony PlayStation 5
    "c81d3a87-3190-45f1-b1c0-fb3c76b97c61",  # Dell XPS 15
    "737d92dd-62fd-4f51-971e-6f46e97b3f45",  # Nike Air Max 270
    "d8555879-94a9-45ce-a94f-1c2f635273a3",  # Nike Pro Dri-FIT
    "7dedb9da-2676-40bb-a035-49e9324dc046",  # Adidas Ultraboost 23
    "44c2fd70-5a5a-4888-a2b1-7b08fb1edeb5",  # Puma RS-X
    "135ee79a-92ae-463b-ac31-ded6685b56ed",  # Samsung Galaxy S24 Ultra
    "9773d65f-3e71-434d-9549-2b045cba4d7f",  # Samsung Neo QLED 4K 55"
    "405d976c-7d8c-4d78-bd3f-d3e2977b32c5",  # LG OLED C3 65"
    "8c1842f0-72d1-41ad-bebe-b5076cd96bc6",  # Bosch Serie 6 Lavadora
    "719ebe33-2191-40ff-86ee-ecce1f857e9e",  # Apple Watch Series 9
}


async def list_products(
    db: AsyncSession,
    page: int = 1,
    size: int = 20,
    search: str | None = None,
    category_id: int | None = None,
    brand_id: int | None = None,
    enabled_only: bool = True,
):
    query = select(Product).options(selectinload(Product.category), selectinload(Product.brand))
    if enabled_only:
        query = query.where(Product.is_enabled == True)
    if search:
        query = query.where(Product.name.ilike(f"%{search}%"))
    if category_id:
        query = query.where(Product.category_id == category_id)
    if brand_id:
        query = query.where(Product.brand_id == brand_id)

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar_one()

    offset = (page - 1) * size
    query = query.offset(offset).limit(size)
    result = await db.execute(query)
    items = result.scalars().all()

    return {
        "items": items,
        "total": total,
        "page": page,
        "size": size,
        "pages": math.ceil(total / size) if total else 1,
    }


async def get_product(db: AsyncSession, product_id: str) -> Product:
    result = await db.execute(
        select(Product)
        .options(selectinload(Product.category), selectinload(Product.brand))
        .where(Product.id == product_id)
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product


async def create_product(db: AsyncSession, data: ProductCreate) -> Product:
    product = Product(id=str(uuid.uuid4()), **data.model_dump())
    db.add(product)
    await db.flush()
    return await get_product(db, product.id)


async def update_product(db: AsyncSession, product_id: str, data: ProductUpdate) -> Product:
    product = await get_product(db, product_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    await db.flush()
    return await get_product(db, product_id)


async def delete_product(db: AsyncSession, product_id: str) -> None:
    product = await get_product(db, product_id)
    product.is_enabled = False


async def hard_delete_product(db: AsyncSession, product_id: str) -> None:
    product = await get_product(db, product_id)

    has_orders = (await db.execute(
        select(func.count()).select_from(OrderItem).where(OrderItem.product_id == product_id)
    )).scalar_one()
    if has_orders:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="No se puede eliminar: el producto tiene pedidos asociados. Puedes deshabilitarlo en su lugar.",
        )

    await db.delete(product)

    if product_id not in _SEED_PRODUCT_IDS:
        for f in _IMAGES_DIR.glob(f"{product_id}.*"):
            f.unlink(missing_ok=True)


async def list_categories(db: AsyncSession) -> list[Category]:
    result = await db.execute(select(Category).order_by(Category.name))
    return result.scalars().all()


async def list_brands(db: AsyncSession, category_id: int | None = None) -> list[Brand]:
    query = select(Brand).order_by(Brand.name)
    if category_id:
        query = query.where(Brand.category_id == category_id)
    result = await db.execute(query)
    return result.scalars().all()


async def create_category(db: AsyncSession, data: CategoryCreate) -> Category:
    slug = _slugify(data.name)
    existing = (await db.execute(select(Category).where(Category.slug == slug))).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya existe una categoría con ese nombre")
    cat = Category(name=data.name, slug=slug)
    db.add(cat)
    await db.flush()
    return cat


async def update_category(db: AsyncSession, category_id: int, data: CategoryUpdate) -> Category:
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoría no encontrada")
    cat.name = data.name
    cat.slug = _slugify(data.name)
    await db.flush()
    return cat


async def delete_category(db: AsyncSession, category_id: int) -> None:
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoría no encontrada")
    prod_count = (await db.execute(
        select(func.count()).select_from(Product).where(Product.category_id == category_id)
    )).scalar_one()
    if prod_count:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"No se puede eliminar: {prod_count} producto(s) usan esta categoría",
        )
    await db.delete(cat)


async def create_brand(db: AsyncSession, data: BrandCreate) -> Brand:
    slug = _slugify(data.name)
    existing = (await db.execute(select(Brand).where(Brand.slug == slug))).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya existe una marca con ese nombre")
    brand = Brand(name=data.name, slug=slug, category_id=data.category_id)
    db.add(brand)
    await db.flush()
    return brand


async def update_brand(db: AsyncSession, brand_id: int, data: BrandUpdate) -> Brand:
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Marca no encontrada")
    if data.name is not None:
        brand.name = data.name
        brand.slug = _slugify(data.name)
    if data.category_id is not None:
        brand.category_id = data.category_id
    await db.flush()
    return brand


async def delete_brand(db: AsyncSession, brand_id: int) -> None:
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Marca no encontrada")
    prod_count = (await db.execute(
        select(func.count()).select_from(Product).where(Product.brand_id == brand_id)
    )).scalar_one()
    if prod_count:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"No se puede eliminar: {prod_count} producto(s) usan esta marca",
        )
    await db.delete(brand)
