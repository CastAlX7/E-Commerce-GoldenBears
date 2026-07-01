import json
import os
import boto3
import logging

# Configuración básica del Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Cliente nativo de AWS S3 (Lambda lo tiene incluido por defecto)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Lambda de Comprobantes (Simulación de NubeFact y guardado en S3):
    - Escucha eventos de la cola SQS (billing_queue).
    - Simula la emisión del comprobante (Factura/Boleta) a NubeFact.
    - Genera la respuesta mock en JSON y la sube al bucket S3 'documental' en la carpeta 'facturas/'.
    """
    logger.info(f"Evento SQS de Comprobantes recibido: {json.dumps(event)}")
    
    # Obtenemos las variables de entorno de AWS
    project_name = os.environ.get("PROJECT_NAME", "e-comerce-golden-bears")
    environment = os.environ.get("ENVIRONMENT", "dev")
    
    # Reconstruimos el nombre del bucket documental
    bucket_name = f"{project_name}-documental-{environment}"
    
    for record in event.get('Records', []):
        try:
            body = json.loads(record['body'])
            order_id = body.get('order_id', 'unknown')
            billing_info = body.get('billing', {})
            total = body.get('total', 0)
            
            logger.info(f"Procesando facturación de la orden: {order_id} por un total de S/. {total}")
            
            # 1. Simulación de llamada a NubeFact (Mock/SUNAT)
            # Retorna una respuesta exitosa falsa simulando el servicio externo
            logger.info("Simulando llamada a API NubeFact...")
            nubefact_response = {
                "status": "success",
                "invoice_number": f"FFF1-{order_id[:8].upper()}",
                "total": float(total),
                "ruc": billing_info.get("ruc", "N/A"),
                "razon_social": billing_info.get("razon_social", "Cliente Genérico"),
                "pdf_url_mock": f"https://api.nubefact.com/mock-invoice-{order_id}.pdf"
            }
            
            # 2. Guardar comprobante generado en S3
            s3_key = f"facturas/factura-{order_id}.json"
            logger.info(f"Subiendo comprobante simulado a S3 en: {bucket_name}/{s3_key}")
            
            s3.put_object(
                Bucket=bucket_name,
                Key=s3_key,
                Body=json.dumps(nubefact_response, indent=2),
                ContentType="application/json"
            )
            logger.info("Comprobante subido a S3 con éxito.")
            
        except Exception as e:
            logger.error(f"Error procesando registro de comprobantes: {str(e)}")
            
    return {
        'statusCode': 200,
        'body': json.dumps('Facturación procesada con éxito (Simulado)')
    }
