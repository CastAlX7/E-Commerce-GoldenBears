# 5 CMK especializadas en vez de una sola "shared": si un componente
# comprometido (Lambda, contenedor ECS, cuenta de un compañero) recibe
# kms:Decrypt sobre UNA de estas keys, el radio de impacto queda acotado a
# ese dominio — nunca alcanza para descifrar, por ejemplo, credenciales
# reales solo por tener acceso a los logs de CloudWatch.

# ---------------------------------------------------------------------------
# kms_secrets: los 4 secretos de Secrets Manager + el password maestro
# autogenerado de Aurora. El dominio más sensible — es lo único que, si se
# filtra, es un login/token reusable directo en otro sistema.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "secrets" {
  description             = "CMK para Secrets Manager y el password maestro de Aurora — Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManager"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk-secrets-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-secrets-${terraform.workspace}"
  target_key_id = aws_kms_key.secrets.key_id
}

# ---------------------------------------------------------------------------
# kms_database: storage físico de Aurora, Performance Insights, y los datos
# cacheados en ElastiCache. Dato en reposo, no credenciales. Sin statement de
# servicio explícito (RDS/ElastiCache nunca lo necesitaron con la key
# original tampoco — solo EnableRootAccess), para no cambiar comportamiento.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "database" {
  description             = "CMK para storage de Aurora y ElastiCache — Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk-database-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.project_name}-database-${terraform.workspace}"
  target_key_id = aws_kms_key.database.key_id
}

# ---------------------------------------------------------------------------
# kms_logs: los Log Groups de CloudWatch (ECS, Lambdas, API Gateway, VPC Flow
# Logs). Contenido operativo/observabilidad, no credenciales.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "logs" {
  description             = "CMK para CloudWatch Logs — Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-logs-${terraform.workspace}"
  target_key_id = aws_kms_key.logs.key_id
}

# ---------------------------------------------------------------------------
# kms_s3: el bucket de logs y el bucket estático del frontend.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "s3" {
  description             = "CMK para buckets S3 (logs y frontend) — Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        # CloudFront (via OAC) necesita descifrar el objeto para servirlo —
        # sin esto, GetObject falla (403 AccessDenied) aunque el bucket
        # policy sí le de s3:GetObject, porque el paso de descifrado con
        # KMS es aparte. HeadObject no lo necesita (no devuelve contenido),
        # por eso solo falla el GET, no el HEAD.
        Sid    = "AllowCloudFrontDecrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "kms:Decrypt"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_cloudfront_distribution.frontend_cdn.arn
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk-s3-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-s3-${terraform.workspace}"
  target_key_id = aws_kms_key.s3.key_id
}

# ---------------------------------------------------------------------------
# kms_compute: variables de entorno de las Lambdas (Inventario y
# Comprobantes) — no son secretas (DB_HOST, SNS_TOPIC_ARN, etc.), pero AWS
# exige una CMK si se activa cifrado de env vars.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "compute" {
  description             = "CMK para variables de entorno de las Lambdas — Golden Bears"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowLambda"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cmk-compute-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "compute" {
  name          = "alias/${var.project_name}-compute-${terraform.workspace}"
  target_key_id = aws_kms_key.compute.key_id
}
