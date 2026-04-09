import math
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.models.product import Product, Category, Brand
from app.schemas.product import ProductCreate, ProductUpdate


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


async def list_categories(db: AsyncSession) -> list[Category]:
    result = await db.execute(select(Category).order_by(Category.name))
    return result.scalars().all()


async def list_brands(db: AsyncSession, category_id: int | None = None) -> list[Brand]:
    query = select(Brand).order_by(Brand.name)
    if category_id:
        query = query.where(Brand.category_id == category_id)
    result = await db.execute(query)
    return result.scalars().all()
