resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group-${terraform.workspace}"
  subnet_ids = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]

  tags = {
    Name        = "${var.project_name}-redis-subnet-group-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis-${terraform.workspace}"
  description                = "Clúster Redis para reservas temporales de inventario y caché de sesión"
  engine_version             = "7.1"
  node_type                  = var.redis_node_type
  parameter_group_name       = "default.redis7"
  num_cache_clusters         = var.redis_num_cache_clusters
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.elasticache.id]
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.shared.arn
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  tags = {
    Name        = "${var.project_name}-redis-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
