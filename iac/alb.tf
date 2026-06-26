resource "aws_lb" "ecs_alb" {
  name                       = "${var.project_name}-alb-${terraform.workspace}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [aws_subnet.private_ingress_a.id, aws_subnet.private_ingress_b.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = var.alb_deletion_protection

  access_logs {
    bucket  = aws_s3_bucket.documental.id
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
  port        = 8080
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
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "${var.project_name}-listener-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
