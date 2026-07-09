output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "api_gateway_endpoint" {
  description = "Endpoint del API Gateway HTTP"
  value       = aws_apigatewayv2_stage.apigw_stage.invoke_url
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer interno"
  value       = aws_lb.ecs_alb.dns_name
}

output "rds_proxy_endpoint" {
  description = "Endpoint del RDS Proxy para Aurora"
  value       = aws_db_proxy.aurora_proxy.endpoint
}

output "redis_primary_endpoint" {
  description = "Endpoint primario del clúster Redis"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "nubefact_secret_arn" {
  description = "ARN del secreto de credenciales NubeFact/SUNAT"
  value       = aws_secretsmanager_secret.nubefact_credentials.arn
  sensitive   = true
}

output "cloudfront_domain_name" {
  description = "Dominio de la distribución CloudFront"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN del rol de ejecución de la task definition ECS"
  value       = aws_iam_role.ecs_task_exec.arn
}

output "ecs_task_role_arn" {
  description = "ARN del rol de la task definition ECS"
  value       = aws_iam_role.ecs_task.arn
}

output "app_db_credentials_secret_arn" {
  description = "ARN del secreto con username/database de la app"
  value       = aws_secretsmanager_secret.app_db_credentials.arn
  sensitive   = true
}

output "aurora_master_user_secret_arn" {
  description = "ARN del secreto auto-generado con el password del master user de Aurora"
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  sensitive   = true
}

output "redis_credentials_secret_arn" {
  description = "ARN del secreto con el auth token de Redis"
  value       = aws_secretsmanager_secret.redis_credentials.arn
  sensitive   = true
}
