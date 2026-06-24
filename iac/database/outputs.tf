output "rds_proxy_endpoint" {
  value       = aws_db_proxy.aurora_proxy.endpoint
  description = "Endpoint del RDS Proxy"
}

output "rds_proxy_arn" {
  value       = aws_db_proxy.aurora_proxy.arn
  description = "ARN del RDS Proxy."
}