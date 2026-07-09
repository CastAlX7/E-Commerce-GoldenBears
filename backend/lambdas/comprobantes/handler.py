import json
import logging
import os
import smtplib
from datetime import datetime, timezone
from decimal import Decimal
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formataddr
from io import BytesIO

import boto3
import psycopg2
import psycopg2.extras
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import HRFlowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

logger = logging.getLogger()
logger.setLevel(logging.INFO)

PROJECT_NAME = os.environ.get("PROJECT_NAME", "e-comerce-golden-bears")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")
BUCKET_NAME = f"{PROJECT_NAME}-documental-{ENVIRONMENT}"

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_USER = os.environ["DB_USER"]
DB_NAME = os.environ["DB_NAME"]
DB_PASSWORD_SECRET_ARN = os.environ["DB_PASSWORD_SECRET_ARN"]
GMAIL_SECRET_ARN = os.environ["GMAIL_SECRET_ARN"]

GOLD, NAVY, GRAY = colors.HexColor("#FF9900"), colors.HexColor("#1B2A3B"), colors.HexColor("#6b7280")

s3 = boto3.client('s3')
_secrets_client = boto3.client("secretsmanager")


def _get_secret(secret_arn: str) -> dict:
    resp = _secrets_client.get_secret_value(SecretId=secret_arn)
    return json.loads(resp["SecretString"])


def _get_connection():
    password = _get_secret(DB_PASSWORD_SECRET_ARN)["password"]
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT, user=DB_USER, password=password,
        dbname=DB_NAME, sslmode="require", cursor_factory=psycopg2.extras.RealDictCursor,
    )


def _fetch_order(conn, order_id: str) -> dict | None:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT o.id, o.receipt_type, o.subtotal, o.shipping_cost, o.tax_amount,
                   o.payment_fee, o.total, o.shipping_city, o.paid_at, o.tracking_id,
                   u.email AS user_email, p.full_name,
                   b.dni, b.razon_social, b.ruc, b.direccion_fiscal, b.billing_email,
                   pt.method AS payment_method, pt.card_last4, pt.yape_phone
            FROM orders o
            JOIN users u ON u.id = o.user_id
            LEFT JOIN profiles p ON p.user_id = u.id
            LEFT JOIN billing_details b ON b.order_id = o.id
            LEFT JOIN payment_tokens pt ON pt.order_id = o.id
            WHERE o.id = %s
            """,
            (order_id,),
        )
        order = cur.fetchone()
        if not order:
            return None

        cur.execute(
            """
            SELECT oi.quantity, oi.unit_price, oi.subtotal, pr.name
            FROM order_items oi
            JOIN products pr ON pr.id = oi.product_id
            WHERE oi.order_id = %s
            """,
            (order_id,),
        )
        items = cur.fetchall()

    return {"order": dict(order), "items": [dict(i) for i in items]}


def _call_nubefact(order: dict, order_id: str) -> dict:
    logger.info("Simulando llamada a API NubeFact...")
    return {
        "status": "success",
        "invoice_number": f"FFF1-{order_id[:8].upper()}",
        "total": float(order["total"]),
        "ruc": order.get("ruc") or "N/A",
        "razon_social": order.get("razon_social") or "Cliente Genérico",
    }


def _update_billing_status(conn, order_id: str, invoice_number: str) -> None:
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE billing_details SET invoice_status = 'issued', invoice_number = %s, invoiced_at = %s WHERE order_id = %s",
            (invoice_number, datetime.now(timezone.utc), order_id),
        )
    conn.commit()


def _generate_pdf(order: dict, items: list[dict], invoice_number: str) -> bytes:
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=2 * cm, leftMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm)
    story = []

    is_boleta = order["receipt_type"] == "boleta"
    doc_label = "BOLETA DE VENTA ELECTRÓNICA" if is_boleta else "FACTURA ELECTRÓNICA"
    tracking = order["tracking_id"] or order["id"][:8].upper()

    empresa_style = ParagraphStyle("empresa", fontSize=9, leading=13)
    doc_style = ParagraphStyle("doctype", fontSize=10, leading=14, alignment=TA_RIGHT, fontName="Helvetica-Bold")
    header = Table(
        [[
            Paragraph("<b>GOLDEN BEARS S.A.C.</b><br/>RUC: 20123456789<br/>Av. Javier Prado Este 4200, Surco, Lima", empresa_style),
            Paragraph(f"<b>{doc_label}</b><br/>{invoice_number}", doc_style),
        ]],
        colWidths=["58%", "42%"],
    )
    header.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LINEBELOW", (0, 0), (-1, 0), 1.5, GOLD)]))
    story.append(header)
    story.append(Spacer(1, 0.5 * cm))

    buyer_name = (order["razon_social"] if not is_boleta and order.get("razon_social") else None) or order.get("full_name") or order["user_email"]
    paid_str = order["paid_at"].strftime("%d/%m/%Y %H:%M") if order["paid_at"] else "—"

    if is_boleta:
        rows = [["Cliente:", buyer_name], ["DNI:", order.get("dni") or "—"], ["Fecha:", paid_str], ["N° Seguimiento:", tracking]]
    else:
        rows = [["Razón Social:", order.get("razon_social") or "—"], ["RUC:", order.get("ruc") or "—"],
                ["Dirección Fiscal:", order.get("direccion_fiscal") or "—"], ["Fecha:", paid_str], ["N° Seguimiento:", tracking]]

    label_style = ParagraphStyle("label", fontSize=8.5, fontName="Helvetica-Bold", textColor=GRAY)
    value_style = ParagraphStyle("value", fontSize=8.5)
    buyer_table = Table([[Paragraph(r[0], label_style), Paragraph(str(r[1]), value_style)] for r in rows], colWidths=[4 * cm, None])
    story.append(buyer_table)
    story.append(Spacer(1, 0.6 * cm))

    th_style = ParagraphStyle("th", fontSize=8.5, fontName="Helvetica-Bold", textColor=colors.white)
    td_style = ParagraphStyle("td", fontSize=8.5)
    td_right = ParagraphStyle("tdr", fontSize=8.5, alignment=TA_RIGHT)
    item_rows = [[Paragraph(h, th_style) for h in ("#", "Descripción", "Cant.", "P. Unit.", "Subtotal")]]
    for idx, item in enumerate(items, 1):
        item_rows.append([
            Paragraph(str(idx), td_style),
            Paragraph(item["name"], td_style),
            Paragraph(str(item["quantity"]), td_style),
            Paragraph(f"S/ {item['unit_price']:.2f}", td_right),
            Paragraph(f"S/ {item['subtotal']:.2f}", td_right),
        ])
    items_table = Table(item_rows, colWidths=[1 * cm, None, 1.6 * cm, 3 * cm, 3 * cm], repeatRows=1)
    items_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#e5e7eb")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story.append(items_table)
    story.append(Spacer(1, 0.4 * cm))

    tot_label = ParagraphStyle("tl", fontSize=9, alignment=TA_RIGHT, textColor=GRAY)
    tot_value = ParagraphStyle("tv", fontSize=9, alignment=TA_RIGHT)
    tot_bold = ParagraphStyle("tb", fontSize=11, fontName="Helvetica-Bold", alignment=TA_RIGHT, textColor=GOLD)
    totals_rows = [
        [Paragraph("Subtotal:", tot_label), Paragraph(f"S/ {order['subtotal']:.2f}", tot_value)],
        [Paragraph("Envío:", tot_label), Paragraph(f"S/ {order['shipping_cost']:.2f}", tot_value)],
        [Paragraph("IGV (18%):", tot_label), Paragraph(f"S/ {order['tax_amount']:.2f}", tot_value)],
    ]
    if order["payment_fee"] and order["payment_fee"] > 0:
        totals_rows.append([Paragraph("Comisión de pago:", tot_label), Paragraph(f"S/ {order['payment_fee']:.2f}", tot_value)])
    totals_rows.append([Paragraph("TOTAL:", tot_bold), Paragraph(f"S/ {order['total']:.2f}", tot_bold)])
    totals_table = Table(totals_rows, colWidths=[4.5 * cm, 3 * cm], hAlign="RIGHT")
    totals_table.setStyle(TableStyle([("LINEABOVE", (0, -1), (-1, -1), 1, NAVY)]))
    story.append(totals_table)
    story.append(Spacer(1, 0.4 * cm))

    story.append(HRFlowable(width="100%", thickness=1, color=GOLD, spaceAfter=6))
    footer_style = ParagraphStyle("footer", fontSize=7, textColor=GRAY, alignment=TA_CENTER)
    story.append(Paragraph(
        "Gracias por su compra en Golden Bears. Este documento es un comprobante electrónico simulado con fines demostrativos.",
        footer_style,
    ))

    doc.build(story)
    return buffer.getvalue()


def _upload_pdf(order_id: str, pdf_bytes: bytes) -> str:
    key = f"facturas/factura-{order_id}.pdf"
    s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=pdf_bytes, ContentType="application/pdf")
    logger.info(f"Comprobante subido a S3 en: {BUCKET_NAME}/{key}")
    return key


def _send_email(order: dict, pdf_bytes: bytes, invoice_number: str) -> None:
    gmail = _get_secret(GMAIL_SECRET_ARN)
    gmail_user = gmail["gmail_user"]
    gmail_password = gmail["gmail_app_password"]

    recipient = order.get("billing_email") if order["receipt_type"] == "factura" and order.get("billing_email") else order["user_email"]
    receipt_label = "Boleta de Venta" if order["receipt_type"] == "boleta" else "Factura Electrónica"
    tracking = order["tracking_id"] or order["id"][:8].upper()

    msg = MIMEMultipart("mixed")
    msg["Subject"] = f"Tu {receipt_label} — Pedido {tracking} | Golden Bears"
    msg["From"] = formataddr(("Golden Bears", gmail_user))
    msg["To"] = recipient

    html_body = f"""
    <html><body style="font-family:Arial,sans-serif;">
      <h2 style="color:#1B2A3B;">GOLDEN BEARS</h2>
      <p>¡Pago confirmado exitosamente!</p>
      <p>Adjuntamos tu <strong>{receipt_label}</strong> ({invoice_number}) en PDF.</p>
      <p>N° Seguimiento: <strong>{tracking}</strong></p>
      <p>Total: <strong>S/ {order['total']:.2f}</strong></p>
      <p style="color:#6b7280;font-size:12px;">Golden Bears S.A.C. — Este es un mensaje automático, por favor no respondas a este correo.</p>
    </body></html>
    """
    msg.attach(MIMEText(html_body, "html", "utf-8"))

    pdf_part = MIMEApplication(pdf_bytes, _subtype="pdf")
    pdf_part.add_header("Content-Disposition", "attachment", filename=f"GoldenBears_{receipt_label.replace(' ', '_')}_{tracking}.pdf")
    msg.attach(pdf_part)

    with smtplib.SMTP_SSL("smtp.gmail.com", 465, timeout=20) as server:
        server.login(gmail_user, gmail_password)
        server.sendmail(gmail_user, recipient, msg.as_string())

    logger.info(f"Correo de comprobante enviado a {recipient}")


def lambda_handler(event, context):
    """
    Lambda de Comprobantes:
    - Escucha eventos de la cola SQS (billing_queue), publicados por el backend al confirmar un checkout.
    - Consulta la orden completa en Aurora, simula la emisión a NubeFact, genera el PDF,
      lo sube a S3 (auditoria) y manda el correo al cliente (mismo PDF, dos destinos).
    """
    logger.info(f"Evento SQS de Comprobantes recibido: {json.dumps(event)}")

    for record in event.get('Records', []):
        order_id = "unknown"
        try:
            body = json.loads(record['body'])
            order_id = body.get('order_id', 'unknown')
            logger.info(f"Procesando facturacion de la orden: {order_id}")

            conn = _get_connection()
            try:
                data = _fetch_order(conn, order_id)
                if not data:
                    logger.error(f"Orden {order_id} no encontrada en la base de datos")
                    continue

                order, items = data["order"], data["items"]
                nubefact_response = _call_nubefact(order, order_id)
                invoice_number = nubefact_response["invoice_number"]

                pdf_bytes = _generate_pdf(order, items, invoice_number)
                _upload_pdf(order_id, pdf_bytes)
                _send_email(order, pdf_bytes, invoice_number)
                _update_billing_status(conn, order_id, invoice_number)
            finally:
                conn.close()
        except Exception as e:
            logger.error(f"Error procesando registro de comprobantes para la orden {order_id}: {str(e)}")

    return {
        'statusCode': 200,
        'body': json.dumps('Facturación procesada con éxito')
    }
