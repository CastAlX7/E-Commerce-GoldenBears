import os
import uuid
import hashlib
from datetime import datetime, timezone
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
import httpx

from app.models.cart import CartItem
from app.models.product import Product
from app.models.order import Order, OrderItem, BillingDetail, PaymentToken
from app.models.user import User
from app.schemas.order import CheckoutConfirmRequest
from app.services.stock_lock_service import create_stock_lock, get_locked_quantity, release_user_locks

CULQI_SECRET_KEY = os.getenv("CULQI_SECRET_KEY", "sk_test_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")


async def charge_culqi(token: str, amount_cents: int, email: str) -> dict:
    if CULQI_SECRET_KEY.startswith("sk_test_XXX"):
        return {"id": "mock_charge_id", "outcome": {"type": "authorized"}}
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "https://api.culqi.com/v2/charges",
            headers={"Authorization": f"Bearer {CULQI_SECRET_KEY}"},
            json={"amount": amount_cents, "currency_code": "PEN",
                  "email": email, "source_id": token},
        )
        return resp.json()


SHIPPING_LIMA = Decimal("15.00")
SHIPPING_PROVINCIAS = Decimal("25.00")
IGV_RATE = Decimal("0.18")
PAYMENT_FEE_CARD = Decimal("0.035")
PAYMENT_FEE_YAPE = Decimal("0.00")


def calculate_payment_fee(method: str, subtotal: Decimal) -> Decimal:
    rate = PAYMENT_FEE_CARD if method == "card" else PAYMENT_FEE_YAPE
    return (subtotal * rate).quantize(Decimal("0.01"))


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


async def initiate_checkout(db: AsyncSession, user_id: str, shipping_city: str, receipt_type: str, payment_method: str = "card") -> dict:
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product))
        .where(CartItem.user_id == user_id)
    )
    cart_items = result.scalars().all()
    if not cart_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cart is empty")

    subtotal = Decimal("0")
    items_summary = []

    for cart_item in cart_items:
        product = cart_item.product
        if not product.is_enabled:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Product '{product.name}' is no longer available",
            )

        total_locked = await get_locked_quantity(product.id)
        available = product.stock - total_locked

        if cart_item.quantity > available:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for '{product.name}'. Available: {available}",
            )

        await create_stock_lock(product.id, user_id, cart_item.quantity)

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
    payment_fee = calculate_payment_fee(payment_method, subtotal)
    total = subtotal + shipping_cost + tax_amount + payment_fee

    return {
        "subtotal": subtotal,
        "shipping_cost": shipping_cost,
        "tax_amount": tax_amount,
        "payment_fee": payment_fee,
        "total": total,
        "shipping_city": shipping_city,
        "estimated_delivery": estimated_delivery,
        "lock_expires_in_minutes": 15,
        "items": items_summary,
    }


async def confirm_checkout(db: AsyncSession, user: User, data: CheckoutConfirmRequest) -> dict:
    result = await db.execute(
        select(CartItem)
        .options(selectinload(CartItem.product))
        .where(CartItem.user_id == user.id)
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
    payment_fee = calculate_payment_fee(data.payment.method, subtotal)
    total = subtotal + shipping_cost + tax_amount + payment_fee

    if data.payment.method == "card" and data.payment.card_number:
        culqi_token, _ = tokenize_card(data.payment.card_number)
        amount_cents = int(total * 100)
        charge = await charge_culqi(culqi_token, amount_cents, user.email)
        if charge.get("outcome", {}).get("type") != "authorized":
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail=charge.get("user_message", "Pago rechazado por la pasarela"),
            )

    order_id = str(uuid.uuid4())
    order = Order(
        id=order_id,
        user_id=user.id,
        status="paid",
        receipt_type=data.receipt_type,
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        tax_amount=tax_amount,
        payment_fee=payment_fee,
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
    for oi in order_items:
        await release_user_locks(oi["product"].id, user.id)

    # Clear cart
    for cart_item in cart_items:
        await db.delete(cart_item)

    await db.flush()

    completed_order = await get_order(db, order_id, user.id)

    # Generar PDF y lanzar envío de correo en background (no bloquea la respuesta)
    import asyncio
    import logging
    email_address = None
    email_scheduled = False
    try:
        from app.services.pdf_service import generate_receipt_pdf
        from app.services.email_service import send_receipt_email, _determine_recipient_email
        pdf_bytes = generate_receipt_pdf(completed_order, user)
        email_address = _determine_recipient_email(completed_order, user)

        async def _send():
            try:
                await send_receipt_email(completed_order, user, pdf_bytes)
            except Exception as e:
                logging.getLogger(__name__).error(
                    "Error enviando correo en background para orden %s: %s", order_id, e
                )

        asyncio.create_task(_send())
        email_scheduled = True
    except Exception as exc:
        logging.getLogger(__name__).error(
            "Error generando PDF para la orden %s: %s", order_id, exc
        )

    return {"order": completed_order, "email_sent": email_scheduled, "email_address": email_address}


async def get_order(db: AsyncSession, order_id: str, user_id: str) -> Order:
    result = await db.execute(
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.category),
            selectinload(Order.items).selectinload(OrderItem.product).selectinload(Product.brand),
            selectinload(Order.billing_detail),
            selectinload(Order.payment_token),
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