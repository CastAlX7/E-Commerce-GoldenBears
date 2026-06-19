resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

resource "aws_ecs_service" "demo-ecs-service" {
    name            = "demo-ecs-svc"
    cluster         = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.ecs_taskdef.arn
    desired_count   = 2
    
    deployment_maximum_percent         = 200
    deployment_minimum_healthy_percent = 50
    
    launch_type = "FARGATE"
    depends_on  = [aws_lb_target_group.alb_ecs_tg, aws_lb_listener.front_end]

    load_balancer {
        target_group_arn = aws_lb_target_group.alb_ecs_tg.arn
        container_name   = "web"
        container_port   = 8080
    }

    network_configuration {
        security_groups  = [var.ecs_sg_id]
        subnets          = var.private_subnets
        assign_public_ip = false
    }
}

resource "aws_ecs_task_definition" "ecs_taskdef" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "nginx:latest" 
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
}