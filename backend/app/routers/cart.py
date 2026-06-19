from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.cart import CartOut, AddToCartRequest, UpdateCartItemRequest, CartItemOut
from app.services import cart_service

router = APIRouter(prefix="/api/cart", tags=["cart"])


@router.get("", response_model=CartOut)
async def get_cart(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await cart_service.get_cart(db, current_user.id)


@router.post("/items", status_code=201)
async def add_item(
    body: AddToCartRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    item = await cart_service.add_to_cart(db, current_user.id, body.product_id, body.quantity)
    return {"message": "Item added to cart", "product_id": item.product_id, "quantity": item.quantity}


@router.put("/items/{product_id}")
async def update_item(
    product_id: str,
    body: UpdateCartItemRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    item = await cart_service.update_cart_item(db, current_user.id, product_id, body.quantity)
    return {"message": "Cart updated", "product_id": item.product_id, "quantity": item.quantity}


@router.delete("/items/{product_id}", status_code=204)
async def remove_item(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await cart_service.remove_cart_item(db, current_user.id, product_id)


@router.delete("", status_code=204)
async def clear_cart(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await cart_service.clear_cart(db, current_user.id)
