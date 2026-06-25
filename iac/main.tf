module "networking" {
  source       = "./networking"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  region       = var.region
  aws_region   = var.region
}

module "security" {
  source           = "./security"
  project_name     = var.project_name
  redis_auth_token = var.redis_auth_token
}

module "database" {
  source                 = "./database"
  project_name           = var.project_name
  environment            = var.environment
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  aurora_sg_id           = module.networking.aurora_sg_id
  rds_proxy_sg_id        = module.networking.rds_proxy_sg_id
  elasticache_sg_id      = module.networking.elasticache_sg_id
  redis_auth_token       = var.redis_auth_token
  kms_key_arn = module.security.kms_key_arn
  elasticache_kms_key_arn = module.security.kms_key_arn
}

module "messaging" {
  source                   = "./messaging"
  project_name             = var.project_name
  environment              = var.environment
  region                   = var.region
  private_lambda_subnet_id = module.networking.private_lambda_subnet_id
  lambda_inv_sg_id         = module.networking.lambda_inventario_sg_id
  rds_proxy_resource_id    = module.database.rds_proxy_resource_id
  nubefact_secret_arn      = module.security.nubefact_secret_arn
}

module "computing" {
  source              = "./computing"
  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  private_subnets     = module.networking.private_app_subnet_ids
  ecs_sg_id           = module.networking.ecs_sg_id
  alb_sg_id           = module.networking.alb_sg_id
  vpc_link_sg_id      = module.networking.vpc_link_sg_id
  app_db_secret_arn   = module.security.app_db_secret_arn
  secrets_kms_key_arn = module.security.secrets_kms_key_arn
  alb_logs_bucket = module.messaging.documental_bucket_name
  sns_orders_topic_arn    = module.messaging.sns_orders_topic_arn
  sqs_inventory_queue_arn = module.messaging.sqs_inventory_queue_arn
}

module "presentacion" {
  source      = "./presentacion"
  bucket_name = "${var.project_name}-frontend-app-bucket"
  domain_name = var.domain_name
}

