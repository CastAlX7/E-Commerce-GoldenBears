# Publicador Central
resource "aws_sns_topic" "orders_topic" {
  name = "golden-bears-orders-topic"

  # reemplazar por una CMK propia cuando unifiquen módulos
  kms_master_key_id = "alias/aws/sns"
}

# Suscripciones (Patron FanOut)

# Suscripcion A: Hacia la cola de Inventario

resource "aws_sns_topic_subscription" "sns_to_sqs_inventory" {
  topic_arn = aws_sns_topic.orders_topic.arn
  protocol  = "sqs"

  # Conecta la cola SQS y crea dependencia implícita en Terraform
  endpoint  = aws_sqs_queue.inventory_queue.arn

  # Evita que el mensaje llegue envuelto en información extra, facilitando su lectura.
  raw_message_delivery = true
}

# Suscripcion B: Hacia la cola de Comprobantes

resource "aws_sns_topic_subscription" "sns_to_sqs_billing" {
  topic_arn = aws_sns_topic.orders_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.billing_queue.arn
  raw_message_delivery = true
}