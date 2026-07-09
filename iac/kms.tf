resource "aws_kms_key" "shared" {
  description             = "CMK compartida para Golden Bears: Secrets Manager, Aurora, ElastiCache, S3, CloudWatch Logs"
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
    Name        = "${var.project_name}-cmk-shared-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_alias" "shared" {
  name          = "alias/${var.project_name}-shared-${terraform.workspace}"
  target_key_id = aws_kms_key.shared.key_id
}

# Clave dedicada para DNSSEC de Route53 — desactivada ya que no se utiliza Route 53 DNSSEC en desarrollo
# resource "aws_kms_key" "dnssec" {
#   provider                 = aws.us_east_1
#   description              = "KMS para DNSSEC de Route53 - ${var.domain_name}"
#   customer_master_key_spec = "ECC_NIST_P256"
#   key_usage                = "SIGN_VERIFY"
#   deletion_window_in_days  = 7
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "EnableRootAccess"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "AllowRoute53DNSSEC"
#         Effect = "Allow"
#         Principal = {
#           Service = "dnssec-route53.amazonaws.com"
#         }
#         Action = [
#           "kms:DescribeKey",
#           "kms:GetPublicKey",
#           "kms:Sign"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# 
#   tags = {
#     Name        = "${var.project_name}-dnssec-key-${terraform.workspace}"
#     Environment = terraform.workspace
#     Project     = var.project_name
#     ManagedBy   = "Terraform"
#   }
# }
# 
# resource "aws_kms_alias" "dnssec" {
#   provider      = aws.us_east_1
#   name          = "alias/${var.project_name}-dnssec-${terraform.workspace}"
#   target_key_id = aws_kms_key.dnssec.key_id
# }

