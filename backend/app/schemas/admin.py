from pydantic import BaseModel, field_validator
from decimal import Decimal
from datetime import datetime
from typing import Literal


class DashboardStats(BaseModel):
    total_orders: int
    total_revenue: Decimal
    total_customers: int
    total_products: int
    orders_today: int
    revenue_today: Decimal
    low_stock_count: int


class AdminOrderItem(BaseModel):
    id: str
    product_name: str
    quantity: int
    unit_price: Decimal
    subtotal: Decimal
    model_config = {"from_attributes": True}


class AdminOrderOut(BaseModel):
    id: str
    status: str
    receipt_type: str
    total: Decimal
    shipping_city: str
    created_at: datetime
    paid_at: datetime | None = None
    tracking_id: str | None = None
    customer_email: str
    items_count: int
    model_config = {"from_attributes": True}


class AdminClientOut(BaseModel):
    id: str
    email: str
    role: str
    is_active: bool
    created_at: datetime
    orders_count: int
    total_spent: Decimal


class TopProduct(BaseModel):
    product_id: str
    name: str
    image_url: str | None
    units_sold: int
    revenue: Decimal


class SalesByCategory(BaseModel):
    category: str
    units_sold: int
    revenue: Decimal


class OrderStatusUpdate(BaseModel):
    status: Literal["shipped", "delivered", "cancelled"]


class AnalyticsOut(BaseModel):
    total_revenue: Decimal
    total_orders: int
    average_ticket: Decimal
    top_products: list[TopProduct]
    sales_by_category: list[SalesByCategory]
