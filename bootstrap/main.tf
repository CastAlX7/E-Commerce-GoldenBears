# ---------------------------------------------------------------------------
# CMK dedicada para cifrar el bucket de tfstate y el bucket de artifacts.
# Independiente de la(s) CMK del módulo raíz (iac/), ya que este state nunca
# se migra a S3 y no puede depender de recursos gestionados por otro módulo.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "bootstrap" {
  description             = "CMK para el backend remoto de Terraform (tfstate + lambda artifacts) de ${var.project_name}"
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
    Name      = "${var.project_name}-bootstrap-cmk"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_kms_alias" "bootstrap" {
  name          = "alias/${var.project_name}-bootstrap"
  target_key_id = aws_kms_key.bootstrap.key_id
}

# ---------------------------------------------------------------------------
# Bucket S3 para el tfstate del módulo raíz (iac/). Nombre fijo (no lleva el
# account id): todo el equipo comparte esta única cuenta de AWS (developers
# entran vía IAM Identity Center), así que no hace falta desambiguar por
# cuenta. El lock del state usa el lockfile nativo de S3 (use_lockfile en
# iac/backend.tf), no una tabla DynamoDB aparte.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = "${var.project_name}-tfstate"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "${var.project_name}-tfstate"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.bootstrap.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ---------------------------------------------------------------------------
# OIDC provider + IAM Role para el pipeline de CI (GitHub Actions). GitHub
# emite un token de identidad firmado por corrida; AWS lo verifica contra este
# provider y permite asumir el rol sin ninguna credencial de larga duración.
# Definido aquí (bootstrap) y no en el módulo raíz (iac/) para que el propio
# pipeline NUNCA pueda modificar sus propios permisos: cualquier cambio a esta
# policy requiere que un humano corra `terraform apply` a mano.
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name      = "${var.project_name}-github-oidc"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role" "ci" {
  name = "${var.project_name}-ci"

  # Las 3 ramas que disparan el CD (develop/qa/main) pueden asumir este rol
  # para aplicar infraestructura de verdad, y además cualquier Pull Request
  # del mismo repo puede asumirlo para el job "plan" de terraform.yml (que
  # solo hace terraform plan de solo lectura, nunca apply — el job "apply"
  # exige "environment:" + push, un PR nunca dispara ese job). No cubre PRs
  # de forks externos (ref "pull_request", no "pull_request_target").
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_repository}:ref:refs/heads/develop",
              "repo:${var.github_repository}:ref:refs/heads/qa",
              "repo:${var.github_repository}:ref:refs/heads/main",
              "repo:${var.github_repository}:pull_request"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-ci-role"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# Acceso de gestión de infraestructura: el pipeline corre `terraform apply`
# sobre todo lo que provisiona iac/, así que necesita permisos amplios sobre
# los servicios involucrados. Va todo en UNA sola policy propia (comodín por
# servicio, mismo nivel de acceso que las *FullAccess de AWS) en vez de una
# policy administrada por servicio: IAM limita a 10 el máximo de policies
# administradas por rol (hard limit, no se puede pedir aumento), y la lista
# original de 19 lo superaba. Sin Route53/ACM (ya no se usan, se sacaron de
# iac/) y con "signer:*" para el code signing de las Lambdas (el ARN
# administrado "AWSSignerReadOnlyAccess" no existe).
resource "aws_iam_policy" "ci_infra_access" {
  name = "${var.project_name}-ci-infra-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InfraServicesAccess"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "rds:*",
          "elasticache:*",
          "lambda:*",
          "sqs:*",
          "sns:*",
          "s3:*",
          "iam:*",
          "kms:*",
          "secretsmanager:*",
          "cloudfront:*",
          "wafv2:*",
          "apigateway:*",
          "logs:*",
          "signer:*",
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-ci-infra-access"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ci_infra_access" {
  role       = aws_iam_role.ci.name
  policy_arn = aws_iam_policy.ci_infra_access.arn
}

# Acceso al backend remoto, acotado explícitamente al bucket de este módulo,
# más un Deny explícito sobre las acciones destructivas. El Deny es necesario
# porque "ci_infra_access" ya otorga "s3:*" sobre "*" (para poder gestionar
# cualquier bucket que cree iac/) — un Allow amplio en otra policy no se
# restringe solo, hace falta un Deny explícito para que el rol realmente no
# pueda borrar el bucket ni sus objetos, aunque se vea comprometido.
resource "aws_iam_role_policy" "ci_backend_access" {
  name = "${var.project_name}-ci-backend-access"
  role = aws_iam_role.ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TfstateBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },
      {
        Sid    = "DenyTfstateBucketDestruction"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
      },
      {
        Sid      = "BootstrapKmsUsage"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = aws_kms_key.bootstrap.arn
      }
    ]
  })
}
