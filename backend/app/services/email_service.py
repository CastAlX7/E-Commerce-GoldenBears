import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.utils import formataddr

import aiosmtplib
from jinja2 import Template

from app.config import settings

logger = logging.getLogger(__name__)


# ── HTML email template (Jinja2, inline) ────────────────────────────────────
_EMAIL_TEMPLATE = """<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Comprobante de Compra — Golden Bears</title>
  <style>
    body { margin:0; padding:0; background:#FAF7F4; font-family:Arial,Helvetica,sans-serif; }
    .wrapper { max-width:620px; margin:0 auto; background:#fff; border-radius:10px; overflow:hidden; }
    .header { background:#1B2A3B; padding:28px 32px; text-align:center; }
    .header h1 { color:#FF9900; font-size:22px; margin:0; letter-spacing:2px; }
    .header p  { color:#9ca3af; font-size:12px; margin:6px 0 0; }
    .success-banner { background:#FF9900; color:#fff; text-align:center;
                      padding:13px 32px; font-size:15px; font-weight:bold; }
    .body { padding:28px 32px; }
    .greeting { font-size:15px; color:#1a1a2e; margin-bottom:6px; }
    .subtext  { font-size:13px; color:#6b7280; margin-bottom:20px; }
    .meta { background:#FAF7F4; border-radius:8px; padding:14px 18px; margin-bottom:20px; }
    .meta table { width:100%; border-collapse:collapse; font-size:13px; }
    .meta td { padding:4px 0; color:#374151; }
    .meta td:first-child { font-weight:bold; color:#6b7280; width:150px; }
    .section-title { font-size:12px; font-weight:bold; text-transform:uppercase;
                     letter-spacing:.06em; color:#9D6D3A; margin:22px 0 10px;
                     border-bottom:2px solid #FF9900; padding-bottom:5px; }
    .items-table { width:100%; border-collapse:collapse; font-size:13px; }
    .items-table th { background:#1B2A3B; color:#fff; padding:9px 10px; text-align:left; }
    .items-table th.right, .items-table td.right { text-align:right; }
    .items-table td { padding:8px 10px; border-bottom:1px solid #e5e7eb; }
    .items-table tr:nth-child(even) td { background:#FAF7F4; }
    .totals { width:100%; border-collapse:collapse; font-size:13px; margin-top:12px; }
    .totals td { padding:5px 10px; }
    .totals td.right { text-align:right; }
    .totals .total-row td { font-weight:bold; font-size:16px; color:#FF9900;
                            border-top:2px solid #1B2A3B; padding-top:9px; }
    .billing-table { width:100%; border-collapse:collapse; font-size:13px; }
    .billing-table td { padding:5px 0; vertical-align:top; }
    .billing-table td:first-child { font-weight:bold; color:#6b7280; width:150px; }
    .pay-box { background:#FAF7F4; border-left:4px solid #FF9900;
               padding:10px 14px; font-size:13px; margin-top:18px;
               border-radius:0 6px 6px 0; }
    .pdf-notice { background:#fff7ed; border:1px solid #fed7aa; border-radius:8px;
                  padding:12px 16px; font-size:13px; color:#92400e; margin-top:20px; }
    .footer { background:#1B2A3B; padding:18px 32px; text-align:center;
              color:#9ca3af; font-size:11px; line-height:1.7; }
  </style>
</head>
<body>
<div class="wrapper">

  <div class="header">
    <h1>GOLDEN BEARS</h1>
    <p>Comprobante de compra electrónico</p>
  </div>

  <div class="success-banner">&#10003; ¡Pago confirmado exitosamente!</div>

  <div class="body">
    <p class="greeting">Hola, <strong>{{ buyer_name }}</strong></p>
    <p class="subtext">
      Gracias por tu compra. Adjuntamos tu <strong>{{ receipt_label }}</strong> en PDF.
      A continuación el resumen de tu pedido:
    </p>

    <!-- Resumen del pedido -->
    <div class="meta">
      <table>
        <tr><td>N° Seguimiento</td><td><strong>{{ tracking_id }}</strong></td></tr>
        <tr><td>Fecha de compra</td><td>{{ paid_at }}</td></tr>
        <tr><td>Ciudad de envío</td><td>{{ shipping_city }}</td></tr>
        <tr><td>Tipo de comprobante</td><td>{{ receipt_label }}</td></tr>
      </table>
    </div>

    <!-- Productos -->
    <div class="section-title">Productos</div>
    <table class="items-table">
      <thead>
        <tr>
          <th>Producto</th>
          <th style="text-align:center">Cant.</th>
          <th class="right">P. Unit.</th>
          <th class="right">Subtotal</th>
        </tr>
      </thead>
      <tbody>
        {% for item in items %}
        <tr>
          <td>{{ item.name }}</td>
          <td style="text-align:center">{{ item.quantity }}</td>
          <td class="right">S/ {{ item.unit_price }}</td>
          <td class="right">S/ {{ item.subtotal }}</td>
        </tr>
        {% endfor %}
      </tbody>
    </table>

    <!-- Totales -->
    <table class="totals">
      <tr><td>Subtotal</td><td class="right">S/ {{ subtotal }}</td></tr>
      <tr><td>Envío</td><td class="right">S/ {{ shipping_cost }}</td></tr>
      <tr><td>IGV (18%)</td><td class="right">S/ {{ tax_amount }}</td></tr>
      {% if payment_fee %}
      <tr><td style="color:#6b7280">Comisión de pago</td><td class="right">S/ {{ payment_fee }}</td></tr>
      {% endif %}
      <tr class="total-row"><td>TOTAL</td><td class="right">S/ {{ total }}</td></tr>
    </table>

    <!-- Método de pago -->
    <div class="pay-box">
      <strong>Método de pago:</strong> {{ payment_display }}
    </div>

    <!-- Datos de facturación -->
    <div class="section-title">Datos de facturación</div>
    <table class="billing-table">
      {% if receipt_type == 'boleta' %}
        <tr><td>Cliente</td><td>{{ buyer_name }}</td></tr>
        {% if dni %}<tr><td>DNI</td><td>{{ dni }}</td></tr>{% endif %}
      {% else %}
        <tr><td>Razón Social</td><td>{{ razon_social }}</td></tr>
        <tr><td>RUC</td><td>{{ ruc }}</td></tr>
        {% if direccion_fiscal %}<tr><td>Dirección Fiscal</td><td>{{ direccion_fiscal }}</td></tr>{% endif %}
      {% endif %}
    </table>

    <!-- Aviso PDF -->
    <div class="pdf-notice">
      Tu <strong>{{ receipt_label }}</strong> en PDF está adjunta a este correo.
      Puedes descargarla para tus registros.
    </div>
  </div>

  <div class="footer">
    Golden Bears S.A.C. &mdash; Av. Javier Prado Este 4200, Lima, Perú<br/>
    Este es un mensaje automático, por favor no respondas a este correo.<br/>
    &copy; 2025 Golden Bears. Todos los derechos reservados.
  </div>

</div>
</body>
</html>"""


def _determine_recipient_email(order, user) -> str:
    """
    Elige el destinatario del correo:
    - Para facturas: billing_email si existe, sino user.email
    - Para boletas: siempre user.email
    """
    if (
        order.receipt_type == "factura"
        and order.billing_detail
        and order.billing_detail.billing_email
    ):
        return order.billing_detail.billing_email
    return user.email


def _build_context(order, user) -> dict:
    """Extrae las variables para el template Jinja2."""
    billing = order.billing_detail
    pt = order.payment_token

    buyer_name = (
        (billing.razon_social if order.receipt_type == "factura" and billing else None)
        or (user.profile.full_name if user.profile and user.profile.full_name else None)
        or user.email
    )

    if pt:
        if pt.method == "card":
            payment_display = f"Tarjeta Visa terminada en {pt.card_last4 or '****'}"
        else:
            payment_display = f"Yape/Plin — {pt.yape_phone or '—'}"
    else:
        payment_display = "—"

    items = []
    for item in order.items:
        name = (
            item.product.name
            if hasattr(item, "product") and item.product
            else f"Producto {str(item.product_id)[:8]}"
        )
        items.append({
            "name": name,
            "quantity": item.quantity,
            "unit_price": f"{item.unit_price:.2f}",
            "subtotal": f"{item.subtotal:.2f}",
        })

    paid_str = (
        order.paid_at.strftime("%d/%m/%Y a las %H:%M")
        if order.paid_at else "—"
    )

    payment_fee = (
        f"{order.payment_fee:.2f}"
        if order.payment_fee and order.payment_fee > 0
        else None
    )

    return {
        "buyer_name": buyer_name,
        "receipt_type": order.receipt_type,
        "receipt_label": "Boleta de Venta" if order.receipt_type == "boleta" else "Factura Electrónica",
        "tracking_id": order.tracking_id or order.id[:8].upper(),
        "paid_at": paid_str,
        "shipping_city": order.shipping_city,
        "items": items,
        "subtotal": f"{order.subtotal:.2f}",
        "shipping_cost": f"{order.shipping_cost:.2f}",
        "tax_amount": f"{order.tax_amount:.2f}",
        "payment_fee": payment_fee,
        "total": f"{order.total:.2f}",
        "payment_display": payment_display,
        "dni": billing.dni if billing else None,
        "razon_social": billing.razon_social if billing else None,
        "ruc": billing.ruc if billing else None,
        "direccion_fiscal": billing.direccion_fiscal if billing else None,
    }


async def send_receipt_email(order, user, pdf_bytes: bytes) -> bool:
    """
    Envía el correo de comprobante con el PDF adjunto vía Gmail SMTP.

    Retorna True si se envió correctamente, False en cualquier error.
    Nunca lanza excepciones — los fallos de correo no deben cancelar una orden confirmada.
    """
    if not settings.EMAIL_ENABLED:
        logger.info("EMAIL_ENABLED=False — omitiendo correo para la orden %s", order.id)
        return False

    if not settings.GMAIL_APP_PASSWORD:
        logger.warning("GMAIL_APP_PASSWORD no configurada — no se puede enviar correo para la orden %s", order.id)
        return False

    recipient = _determine_recipient_email(order, user)
    ctx = _build_context(order, user)
    tracking = ctx["tracking_id"]
    receipt_label = ctx["receipt_label"]
    pdf_filename = f"GoldenBears_{receipt_label.replace(' ', '_')}_{tracking}.pdf"

    # Construir mensaje MIME
    msg = MIMEMultipart("mixed")
    msg["Subject"] = f"Tu {receipt_label} — Pedido {tracking} | Golden Bears"
    msg["From"] = formataddr((settings.GMAIL_FROM_NAME, settings.GMAIL_USER))
    msg["To"] = recipient

    # Cuerpo HTML
    html_body = Template(_EMAIL_TEMPLATE).render(**ctx)
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    # Adjunto PDF
    pdf_part = MIMEApplication(pdf_bytes, _subtype="pdf")
    pdf_part.add_header("Content-Disposition", "attachment", filename=pdf_filename)
    msg.attach(pdf_part)

    try:
        await aiosmtplib.send(
            msg,
            hostname="smtp.gmail.com",
            port=465,
            use_tls=True,
            username=settings.GMAIL_USER,
            password=settings.GMAIL_APP_PASSWORD,
            timeout=20,
        )
        logger.info("Correo de comprobante enviado a %s para la orden %s", recipient, order.id)
        return True
    except Exception as exc:
        logger.error("Error al enviar correo para la orden %s: %s", order.id, exc)
        return False
