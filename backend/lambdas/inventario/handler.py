import json
import logging
import os

import boto3
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_USER = os.environ["DB_USER"]
DB_NAME = os.environ["DB_NAME"]
DB_PASSWORD_SECRET_ARN = os.environ["DB_PASSWORD_SECRET_ARN"]

_secrets_client = boto3.client("secretsmanager")


def _get_connection():
    secret = _secrets_client.get_secret_value(SecretId=DB_PASSWORD_SECRET_ARN)
    password = json.loads(secret["SecretString"])["password"]
    return psycopg2.connect(
        host=DB_HOST, port=DB_PORT, user=DB_USER, password=password,
        dbname=DB_NAME, sslmode="require",
    )


def lambda_handler(event, context):
    """
    Lambda de Inventario:
    - Escucha eventos de la cola SQS (inventory_queue), publicados por el backend
      cuando un checkout ya pasó por Culqi y quedó confirmado.
    - Descuenta el stock en Aurora en segundo plano, fuera del request de checkout.
    """
    logger.info(f"Evento SQS de Inventario recibido: {json.dumps(event)}")

    conn = _get_connection()
    try:
        with conn.cursor() as cur:
            for record in event.get('Records', []):
                try:
                    body = json.loads(record['body'])
                    order_id = body.get('order_id', 'N/A')
                    items = body.get('items', [])

                    logger.info(f"Procesando deduccion de inventario para la orden ID: {order_id}")
                    for item in items:
                        product_id = item.get('product_id')
                        quantity = item.get('quantity')
                        cur.execute(
                            "UPDATE products SET stock = stock - %s WHERE id = %s",
                            (quantity, product_id),
                        )
                        logger.info(f"Deducidas {quantity} unidades del producto ID: {product_id}")
                except Exception as e:
                    logger.error(f"Error procesando registro de inventario: {str(e)}")
        conn.commit()
    finally:
        conn.close()

    return {
        'statusCode': 200,
        'body': json.dumps('Inventario procesado con éxito')
    }
