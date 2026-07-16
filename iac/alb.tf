resource "aws_lb" "ecs_alb" {
  # checkov:skip=CKV2_AWS_20: ALB interno accedido via VPC Link desde API Gateway. El backend FastAPI (uvicorn) escucha en el puerto 8000 por convencion WSGI/ASGI en contenedores Linux — usar puerto 80 requeriria privilegios root (CAP_NET_BIND_SERVICE), lo cual viola el principio de minimo privilegio y generaria fallos en CKV_ECS_16.

  name                       = "${var.project_name}-alb-${terraform.workspace}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [aws_subnet.private_ingress_a.id, aws_subnet.private_ingress_b.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = terraform.workspace == "prod" ? true : false

  access_logs {
    bucket  = aws_s3_bucket.logs.id
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-alb-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg-${terraform.workspace}"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "${var.project_name}-tg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_listener" "main" {
  # checkov:skip=CKV_AWS_2: Este listener es interno/VPC Link y el tráfico HTTPS se termina en API Gateway/CloudFront.
  # checkov:skip=CKV_AWS_103: Al usar HTTP para tráfico interno/VPC Link, no se configura SSL/TLS en esta capa.
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 8000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name        = "${var.project_name}-listener-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Reenvía /grafana/* (llega vía CloudFront -> API Gateway -> este mismo VPC
# Link/listener) al target group de Grafana en vez del backend. Así Grafana
# no necesita su propio ALB público.
resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    path_pattern {
      values = ["/grafana/*"]
    }
  }

  tags = {
    Name        = "${var.project_name}-grafana-rule-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}