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

output "aurora_cluster_endpoint" {
  value       = aws_rds_cluster.aurora.endpoint
  description = "Endpoint directo del clúster de Aurora (Escritura) solo para migraciones de datos o scripts de emergencia."
}