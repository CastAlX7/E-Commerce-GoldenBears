output "vpc_id" {
  value = module.networking.vpc_id
  description = "ID de la VPC principal"
}

output "api_gateway_endpoint" {
  value       = module.computing.apigw_http_endpoint
  description = "Endpoint del API Gateway"
}

output "alb_dns_name" {
  value       = module.computing.alb_dns_name
  description = "DNS del Application Load Balancer"
}

output "rds_proxy_endpoint" {
  value       = module.database.rds_proxy_endpoint
  description = "Endpoint del RDS Proxy"
}

output "redis_primary_endpoint" {
  value       = module.database.redis_primary_endpoint
  description = "Endpoint primario de Redis"
}

output "nubefact_secret_arn" {
  value       = module.security.nubefact_secret_arn
  description = "ARN del secreto de NubeFact"
  sensitive   = true
}
