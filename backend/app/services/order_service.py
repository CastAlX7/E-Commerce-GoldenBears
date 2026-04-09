import uuid
import hashlib
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status

from app.models.cart import CartItem
from app.models.product import Product, StockLock
from app.models.order import Order, OrderItem, BillingDetail, PaymentToken
from app.schemas.order import CheckoutConfirmRequest


SHIPPING_LIMA = Decimal("15.00")
SHIPPING_PROVINCIAS = Decimal("25.00")
IGV_RATE = Decimal("0.18")


def calculate_shipping(city: str) -> tuple[Decimal, str]:
    city_lower = city.strip().lower()
    if city_lower == "lima":
        return SHIPPING_LIMA, "24-48 horas"
    else:
        return SHIPPING_PROVINCIAS, "5 días hábiles"


def tokenize_card(card_number: str) -> tuple[str, str]:
    clean = card_number.replace(" ", "").replace("-", "")
    token = hashlib.sha256(clean.encode()).hexdigest()
    last4 = clean[-4:] if len(clean) >= 4 else clean
    return token, last4


async def initiate_checkout(db: AsyncSession, user_id: str, shipping_city: str, receipt_type: str) -> dict:
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product))
        .where(CartItem.user_id == user_id)
    )
    cart_items = result.scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=15)
    subtotal = Decimal("0")
    items_summary = []

    for cart_item in cart_items:
        product = cart_item.product
        if not product.is_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product '{product.name}' is no longer available",
            )

        locked_result = await db.execute(
            select(StockLock).where(
                StockLock.product_id == product.id,
                StockLock.expires_at > now,
                StockLock.order_id == None,
            )
        )
        active_locks = locked_result.scalars().all()
        total_locked = sum(lock.quantity for lock in active_locks)
        available = product.stock - total_locked

        if cart_item.quantity > available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for '{product.name}'. Available: {available}",
            )

        lock = StockLock(
            id=str(uuid.uuid4()),
            product_id=product.id,
            quantity=cart_item.quantity,
            locked_at=now,
            expires_at=expires_at,
        )
        db.add(lock)

        item_subtotal = product.price * cart_item.quantity
        subtotal += item_subtotal
        items_summary.append({
            "product_id": product.id,
            "name": product.name,
            "image_url": product.image_url,
            "quantity": cart_item.quantity,
            "unit_price": float(product.price),
            "subtotal": float(item_subtotal),
        })

    shipping_cost, estimated_delivery = calculate_shipping(shipping_city)
    tax_amount = (subtotal * IGV_RATE).quantize(Decimal("0.01"))
    total = subtotal + shipping_cost + tax_amount

    return {
        "subtotal": subtotal,
        "shipping_cost": shipping_cost,
        "tax_amount": tax_amount,
        "total": total,
        "shipping_city": shipping_city,
        "estimated_delivery": estimated_delivery,
        "lock_expires_in_minutes": 15,
        "items": items_summary,
    }


async def confirm_checkout(db: AsyncSession, user_id: str, data: CheckoutConfirmRequest) -> Order:
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product))
        .where(CartItem.user_id == user_id)
    )
    cart_items = result.scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty")

    if data.receipt_type == "factura":
        if not data.billing.ruc or not data.billing.razon_social:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Factura requires RUC and Razón Social",
            )

    subtotal = Decimal("0")
    order_items = []
    now = datetime.now(timezone.utc)

    for cart_item in cart_items:
        product = cart_item.product
        if not product.is_enabled:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Product '{product.name}' unavailable")

        if product.stock < cart_item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for '{product.name}'",
            )

        item_subtotal = product.price * cart_item.quantity
        subtotal += item_subtotal
        order_items.append({
            "product": product,
            "quantity": cart_item.quantity,
            "unit_price": product.price,
            "subtotal": item_subtotal,
        })

    shipping_cost, _ = calculate_shipping(data.shipping_city)
    tax_amount = (subtotal * IGV_RATE).quantize(Decimal("0.01"))
    total = subtotal + shipping_cost + tax_amount

    order_id = str(uuid.uuid4())
    order = Order(
        id=order_id,
        user_id=user_id,
        status="paid",
        receipt_type=data.receipt_type,
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        tax_amount=tax_amount,
        total=total,
        shipping_city=data.shipping_city,
        paid_at=now,
        tracking_id=f"GB-{order_id[:8].upper()}",
    )
    db.add(order)
    await db.flush()

    for oi in order_items:
        product = oi["product"]
        product.stock -= oi["quantity"]
        db.add(OrderItem(
            id=str(uuid.uuid4()),
            order_id=order_id,
            product_id=product.id,
            quantity=oi["quantity"],
            unit_price=oi["unit_price"],
            subtotal=oi["subtotal"],
        ))

    billing = BillingDetail(
        id=str(uuid.uuid4()),
        order_id=order_id,
        dni=data.billing.dni,
        razon_social=data.billing.razon_social,
        ruc=data.billing.ruc,
        direccion_fiscal=data.billing.direccion_fiscal,
        billing_email=data.billing.billing_email,
    )
    db.add(billing)

    payment_kwargs = {
        "id": str(uuid.uuid4()),
        "order_id": order_id,
        "method": data.payment.method,
    }
    if data.payment.method == "card" and data.payment.card_number:
        token, last4 = tokenize_card(data.payment.card_number)
        payment_kwargs.update({"card_token": token, "card_last4": last4, "card_brand": "Visa"})
    elif data.payment.method == "yape_plin":
        payment_kwargs["yape_phone"] = data.payment.yape_phone
    db.add(PaymentToken(**payment_kwargs))

    # Release stock locks for this user
    locks_result = await db.execute(
        select(StockLock).where(StockLock.order_id == None, StockLock.expires_at > now)
    )
    for lock in locks_result.scalars().all():
        await db.delete(lock)

    # Clear cart
    for cart_item in cart_items:
        await db.delete(cart_item)

    await db.flush()
    return await get_order(db, order_id, user_id)


async def get_order(db: AsyncSession, order_id: str, user_id: str) -> Order:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.category),
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.brand),
            selectinload(Order.billing_detail),
        )
        .where(Order.id == order_id, Order.user_id == user_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Order not found")
    return order


async def list_orders(db: AsyncSession, user_id: str) -> list[Order]:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.category),
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.brand),
            selectinload(Order.billing_detail),
        )
        .where(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
    )
    return result.scalars().all()


async def buy_again(db: AsyncSession, user_id: str, order_id: str) -> dict:
    from app.services.cart_service import add_to_cart
    order = await get_order(db, order_id, user_id)
    added = []
    skipped = []
    for item in order.items:
        try:
            await add_to_cart(db, user_id, item.product_id, item.quantity)
            added.append(item.product_id)
        except HTTPException:
            skipped.append(item.product_id)
    return {"added": added, "skipped": skipped}
