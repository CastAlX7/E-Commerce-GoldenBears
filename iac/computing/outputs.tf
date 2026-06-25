output "apigw_http_endpoint" {
  value       = aws_apigatewayv2_api.apigw_http_endpoint.api_endpoint
  description = "Api Gateway Endpoint"
}

output "alb_arn" {
  value       = aws_lb.ecs_alb.arn
  description = "ARN del Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_lb.ecs_alb.dns_name
  description = "DNS del ALB"
}

output "documental_bucket_name" {
  value       = aws_s3_bucket.documental.bucket
  description = "Nombre del bucket S3 documental para logs y comprobantes"
}

output "sns_orders_topic_arn" {
  value       = aws_sns_topic.orders_topic.arn
  description = "ARN del topic SNS de ordenes"
}

output "sqs_inventory_queue_arn" {
  value       = aws_sqs_queue.inventory_queue.arn
  description = "ARN de la cola SQS de inventario"
}