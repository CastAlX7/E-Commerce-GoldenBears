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

output "aurora_master_user_secret_arn" {
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  description = "ARN del secreto generado automáticamente en AWS Secrets Manager que almacena las credenciales master."
}

output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Endpoint de lectura y escritura del nodo primario de Redis para la gestión de sesiones e inventario."
}

output "redis_reader_endpoint" {
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
  description = "Endpoint de solo lectura del nodo réplica de Redis."
}