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

# Prometheus corre en su propia tarea Fargate (ENI/IP propia, modo awsvpc), así
# que Grafana necesita resolverlo por nombre igual que el backend — sin esto,
# el datasource de Prometheus en Grafana no tiene forma de encontrarlo.
resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"

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
  security_group_id            = aws_security_group.observability.id
  description                  = "Allow inbound HTTP access to Grafana from the shared internal ALB (path /grafana/*)"
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "observability_egress" {
  security_group_id = aws_security_group.observability.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Prometheus (observability) -> backend, en el mismo puerto 8000 donde ya
# corre la API — sin esto Prometheus nunca puede scrapear /metrics.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_observability" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Ingress desde Prometheus (observability) en puerto 8000 para scraping"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
  referenced_security_group_id = aws_security_group.observability.id
}

# Montaje de EFS (Grafana) — self-referencing, sin esto el mount de EFS se
# cuelga al iniciar la tarea de Grafana.
resource "aws_vpc_security_group_ingress_rule" "observability_efs_nfs" {
  security_group_id            = aws_security_group.observability.id
  description                  = "Ingress NFS (puerto 2049) para montar EFS de Grafana"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.observability.id
}

# --- Acceso a Grafana vía el ALB interno compartido con el backend ---
# Sin ALB propio: reusa el mismo camino público que ya expone al backend
# (CloudFront -> API Gateway -> VPC Link -> este listener), enrutado por path
# ("/grafana/*", ver aws_lb_listener_rule.grafana en alb.tf). Así Grafana
# hereda el WAF y el TLS de CloudFront gratis, sin quedar con IP/DNS pública
# propia. La autenticación de Grafana (admin + password en Secrets Manager)
# sigue siendo la última línea de defensa detrás de todo esto.
resource "aws_lb_target_group" "grafana" {
  # Nombre corto a propósito: los Target Group tienen un límite duro de 32
  # caracteres en AWS, y "${var.project_name}-grafana-tg-${workspace}" lo supera.
  name        = "gb-grafana-tg-${terraform.workspace}"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  # Con GF_SERVER_SERVE_FROM_SUB_PATH=true (ver container_definitions abajo),
  # Grafana registra TODAS sus rutas internas bajo /grafana/, incluida la de
  # salud — por eso el health check también lleva el prefijo.
  health_check {
    path                = "/grafana/api/health"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "${var.project_name}-grafana-tg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
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

# Grafana corre como usuario no-root (UID/GID 472) dentro del contenedor
# oficial — sin un Access Point que fuerce ese ownership al montar, la raíz
# de EFS queda de root y Grafana no puede escribir ("Permission denied").
resource "aws_efs_access_point" "grafana" {
  file_system_id = aws_efs_file_system.observability.id

  posix_user {
    uid = 472
    gid = 472
  }

  root_directory {
    path = "/grafana"
    creation_info {
      owner_uid   = 472
      owner_gid   = 472
      permissions = "755"
    }
  }

  tags = {
    Name        = "${var.project_name}-grafana-efs-ap-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
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

# Ingress to pull configuration from Secrets Manager — acotado al secret de
# Grafana y a la llave "secrets", no a "*" (mismo patrón de mínimo privilegio
# que el resto de iac/iam.tf).
resource "aws_iam_policy" "observability_secrets" {
  name = "${var.project_name}-observability-secrets-${terraform.workspace}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.grafana_admin.arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.secrets.arn
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

# Permiso para montar el volumen vía el Access Point (autorización IAM del
# mount, además del ownership POSIX que ya fuerza el propio Access Point).
resource "aws_iam_role_policy" "grafana_efs" {
  name = "${var.project_name}-grafana-efs-policy-${terraform.workspace}"
  role = aws_iam_role.grafana_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.observability.arn
        Condition = {
          StringEquals = {
            "elasticfilesystem:AccessPointArn" = aws_efs_access_point.grafana.arn
          }
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

# Rol de infraestructura que ECS asume para provisionar y adjuntar el volumen
# EBS gestionado de Prometheus (distinto del execution/task role — es el rol
# que usa el propio servicio ECS, no el contenedor).
resource "aws_iam_role" "ecs_infrastructure" {
  name = "${var.project_name}-ecs-infra-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSInfrastructureRolePolicyForVolumes"
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
    name                = "prometheus-tsdb"
    configure_at_launch = true
  }

  container_definitions = jsonencode([{
    name      = "prometheus"
    image     = "${aws_ecr_repository.prometheus.repository_url}:${terraform.workspace}"
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

  # El volumen "prometheus-tsdb" del task definition queda como
  # "configure_at_launch" — los parámetros reales del EBS (tamaño, tipo, rol)
  # se proveen acá, a nivel de servicio, no en el task definition.
  volume_configuration {
    name = "prometheus-tsdb"
    managed_ebs_volume {
      role_arn         = aws_iam_role.ecs_infrastructure.arn
      size_in_gb       = 20
      volume_type      = "gp3"
      file_system_type = "ext4"
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
  }

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
      file_system_id     = aws_efs_file_system.observability.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.grafana.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = "${aws_ecr_repository.grafana.repository_url}:${terraform.workspace}"
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
    environment = [
      { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
      # Grafana vive detrás de CloudFront en el path /grafana/* (ver
      # cloudfront.tf) — sin esto, sus assets (CSS/JS) y links internos se
      # generan apuntando a la raíz del dominio y rompen.
      { name = "GF_SERVER_ROOT_URL", value = "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/grafana/" },
      { name = "GF_SERVER_SERVE_FROM_SUB_PATH", value = "true" },
      { name = "GF_SECURITY_CSRF_TRUSTED_ORIGINS", value = "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}" }
    ]
    secrets = [
      {
        name      = "GF_SECURITY_ADMIN_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.grafana_admin.arn}:admin_password::"
      }
    ]
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

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

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
