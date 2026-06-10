from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_admin
from app.models.user import User
from app.schemas.admin import DashboardStats, AnalyticsOut, OrderStatusUpdate
from app.services import admin_service

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.get("/dashboard", response_model=DashboardStats)
async def get_dashboard(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await admin_service.get_dashboard(db)


@router.get("/orders")
async def list_all_orders(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await admin_service.list_all_orders(db, page, size)


@router.get("/clients")
async def list_all_clients(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await admin_service.list_all_clients(db, page, size)


@router.patch("/clients/{user_id}/toggle", status_code=204)
async def toggle_client_active(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await admin_service.toggle_client_active(db, user_id)


@router.delete("/clients/{user_id}", status_code=204)
async def delete_client(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await admin_service.delete_client(db, user_id)


@router.patch("/orders/{order_id}/status", status_code=204)
async def update_order_status(
    order_id: str,
    body: OrderStatusUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    await admin_service.update_order_status(db, order_id, body.status)


@router.get("/analytics", response_model=AnalyticsOut)
async def get_analytics(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await admin_service.get_analytics(db)
