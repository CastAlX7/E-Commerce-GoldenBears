from pydantic import BaseModel, field_validator
from decimal import Decimal
from datetime import datetime
from app.schemas.product import ProductOut


class BillingDetailIn(BaseModel):
    dni: str | None = None
    razon_social: str | None = None
    ruc: str | None = None
    direccion_fiscal: str | None = None
    billing_email: str | None = None

    @field_validator("ruc")
    @classmethod
    def ruc_must_be_11_digits(cls, v):
        if v is not None and (not v.isdigit() or len(v) != 11):
            raise ValueError("RUC must be exactly 11 digits")
        return v


class PaymentIn(BaseModel):
    method: str  # "card" or "yape_plin"
    card_number: str | None = None
    card_expiry: str | None = None
    card_cvv: str | None = None
    yape_phone: str | None = None


class CheckoutInitiateRequest(BaseModel):
    shipping_city: str
    receipt_type: str  # "boleta" or "factura"
    payment_method: str = "card"  # "card" or "yape_plin"


class CheckoutConfirmRequest(BaseModel):
    shipping_city: str
    receipt_type: str
    billing: BillingDetailIn
    payment: PaymentIn


class OrderItemOut(BaseModel):
    id: str
    product_id: str
    quantity: int
    unit_price: Decimal
    subtotal: Decimal
    product: ProductOut
    model_config = {"from_attributes": True}


class BillingDetailOut(BaseModel):
    id: str
    dni: str | None = None
    razon_social: str | None = None
    ruc: str | None = None
    direccion_fiscal: str | None = None
    billing_email: str | None = None
    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: str
    status: str
    receipt_type: str
    subtotal: Decimal
    shipping_cost: Decimal
    tax_amount: Decimal
    payment_fee: Decimal
    total: Decimal
    shipping_city: str
    created_at: datetime
    paid_at: datetime | None = None
    tracking_id: str | None = None
    items: list[OrderItemOut] = []
    billing_detail: BillingDetailOut | None = None
    model_config = {"from_attributes": True}


class CheckoutConfirmResponse(OrderOut):
    email_sent: bool = False
    email_address: str | None = None


class CheckoutSummary(BaseModel):
    subtotal: Decimal
    shipping_cost: Decimal
    tax_amount: Decimal
    payment_fee: Decimal
    total: Decimal
    shipping_city: str
    estimated_delivery: str
    lock_expires_in_minutes: int = 15
    items: list[dict]
