# 1. SECURITY GROUP: VPC Link V2 (API Gateway)

resource "aws_security_group" "vpc_link" {
  name        = "${var.project_name}-vpc-link-sg"
  description = "Security Group para el VPC Link de API Gateway"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-vpc-link-sg" }
}

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_alb" {
  security_group_id            = aws_security_group.vpc_link.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Permite enviar trafico al ALB interno en el puerto 8080"
}

# 2. SECURITY GROUP: Application Load Balancer Interno (ALB)

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group para el ALB Interno"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.vpc_link.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Solo acepta trafico proveniente del VPC Link"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Reenvia peticiones a los contenedores ECS Fargate"
}

# 3. SECURITY GROUP: ECS Fargate Tasks (Backend Monolito)

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security Group para las tareas de ECS Fargate"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-ecs-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Acepta trafico HTTP unicamente desde el ALB"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds_proxy" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Salida hacia el Proxy de la Base de Datos PostgreSQL"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_elasticache" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.elasticache.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Salida hacia el cluster de Redis"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_internet_https" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Salida HTTPS general para pasarelas (Culqi/Niubiz) y VPC Endpoints"
}

# 4. SECURITY GROUP: RDS Proxy

resource "aws_security_group" "rds_proxy" {
  name        = "${var.project_name}-rds-proxy-sg"
  description = "Security Group para el RDS Proxy"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-rds-proxy-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_ecs" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Conexiones PostgreSQL desde las tareas ECS"
}

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_lambda" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.lambda_inventario.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Conexiones PostgreSQL desde la Lambda de Inventario"
}

resource "aws_vpc_security_group_egress_rule" "rds_proxy_to_aurora" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.aurora.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Envio de conexiones agrupadas hacia Aurora"
}

# 5. SECURITY GROUP: Aurora PostgreSQL Cluster

resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-aurora-sg"
  description = "Security Group exclusivo para la base de datos Aurora"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-aurora-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_rds_proxy" {
  security_group_id            = aws_security_group.aurora.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Aislamiento total: solo acepta trafico del RDS Proxy"
}

# 6. SECURITY GROUP: ElastiCache (Redis)
resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-elasticache-sg"
  description = "Security Group para el Cluster de Redis"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-elasticache-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.elasticache.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Solo el backend ECS puede leer/escribir en la cache"
}

# 7. SECURITY GROUP: Lambda Inventario
resource "aws_security_group" "lambda_inventario" {
  name        = "${var.project_name}-lambda-inventario-sg"
  description = "Security Group para la funcion Lambda de Inventario"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-lambda-inventario-sg" }
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_rds_proxy" {
  security_group_id            = aws_security_group.lambda_inventario.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Permite a la Lambda conectarse al RDS Proxy para actualizar stock"
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_endpoints_internal" {
  security_group_id = aws_security_group.lambda_inventario.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Permite acceso HTTPS a servicios externos mediante NAT Gateway"
}

# 8. SECURITY GROUP: VPC Endpoints (Interface Endpoints)
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-vpc-endpoints-sg"
  description = "Security Group para las ENIs de los Interface VPC Endpoints"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project_name}-vpc-endpoints-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_ecs" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Permite llamadas HTTPS seguras desde las tareas de ECS"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_lambda" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.lambda_inventario.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Permite llamadas HTTPS seguras desde la Lambda de Inventario"
}