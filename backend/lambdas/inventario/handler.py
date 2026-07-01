import json
import logging

# Configuración básica del Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda de Inventario (Mock / Simulación):
    - Escucha eventos de la cola SQS (inventory_queue).
    - Procesa los ítems y cantidades para actualizar el stock.
    - Como estamos simulando la persistencia en desarrollo, logueamos la acción con éxito.
    """
    logger.info(f"Evento SQS de Inventario recibido: {json.dumps(event)}")
    
    for record in event.get('Records', []):
        try:
            # SQS entrega el cuerpo del mensaje como string
            body = json.loads(record['body'])
            order_id = body.get('order_id', 'N/A')
            items = body.get('items', [])
            
            logger.info(f"Procesando deducción de inventario para la orden ID: {order_id}")
            for item in items:
                product_id = item.get('product_id')
                quantity = item.get('quantity')
                logger.info(f"Deduciendo {quantity} unidades del producto ID: {product_id} en la base de datos.")
                
        except Exception as e:
            logger.error(f"Error procesando registro de inventario: {str(e)}")
            
    return {
        'statusCode': 200,
        'body': json.dumps('Inventario procesado con éxito (Simulado)')
    }
