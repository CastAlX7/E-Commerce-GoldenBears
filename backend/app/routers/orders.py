from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.order import CheckoutInitiateRequest, CheckoutConfirmRequest, CheckoutSummary, OrderOut
from app.services import order_service

router = APIRouter(prefix="/api/orders", tags=["orders"])


@router.post("/checkout/initiate", response_model=CheckoutSummary)
async def initiate_checkout(
    body: CheckoutInitiateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await order_service.initiate_checkout(db, current_user.id, body.shipping_city, body.receipt_type, body.payment_method)


@router.post("/checkout/confirm", response_model=OrderOut, status_code=201)
async def confirm_checkout(
    body: CheckoutConfirmRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await order_service.confirm_checkout(db, current_user.id, body)


@router.get("", response_model=list[OrderOut])
async def list_orders(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await order_service.list_orders(db, current_user.id)


@router.get("/{order_id}", response_model=OrderOut)
async def get_order(
    order_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await order_service.get_order(db, order_id, current_user.id)


@router.post("/{order_id}/buy-again")
async def buy_again(
    order_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await order_service.buy_again(db, current_user.id, order_id)
    return result
