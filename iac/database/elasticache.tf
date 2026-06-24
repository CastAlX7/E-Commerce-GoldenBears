resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = var.private_app_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id        = "${var.project_name}-redis"
  description                = "Cluster de Redis para reservas temporales de inventario y cache"  
    engine_version             = "7.1"
  node_type                  = "cache.t3.micro"
  parameter_group_name       = "default.redis7"
    num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.elasticache_sg_id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  auth_token_update_strategy = "ROTATE"
}