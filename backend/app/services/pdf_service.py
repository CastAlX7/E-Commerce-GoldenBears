from io import BytesIO
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT

# ── Brand colors ────────────────────────────────────────────────────────────
GOLD  = colors.HexColor("#FF9900")
NAVY  = colors.HexColor("#1B2A3B")
BROWN = colors.HexColor("#9D6D3A")
LIGHT = colors.HexColor("#FAF7F4")
GRAY  = colors.HexColor("#6b7280")
WHITE = colors.white
BLACK = colors.black


def generate_receipt_pdf(order, user) -> bytes:
    """
    Genera un PDF de boleta o factura en memoria (BytesIO).
    Retorna los bytes crudos listos para adjuntar al email.

    Los objetos `order` y `user` deben tener cargadas sus relaciones:
      order.items, order.billing_detail, order.payment_token
      user.profile (puede ser None)
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    normal = styles["Normal"]
    normal.fontSize = 9

    story = []

    # ── Header: empresa + N° comprobante ────────────────────────────────────
    is_boleta = (order.receipt_type == "boleta")
    doc_label = "BOLETA DE VENTA ELECTRÓNICA" if is_boleta else "FACTURA ELECTRÓNICA"
    tracking = order.tracking_id or order.id[:8].upper()
    serial = f"B001-{tracking}" if is_boleta else f"F001-{tracking}"

    empresa_style = ParagraphStyle(
        "empresa", fontSize=9, leading=13, spaceAfter=2
    )
    doc_style = ParagraphStyle(
        "doctype", fontSize=10, leading=14, alignment=TA_RIGHT, fontName="Helvetica-Bold"
    )

    header_data = [[
        Paragraph(
            "<b>GOLDEN BEARS S.A.C.</b><br/>RUC: 20123456789<br/>"
            "Av. Javier Prado Este 4200, Surco, Lima<br/>Tel: (01) 555-0100",
            empresa_style,
        ),
        Paragraph(f"<b>{doc_label}</b><br/>{serial}", doc_style),
    ]]
    header_table = Table(header_data, colWidths=["58%", "42%"])
    header_table.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, 0), 1.5, GOLD),
        ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 0.5 * cm))

    # ── Datos del comprador ──────────────────────────────────────────────────
    billing = order.billing_detail
    buyer_name = (
        (billing.razon_social if not is_boleta and billing else None)
        or (user.profile.full_name if user.profile and user.profile.full_name else None)
        or user.email
    )
    paid_str = (
        order.paid_at.strftime("%d/%m/%Y %H:%M")
        if order.paid_at else "—"
    )

    if is_boleta:
        buyer_rows = [
            ["Cliente:", buyer_name],
            ["DNI:", billing.dni if billing and billing.dni else "—"],
            ["Fecha:", paid_str],
            ["N° Seguimiento:", tracking],
            ["Ciudad de envío:", order.shipping_city],
        ]
    else:
        buyer_rows = [
            ["Razón Social:", billing.razon_social if billing and billing.razon_social else "—"],
            ["RUC:", billing.ruc if billing and billing.ruc else "—"],
            ["Dirección Fiscal:", billing.direccion_fiscal if billing and billing.direccion_fiscal else "—"],
            ["Fecha:", paid_str],
            ["N° Seguimiento:", tracking],
            ["Ciudad de envío:", order.shipping_city],
        ]

    label_style = ParagraphStyle("label", fontSize=8.5, fontName="Helvetica-Bold", textColor=GRAY)
    value_style = ParagraphStyle("value", fontSize=8.5)

    buyer_data = [
        [Paragraph(r[0], label_style), Paragraph(str(r[1]), value_style)]
        for r in buyer_rows
    ]
    buyer_table = Table(buyer_data, colWidths=[4 * cm, None])
    buyer_table.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ROWBACKGROUNDS", (0, 0), (-1, -1), [LIGHT, WHITE]),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(buyer_table)
    story.append(Spacer(1, 0.6 * cm))

    # ── Tabla de productos ───────────────────────────────────────────────────
    th_style = ParagraphStyle("th", fontSize=8.5, fontName="Helvetica-Bold", textColor=WHITE)
    td_style = ParagraphStyle("td", fontSize=8.5)
    td_right = ParagraphStyle("tdr", fontSize=8.5, alignment=TA_RIGHT)

    item_rows = [[
        Paragraph("#", th_style),
        Paragraph("Descripción", th_style),
        Paragraph("Cant.", th_style),
        Paragraph("P. Unit.", th_style),
        Paragraph("Subtotal", th_style),
    ]]
    for idx, item in enumerate(order.items, 1):
        product_name = (
            item.product.name
            if hasattr(item, "product") and item.product
            else f"Producto {str(item.product_id)[:8]}"
        )
        item_rows.append([
            Paragraph(str(idx), td_style),
            Paragraph(product_name, td_style),
            Paragraph(str(item.quantity), td_style),
            Paragraph(f"S/ {item.unit_price:.2f}", td_right),
            Paragraph(f"S/ {item.subtotal:.2f}", td_right),
        ])

    items_table = Table(
        item_rows,
        colWidths=[1 * cm, None, 1.6 * cm, 3 * cm, 3 * cm],
        repeatRows=1,
    )
    items_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [WHITE, LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#e5e7eb")),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(items_table)
    story.append(Spacer(1, 0.4 * cm))

    # ── Totales ──────────────────────────────────────────────────────────────
    tot_label = ParagraphStyle("tl", fontSize=9, alignment=TA_RIGHT, textColor=GRAY)
    tot_value = ParagraphStyle("tv", fontSize=9, alignment=TA_RIGHT)
    tot_bold  = ParagraphStyle("tb", fontSize=11, fontName="Helvetica-Bold", alignment=TA_RIGHT, textColor=GOLD)

    totals_rows = [
        [Paragraph("Subtotal:", tot_label),    Paragraph(f"S/ {order.subtotal:.2f}", tot_value)],
        [Paragraph("Envío:", tot_label),        Paragraph(f"S/ {order.shipping_cost:.2f}", tot_value)],
        [Paragraph("IGV (18%):", tot_label),    Paragraph(f"S/ {order.tax_amount:.2f}", tot_value)],
    ]
    if order.payment_fee and order.payment_fee > 0:
        totals_rows.append([
            Paragraph("Comisión de pago:", tot_label),
            Paragraph(f"S/ {order.payment_fee:.2f}", tot_value),
        ])
    totals_rows.append([
        Paragraph("TOTAL:", tot_bold),
        Paragraph(f"S/ {order.total:.2f}", tot_bold),
    ])

    totals_table = Table(totals_rows, colWidths=[4.5 * cm, 3 * cm], hAlign="RIGHT")
    totals_table.setStyle(TableStyle([
        ("LINEABOVE", (0, -1), (-1, -1), 1, NAVY),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(totals_table)
    story.append(Spacer(1, 0.4 * cm))

    # ── Método de pago ───────────────────────────────────────────────────────
    pt = order.payment_token
    if pt:
        if pt.method == "card":
            pay_text = f"Tarjeta Visa terminada en {pt.card_last4 or '****'}"
        else:
            pay_text = f"Yape/Plin — Teléfono: {pt.yape_phone or '—'}"
        pay_style = ParagraphStyle("pay", fontSize=8.5)
        story.append(Paragraph(f"<b>Método de pago:</b> {pay_text}", pay_style))
        story.append(Spacer(1, 0.3 * cm))

    # ── Footer ───────────────────────────────────────────────────────────────
    story.append(HRFlowable(width="100%", thickness=1, color=GOLD, spaceAfter=6))
    footer_style = ParagraphStyle("footer", fontSize=7, textColor=GRAY, alignment=TA_CENTER)
    story.append(Paragraph(
        "Gracias por su compra en Golden Bears. "
        "Este documento es un comprobante electrónico simulado con fines demostrativos.",
        footer_style,
    ))

    doc.build(story)
    return buffer.getvalue()
