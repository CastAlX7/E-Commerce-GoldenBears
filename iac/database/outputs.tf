output "rds_proxy_endpoint" {
  value       = aws_db_proxy.aurora_proxy.endpoint
  description = "Endpoint del RDS Proxy"
}