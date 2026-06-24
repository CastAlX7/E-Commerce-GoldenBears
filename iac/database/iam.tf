resource "aws_iam_role" "rds_proxy_role" {
  name        = "${var.project_name}-${var.environment}-rds-proxy-role"
  description = "Rol asumido por el RDS Proxy para leer el secreto de Aurora"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}