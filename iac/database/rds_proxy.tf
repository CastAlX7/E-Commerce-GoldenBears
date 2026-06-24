resource "aws_db_proxy" "aurora_proxy" {
  name                   = "${var.project_name}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_subnet_ids         = var.private_db_subnet_ids
  vpc_security_group_ids = [var.rds_proxy_sg_id]
  require_tls            = true

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  }
}

resource "aws_db_proxy_default_target_group" "aurora_proxy" {
  db_proxy_name = aws_db_proxy.aurora_proxy.name

  connection_pool_config {
    max_connections_percent = 80
    max_idle_connections_percent = 50
  }

  lifecycle {
    replace_triggered_by = [aws_db_proxy.aurora_proxy.id]
  }
}

resource "aws_db_proxy_target" "aurora_proxy" {
  db_proxy_name         = aws_db_proxy.aurora_proxy.name
  target_group_name     = aws_db_proxy_default_target_group.aurora_proxy.name
  db_cluster_identifier = aws_rds_cluster.aurora.cluster_identifier

  lifecycle {
    replace_triggered_by = [aws_db_proxy.aurora_proxy.id]
  }
}