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