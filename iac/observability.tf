# Observability Infrastructure for E-Commerce Golden Bears
# Prometheus & Grafana deployed as isolated services on ECS Fargate

# --- Private DNS Namespace for Service Discovery (AWS Cloud Map) ---
resource "aws_service_discovery_private_dns_namespace" "observability" {
  name        = "golden-bears.local"
  description = "Service Discovery private namespace for Golden Bears"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "backend" {
  name = "golden-bears-backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.observability.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

# --- CloudWatch Log Group for Prometheus & Grafana ---
resource "aws_cloudwatch_log_group" "observability" {
  name              = "/ecs/golden-bears-observability-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn
}

# --- Security Group for Observability Tasks ---
resource "aws_security_group" "observability" {
  name        = "${var.project_name}-observability-sg-${terraform.workspace}"
  description = "Security group for Prometheus and Grafana tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-observability-sg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "grafana_web" {
  security_group_id = aws_security_group.observability.id
  description       = "Allow inbound HTTP access to Grafana from VPC"
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_ipv4         = aws_vpc.main.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "observability_egress" {
  security_group_id = aws_security_group.observability.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- EFS for Grafana Storage ---
resource "aws_efs_file_system" "observability" {
  encrypted  = true
  kms_key_id = aws_kms_key.logs.arn

  tags = {
    Name        = "${var.project_name}-observability-efs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_efs_mount_target" "observability_a" {
  file_system_id  = aws_efs_file_system.observability.id
  subnet_id       = aws_subnet.private_app_a.id
  security_groups = [aws_security_group.observability.id]
}

resource "aws_efs_mount_target" "observability_b" {
  file_system_id  = aws_efs_file_system.observability.id
  subnet_id       = aws_subnet.private_app_b.id
  security_groups = [aws_security_group.observability.id]
}

# --- IAM Roles for Observability Tasks ---
resource "aws_iam_role" "observability_exec" {
  name = "${var.project_name}-observability-exec-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "observability_exec" {
  role       = aws_iam_role.observability_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Ingress to pull configuration from Secrets Manager
resource "aws_iam_policy" "observability_secrets" {
  name = "${var.project_name}-observability-secrets-${terraform.workspace}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "observability_secrets" {
  role       = aws_iam_role.observability_exec.name
  policy_arn = aws_iam_policy.observability_secrets.arn
}

resource "aws_iam_role" "prometheus_task" {
  name = "${var.project_name}-prometheus-task-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "grafana_task" {
  name = "${var.project_name}-grafana-task-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Permissions for Grafana to read CloudWatch logs and metrics
resource "aws_iam_policy" "grafana_cloudwatch_readonly" {
  name = "${var.project_name}-grafana-cloudwatch-policy-${terraform.workspace}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:GetQueryResults",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana_task.name
  policy_arn = aws_iam_policy.grafana_cloudwatch_readonly.arn
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "observability" {
  name = "${var.project_name}-observability-${terraform.workspace}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --- Prometheus Task & Service ---
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.project_name}-prometheus-${terraform.workspace}"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.observability_exec.arn
  task_role_arn            = aws_iam_role.prometheus_task.arn

  volume {
    name = "prometheus-tsdb"
    configure_at_launch = true
  }

  container_definitions = jsonencode([{
    name      = "prometheus"
    image = "${aws_ecr_repository.prometheus.repository_url}:${terraform.workspace}"
    essential = true
    command   = ["--storage.tsdb.retention.time=15d", "--config.file=/etc/prometheus/prometheus.yml"]
    portMappings = [{
      containerPort = 9090
      hostPort      = 9090
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "prometheus-tsdb"
      containerPath = "/prometheus"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.observability.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "prometheus"
      }
    }
  }])
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.project_name}-prometheus-${terraform.workspace}"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.observability.id]
    subnets          = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.project_name}-prometheus-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# --- Grafana Task & Service ---
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project_name}-grafana-${terraform.workspace}"
  cpu                      = "512"
  memory                   = "1024"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.observability_exec.arn
  task_role_arn            = aws_iam_role.grafana_task.arn

  volume {
    name = "grafana-storage"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.observability.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = "grafana/grafana:11.0.0"
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]
    mountPoints = [{
      sourceVolume  = "grafana-storage"
      containerPath = "/var/lib/grafana"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.observability.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "grafana"
      }
    }
  }])
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.project_name}-grafana-${terraform.workspace}"
  cluster         = aws_ecs_cluster.observability.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.observability.id]
    subnets          = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
    assign_public_ip = false
  }

  tags = {
    Name        = "${var.project_name}-grafana-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
