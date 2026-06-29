import json
import logging
import os
import boto3
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_db_connection():
    """Conecta al RDS Proxy usando IAM auth token."""
    rds_client = boto3.client("rds", region_name=os.environ.get("AWS_REGION", "us-east-1"))
    token = rds_client.generate_db_auth_token(
        DBHostname=os.environ["DB_PROXY_ENDPOINT"],
        Port=5432,
        DBUsername=os.environ.get("DB_USER", "inventory_user"),
    )
    return psycopg2.connect(
        host=os.environ["DB_PROXY_ENDPOINT"],
        port=5432,
        dbname=os.environ.get("DB_NAME", "goldenbearsdb"),
        user=os.environ.get("DB_USER", "inventory_user"),
        password=token,
        sslmode="require",
    )


def lambda_handler(event, context):
    """
    Descuenta stock de productos al confirmar una orden.
    Mensaje SQS esperado:
    {
      "order_id": "uuid",
      "items": [{"product_id": "uuid", "quantity": N}, ...]
    }
    """
    conn = get_db_connection()
    cur = conn.cursor()
    processed = []
    failed = []

    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            order_id = body["order_id"]
            items = body["items"]

            for item in items:
                cur.execute(
                    """
                    UPDATE products
                    SET stock = stock - %s
                    WHERE id = %s AND stock >= %s
                    RETURNING id, stock
                    """,
                    (item["quantity"], item["product_id"], item["quantity"]),
                )
                row = cur.fetchone()
                if not row:
                    raise ValueError(
                        f"Stock insuficiente o producto no existe: product_id={item['product_id']}"
                    )

            conn.commit()
            processed.append(order_id)
            logger.info("Stock descontado correctamente para orden %s", order_id)

        except Exception as exc:
            conn.rollback()
            logger.error("Error procesando orden %s: %s", record.get("messageId"), exc)
            failed.append({"messageId": record["messageId"], "error": str(exc)})

    cur.close()
    conn.close()

    if failed:
        return {
            "batchItemFailures": [
                {"itemIdentifier": f["messageId"]} for f in failed
            ]
        }

    return {"statusCode": 200, "processed": processed}