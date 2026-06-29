resource "aws_secretsmanager_secret" "app_db_credentials" {
  name                    = "${var.project_name}/${terraform.workspace}/app/db-credentials"
  kms_key_id              = aws_kms_key.shared.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "${var.project_name}-app-db-credentials-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "app_db_credentials" {
  secret_id = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    database = "goldenbearsdb"
    port     = 5432
  })
}

resource "aws_secretsmanager_secret" "nubefact_credentials" {
  name                    = "${var.project_name}/${terraform.workspace}/billing/nubefact"
  kms_key_id              = aws_kms_key.shared.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "${var.project_name}-nubefact-credentials-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Compliance  = "SUNAT"
  }
}

resource "aws_secretsmanager_secret_version" "nubefact_credentials" {
  secret_id = aws_secretsmanager_secret.nubefact_credentials.id
  secret_string = jsonencode({
    nubefact_token = "PLACEHOLDER_SUNAT_NUBEFACT_TOKEN"
    nubefact_url   = "https://api.nubefact.com/v1/each"
  })
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.project_name}/${terraform.workspace}/cache/redis-token"
  kms_key_id              = aws_kms_key.shared.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "${var.project_name}-redis-credentials-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id     = aws_secretsmanager_secret.redis_credentials.id
  secret_string = jsonencode({ auth_token = var.redis_auth_token })
}

resource "aws_secretsmanager_secret" "culqi_credentials" {
  name                    = "${var.project_name}/${terraform.workspace}/payments/culqi"
  kms_key_id              = aws_kms_key.shared.arn
  recovery_window_in_days = 0

  tags = {
    Name        = "${var.project_name}-culqi-credentials-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "culqi_credentials" {
  secret_id = aws_secretsmanager_secret.culqi_credentials.id
  secret_string = jsonencode({
    secret_key = "sk_test_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  })
}