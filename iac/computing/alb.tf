# Creacion de alb en private subnets
resource "aws_lb" "ecs_alb" {
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.private_subnets
}