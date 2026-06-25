output "documental_bucket_name" {
  value       = aws_s3_bucket.documental.id
  description = "Nombre del bucket S3 documental para logs de acceso y comprobantes"
}

output "sns_orders_topic_arn" {
  value       = aws_sns_topic.orders_topic.arn
  description = "ARN del topico SNS de ordenes centralizadas"
}

output "sqs_inventory_queue_arn" {
  value       = aws_sqs_queue.inventory_queue.arn
  description = "ARN de la cola SQS de inventario para procesamiento"
}