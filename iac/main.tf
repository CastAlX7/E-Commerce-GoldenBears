module "networking" {
  source       = "./networking"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  region       = var.region
  aws_region   = var.region
}

