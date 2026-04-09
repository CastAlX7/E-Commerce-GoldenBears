from datetime import datetime, timezone, timedelta
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.models.order import Order, OrderItem
from app.models.product import Product, Category
from app.models.user import User
from app.schemas.admin import DashboardStats, AdminOrderOut, AdminClientOut, AnalyticsOut, TopProduct, SalesByCategory


async def get_dashboard(db: AsyncSession) -> DashboardStats:
    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    total_orders = (await db.execute(select(func.count()).select_from(Order))).scalar() or 0
    total_revenue = (await db.execute(select(func.coalesce(func.sum(Order.total), 0)).where(Order.status == "paid"))).scalar() or Decimal("0")
    total_customers = (await db.execute(select(func.count()).select_from(User).where(User.role == "customer"))).scalar() or 0
    total_products = (await db.execute(select(func.count()).select_from(Product).where(Product.is_enabled == True))).scalar() or 0
    orders_today = (await db.execute(select(func.count()).select_from(Order).where(Order.created_at >= today_start))).scalar() or 0
    revenue_today = (await db.execute(select(func.coalesce(func.sum(Order.total), 0)).where(and_(Order.status == "paid", Order.created_at >= today_start)))).scalar() or Decimal("0")
    low_stock_count = (await db.execute(select(func.count()).select_from(Product).where(and_(Product.is_enabled == True, Product.stock <= 10)))).scalar() or 0

    return DashboardStats(
        total_orders=total_orders,
        total_revenue=Decimal(str(total_revenue)),
        total_customers=total_customers,
        total_products=total_products,
        orders_today=orders_today,
        revenue_today=Decimal(str(revenue_today)),
        low_stock_count=low_stock_count,
    )


async def list_all_orders(db: AsyncSession, page: int = 1, size: int = 20) -> dict:
    offset = (page - 1) * size
    total = (await db.execute(select(func.count()).select_from(Order))).scalar() or 0

    result = await db.execute(
        select(Order, User.email)
        .join(User, Order.user_id == User.id)
        .order_by(Order.created_at.desc())
        .offset(offset)
        .limit(size)
    )
    rows = result.all()

    orders = []
    for order, email in rows:
        items_count = (await db.execute(
            select(func.count()).select_from(OrderItem).where(OrderItem.order_id == order.id)
        )).scalar() or 0
        orders.append(AdminOrderOut(
            id=order.id,
            status=order.status,
            receipt_type=order.receipt_type,
            total=order.total,
            shipping_city=order.shipping_city,
            created_at=order.created_at,
            paid_at=order.paid_at,
            tracking_id=order.tracking_id,
            customer_email=email,
            items_count=items_count,
        ))

    return {"items": orders, "total": total, "page": page, "pages": max(1, -(-total // size))}


async def list_all_clients(db: AsyncSession, page: int = 1, size: int = 20) -> dict:
    offset = (page - 1) * size
    total = (await db.execute(select(func.count()).select_from(User).where(User.role == "customer"))).scalar() or 0

    result = await db.execute(
        select(User).where(User.role == "customer").order_by(User.created_at.desc()).offset(offset).limit(size)
    )
    users = result.scalars().all()

    clients = []
    for user in users:
        orders_count = (await db.execute(
            select(func.count()).select_from(Order).where(Order.user_id == user.id)
        )).scalar() or 0
        total_spent = (await db.execute(
            select(func.coalesce(func.sum(Order.total), 0)).where(and_(Order.user_id == user.id, Order.status == "paid"))
        )).scalar() or Decimal("0")
        clients.append(AdminClientOut(
            id=user.id,
            email=user.email,
            role=user.role,
            is_active=user.is_active,
            created_at=user.created_at,
            orders_count=orders_count,
            total_spent=Decimal(str(total_spent)),
        ))

    return {"items": clients, "total": total, "page": page, "pages": max(1, -(-total // size))}


async def get_analytics(db: AsyncSession) -> AnalyticsOut:
    total_revenue = (await db.execute(
        select(func.coalesce(func.sum(Order.total), 0)).where(Order.status == "paid")
    )).scalar() or Decimal("0")

    total_orders = (await db.execute(
        select(func.count()).select_from(Order).where(Order.status == "paid")
    )).scalar() or 0

    average_ticket = Decimal(str(total_revenue)) / total_orders if total_orders > 0 else Decimal("0")

    top_result = await db.execute(
        select(
            OrderItem.product_id,
            Product.name,
            Product.image_url,
            func.sum(OrderItem.quantity).label("units_sold"),
            func.sum(OrderItem.subtotal).label("revenue"),
        )
        .join(Product, OrderItem.product_id == Product.id)
        .join(Order, OrderItem.order_id == Order.id)
        .where(Order.status == "paid")
        .group_by(OrderItem.product_id, Product.name, Product.image_url)
        .order_by(func.sum(OrderItem.quantity).desc())
        .limit(5)
    )
    top_products = [
        TopProduct(
            product_id=row.product_id,
            name=row.name,
            image_url=row.image_url,
            units_sold=row.units_sold,
            revenue=Decimal(str(row.revenue)),
        )
        for row in top_result.all()
    ]

    cat_result = await db.execute(
        select(
            Category.name,
            func.sum(OrderItem.quantity).label("units_sold"),
            func.sum(OrderItem.subtotal).label("revenue"),
        )
        .join(Product, OrderItem.product_id == Product.id)
        .join(Category, Product.category_id == Category.id)
        .join(Order, OrderItem.order_id == Order.id)
        .where(Order.status == "paid")
        .group_by(Category.name)
        .order_by(func.sum(OrderItem.subtotal).desc())
    )
    sales_by_category = [
        SalesByCategory(
            category=row.name,
            units_sold=row.units_sold,
            revenue=Decimal(str(row.revenue)),
        )
        for row in cat_result.all()
    ]

    return AnalyticsOut(
        total_revenue=Decimal(str(total_revenue)),
        total_orders=total_orders,
        average_ticket=average_ticket.quantize(Decimal("0.01")),
        top_products=top_products,
        sales_by_category=sales_by_category,
    )
