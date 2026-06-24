output "rds_proxy_endpoint" {
  value       = aws_db_proxy.aurora_proxy.endpoint
  description = "Endpoint del RDS Proxy"
}

output "rds_proxy_arn" {
  value       = aws_db_proxy.aurora_proxy.arn
  description = "ARN del RDS Proxy."
}

output "rds_proxy_resource_id" {
  value       = aws_db_proxy.aurora_proxy.id
  description = "El ID de recurso del RDS Proxy. Lo requiere el lambda de inventario"
}