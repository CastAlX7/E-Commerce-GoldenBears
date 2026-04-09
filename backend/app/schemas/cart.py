from pydantic import BaseModel
from decimal import Decimal
from app.schemas.product import ProductOut


class CartItemOut(BaseModel):
    id: str
    product_id: str
    quantity: int
    product: ProductOut
    model_config = {"from_attributes": True}


class CartOut(BaseModel):
    items: list[CartItemOut]
    subtotal: Decimal


class AddToCartRequest(BaseModel):
    product_id: str
    quantity: int = 1


class UpdateCartItemRequest(BaseModel):
    quantity: int
