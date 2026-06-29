import json
import logging
import os
import boto3
import urllib.request
import urllib.error

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_nubefact_credentials() -> dict:
    """Lee token y URL de Nubefact desde Secrets Manager."""
    sm = boto3.client("secretsmanager")
    secret = sm.get_secret_value(SecretId=os.environ["NUBEFACT_SECRET_ARN"])
    return json.loads(secret["SecretString"])


def emit_comprobante(order: dict, credentials: dict) -> dict:
    """
    Emite boleta o factura electrónica vía Nubefact.
    En dev el token es PLACEHOLDER_SUNAT_NUBEFACT_TOKEN — retorna respuesta simulada.
    """
    token = credentials.get("nubefact_token", "")
    base_url = credentials.get("nubefact_url", "https://api.nubefact.com/v1/each")

    if token.startswith("PLACEHOLDER"):
        logger.warning("Modo mock Nubefact activo (token placeholder)")
        return {
            "enlace_del_pdf": f"https://mock.nubefact.com/{order['order_id']}.pdf",
            "enlace_del_xml": f"https://mock.nubefact.com/{order['order_id']}.xml",
            "mock": True,
        }

    receipt_type = order.get("receipt_type", "boleta")
    billing = order.get("billing", {})

    payload = {
        "operacion": "generar_comprobante",
        "tipo_de_comprobante": 2 if receipt_type == "factura" else 1,
        "serie": "B001" if receipt_type == "boleta" else "F001",
        "numero": order.get("correlativo", 1),
        "sunat_transaction": 1,
        "cliente_tipo_de_documento": 6 if receipt_type == "factura" else 1,
        "cliente_numero_de_documento": billing.get("ruc") or billing.get("dni", "00000000"),
        "cliente_denominacion": billing.get("razon_social") or billing.get("nombre", "Cliente"),
        "cliente_email": billing.get("billing_email", ""),
        "fecha_de_emision": order["fecha"],
        "moneda": 1,
        "items": [
            {
                "unidad_de_medida": "NIU",
                "codigo": item["product_id"],
                "descripcion": item["name"],
                "cantidad": item["quantity"],
                "valor_unitario": item["unit_price"],
                "precio_unitario": round(item["unit_price"] * 1.18, 2),
                "subtotal": item["subtotal"],
                "tipo_de_igv": 1,
                "igv": round(item["subtotal"] * 0.18, 2),
                "total": round(item["subtotal"] * 1.18, 2),
            }
            for item in order["items"]
        ],
    }

    req = urllib.request.Request(
        base_url,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Token {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())


def save_to_s3(order_id: str, result: dict):
    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=os.environ["DOCUMENTAL_BUCKET"],
        Key=f"facturas/{order_id}.json",
        Body=json.dumps(result).encode(),
        ContentType="application/json",
    )
    logger.info("Comprobante guardado en S3 para orden %s", order_id)


def lambda_handler(event, context):
    credentials = get_nubefact_credentials()

    for record in event.get("Records", []):
        try:
            order = json.loads(record["body"])
            result = emit_comprobante(order, credentials)
            save_to_s3(order["order_id"], result)
            logger.info("Comprobante emitido para orden %s", order["order_id"])
        except Exception as exc:
            logger.error("Error procesando comprobante: %s", exc)
            raise  # SQS reintenta el mensaje

    return {"statusCode": 200}