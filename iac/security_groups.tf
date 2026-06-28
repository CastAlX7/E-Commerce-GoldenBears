resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-default-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# --- VPC Link (API Gateway → ALB) ---

resource "aws_security_group" "vpc_link" {
  name        = "${var.project_name}-vpc-link-sg-${terraform.workspace}"
  description = "Security group para el VPC Link de API Gateway"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-vpc-link-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_alb" {
  security_group_id            = aws_security_group.vpc_link.id
  description                  = "Egress al ALB en puerto 8000"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = aws_security_group.alb.id
}

# --- Application Load Balancer ---

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${terraform.workspace}"
  description = "Security group del ALB interno"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-alb-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Ingress desde VPC Link en puerto 8000"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = aws_security_group.vpc_link.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Egress al ECS en puerto 8000"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = aws_security_group.ecs.id
}

# --- ECS Fargate Tasks ---

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg-${terraform.workspace}"
  description = "Security group para las tareas ECS Fargate"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-ecs-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Ingress desde ALB en puerto 8000"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds_proxy" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Egress al RDS Proxy (PostgreSQL)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_elasticache" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Egress a ElastiCache Redis"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.elasticache.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_internet_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "Egress a Internet (HTTPS)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_vpc_endpoints" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Egress a VPC Endpoints (HTTPS)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

# --- RDS Proxy ---

resource "aws_security_group" "rds_proxy" {
  name        = "${var.project_name}-rds-proxy-sg-${terraform.workspace}"
  description = "Security group del RDS Proxy"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-rds-proxy-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_ecs" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Ingress desde ECS (PostgreSQL)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_lambda_inventario" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Ingress desde Lambda Inventario (PostgreSQL)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.lambda_inventario.id
}

resource "aws_vpc_security_group_egress_rule" "rds_proxy_to_aurora" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "Egress a Aurora (PostgreSQL)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.aurora.id
}

# --- Aurora PostgreSQL ---

resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-aurora-sg-${terraform.workspace}"
  description = "Security group del cluster Aurora PostgreSQL"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-aurora-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_rds_proxy" {
  security_group_id            = aws_security_group.aurora.id
  description                  = "Ingress exclusivo desde RDS Proxy"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

# --- ElastiCache Redis ---

resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-elasticache-sg-${terraform.workspace}"
  description = "Security group de ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-elasticache-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_from_ecs" {
  security_group_id            = aws_security_group.elasticache.id
  description                  = "Ingress desde ECS (Redis)"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.ecs.id
}

# --- Lambda Inventario ---

resource "aws_security_group" "lambda_inventario" {
  name        = "${var.project_name}-lambda-inventario-sg-${terraform.workspace}"
  description = "Security group de Lambda Inventario (dentro de VPC)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-lambda-inventario-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_inventario_to_rds_proxy" {
  security_group_id            = aws_security_group.lambda_inventario.id
  description                  = "Egress al RDS Proxy (PostgreSQL)"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_inventario_to_vpc_endpoints" {
  security_group_id            = aws_security_group.lambda_inventario.id
  description                  = "Egress a VPC Endpoints (HTTPS)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

# --- Lambda de comprobantes----
resource "aws_security_group" "lambda_comprobantes" {
  name        = "${var.project_name}-lambda-comprobantes-sg-${terraform.workspace}"
  description = "Security group de Lambda Comprobantes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-lambda-comprobantes-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_comprobantes_to_internet_https" {
  security_group_id = aws_security_group.lambda_comprobantes.id
  description       = "Salida HTTPS a Internet via NAT"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "lambda_comprobantes_to_vpc_endpoints" {
  security_group_id            = aws_security_group.lambda_comprobantes.id
  description                  = "Salida HTTPS a VPC Endpoints"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

# --- VPC Endpoints ---

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg-${terraform.workspace}"
  description = "Security group para los VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-vpc-endpoints-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_from_ecs" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Ingress desde ECS (HTTPS)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_from_lambda_inventario" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Ingress desde Lambda Inventario (HTTPS)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.lambda_inventario.id
}
