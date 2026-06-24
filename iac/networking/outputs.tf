output "vpc_id" {
  description = "ID de la VPC principal"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "ecs_sg_id" {
  description = "ID del Security Group para ECS"
  value       = aws_security_group.ecs.id
}

output "alb_sg_id" {
  description = "ID del Security Group para ALB"
  value       = aws_security_group.alb.id
}

output "vpc_link_sg_id" {
  description = "ID del Security Group para VPC Link"
  value       = aws_security_group.vpc_link.id
}

output "elasticache_sg_id" {
  description = "ID del Security Group para ElastiCache"
  value       = aws_security_group.elasticache.id
}

output "rds_proxy_sg_id" {
  description = "ID del Security Group para RDS Proxy"
  value       = aws_security_group.rds_proxy.id
}

output "aurora_sg_id" {
  description = "ID del Security Group para Aurora"
  value       = aws_security_group.aurora.id
}

output "lambda_inventario_sg_id" {
  description = "ID del Security Group para Lambda Inventario"
  value       = aws_security_group.lambda_inventario.id
}

output "vpc_endpoints_sg_id" {
  description = "ID del Security Group para VPC Endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "private_app_subnet_ids" {
  description = "IDs de las subredes privadas de aplicación"
  value       = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
}

output "private_ingress_subnet_ids" {
  description = "IDs de las subredes privadas de ingress"
  value       = [aws_subnet.private_ingress_a.id, aws_subnet.private_ingress_b.id]
}

output "private_db_subnet_ids" {
  description = "IDs de las subredes privadas de base de datos"
  value       = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}

output "private_lambda_subnet_id" {
  description = "ID de la subred privada aislada para Lambda de Inventario"
  value       = aws_subnet.private_lambda_a.id
}