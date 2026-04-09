from pydantic import BaseModel
from decimal import Decimal


class CategoryOut(BaseModel):
    id: int
    name: str
    slug: str
    model_config = {"from_attributes": True}


class BrandOut(BaseModel):
    id: int
    name: str
    slug: str
    category_id: int | None = None
    model_config = {"from_attributes": True}


class ProductOut(BaseModel):
    id: str
    name: str
    description: str | None = None
    price: Decimal
    stock: int
    rating_avg: float
    rating_count: int
    image_url: str | None = None
    is_enabled: bool
    category_id: int | None = None
    brand_id: int | None = None
    category: CategoryOut | None = None
    brand: BrandOut | None = None
    model_config = {"from_attributes": True}


class ProductCreate(BaseModel):
    name: str
    description: str | None = None
    price: Decimal
    stock: int
    image_url: str | None = None
    category_id: int | None = None
    brand_id: int | None = None


class ProductUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    price: Decimal | None = None
    stock: int | None = None
    image_url: str | None = None
    category_id: int | None = None
    brand_id: int | None = None
    is_enabled: bool | None = None


class ProductListResponse(BaseModel):
    items: list[ProductOut]
    total: int
    page: int
    size: int
    pages: int
