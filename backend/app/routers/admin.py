from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_admin
from app.models.user import User
from app.schemas.admin import DashboardStats, AnalyticsOut
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


@router.get("/analytics", response_model=AnalyticsOut)
async def get_analytics(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    return await admin_service.get_analytics(db)
