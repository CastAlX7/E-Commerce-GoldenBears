data "aws_caller_identity" "current" {}

resource "aws_kms_key" "secrets_key" {
  description             = "Llave KMS para cifrar secretos de la app Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = { Name = "${var.project_name}-secrets-key" }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3KMS"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      }

    ]
  })
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/${var.project_name}-secrets-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# Credenciales del Backend de la Aplicación 

resource "aws_secretsmanager_secret" "app_db_credentials" {
  name                    = "${var.project_name}/app/db-credentials"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "app_db_credentials_val" {
  secret_id = aws_secretsmanager_secret.app_db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    database = "goldenbearsdb"
    port     = 5432
  })
}

# Credenciales para facturación

resource "aws_secretsmanager_secret" "nubefact_credentials" {
  name                    = "${var.project_name}/billing/nubefact"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "nubefact_credentials_val" {
  secret_id = aws_secretsmanager_secret.nubefact_credentials.id
  secret_string = jsonencode({
    nubefact_token = "PLACEHOLDER_SUNAT_NUBEFACT_TOKEN"
    nubefact_url   = "https://api.nubefact.com/v1/each"
  })
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.project_name}/cache/redis-token"
  kms_key_id              = aws_kms_key.secrets_key.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis_credentials_val" {
  secret_id     = aws_secretsmanager_secret.redis_credentials.id
  secret_string = var.redis_auth_token
}