import uuid
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.models.cart import CartItem
from app.models.product import Product
from app.services.stock_lock_service import get_locked_quantity


async def get_available_stock(db: AsyncSession, product_id: str) -> int:
    product_result = await db.execute(select(Product).where(Product.id == product_id))
    product = product_result.scalar_one_or_none()
    if not product or not product.is_enabled:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    locked_qty = await get_locked_quantity(product_id)
    return product.stock - locked_qty


async def get_cart(db: AsyncSession, user_id: str):
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product).selectinload(Product.category),
                 selectinload(CartItem.product).selectinload(Product.brand))
        .where(CartItem.user_id == user_id)
        .order_by(CartItem.added_at)
    )
    items = result.scalars().all()
    subtotal = sum(item.product.price * item.quantity for item in items)
    return {"items": items, "subtotal": Decimal(subtotal)}


async def add_to_cart(db: AsyncSession, user_id: str, product_id: str, quantity: int) -> CartItem:
    available = await get_available_stock(db, product_id)

    existing_result = await db.execute(
        select(CartItem).where(CartItem.user_id == user_id, CartItem.product_id == product_id)
    )
    existing = existing_result.scalar_one_or_none()

    if existing:
        new_qty = existing.quantity + quantity
        if new_qty > available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Only {available} units available",
            )
        existing.quantity = new_qty
        return existing
    else:
        if quantity > available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Only {available} units available",
            )
        item = CartItem(id=str(uuid.uuid4()), user_id=user_id, product_id=product_id, quantity=quantity)
        db.add(item)
        return item


async def update_cart_item(db: AsyncSession, user_id: str, product_id: str, quantity: int) -> CartItem:
    available = await get_available_stock(db, product_id)
    if quantity > available:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only {available} units available",
        )

    result = await db.execute(
        select(CartItem).where(CartItem.user_id == user_id, CartItem.product_id == product_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")
    item.quantity = quantity
    return item


async def remove_cart_item(db: AsyncSession, user_id: str, product_id: str) -> None:
    result = await db.execute(
        select(CartItem).where(CartItem.user_id == user_id, CartItem.product_id == product_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found")
    await db.delete(item)


async def clear_cart(db: AsyncSession, user_id: str) -> None:
    result = await db.execute(select(CartItem).where(CartItem.user_id == user_id))
    for item in result.scalars().all():
        await db.delete(item)
