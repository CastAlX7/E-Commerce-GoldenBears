resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_144: El bucket de logs S3 no requiere de replicación cross-region.
  # checkov:skip=CKV2_AWS_62: Este bucket no requiere notificaciones de eventos (SNS/SQS/Lambda); no existe flujo event-driven asociado.
  # El nombre del bucket de logs de WAFv2 DEBE empezar con "aws-waf-logs-" por restriccion del API de AWS, de lo contrario fallara al configurar el logging.
  # checkov:skip=CKV_AWS_21: Bucket de logs con política operativa sin versionado.
  bucket        = "aws-waf-logs-${var.project_name}-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  # checkov:skip=CKV_AWS_145: ALB access logging no soporta buckets con SSE-KMS
  # (falla en runtime con "Access Denied... Please check S3 bucket permission",
  # sin importar qué política KMS se agregue) — mismo motivo por el que
  # aws_s3_bucket.documental ya usa AES256 en vez de KMS.
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    expiration {
      days = var.log_retention_days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowALBAccessLogs"
      Effect = "Allow"
      Principal = {
        AWS = data.aws_elb_service_account.main.arn
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.logs.arn}/alb/*"
    }]
  })
}


# --- Bucket Frontend (SPA / activos estáticos) ---

resource "aws_s3_bucket" "frontend" {
  # checkov:skip=CKV_AWS_144: Bucket de artefactos estáticos del SPA; se reconstruye/republica desde CI en minutos, no requiere replicación cross-region.
  # checkov:skip=CKV2_AWS_62: Bucket estático de frontend sin consumidores de eventos S3.
  bucket        = "${var.project_name}-frontend-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-frontend-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "frontend" {
  bucket        = aws_s3_bucket.frontend.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "frontend_oac" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.frontend_cdn.arn
        }
      }
    }]
  })
}

# --- Bucket Documental (exclusivo para comprobantes electrónicos SUNAT) ---

resource "aws_s3_bucket" "documental" {
  # checkov:skip=CKV2_AWS_62: Bucket documental sin integración event-driven; el procesamiento no depende de eventos S3.
  bucket        = "${var.project_name}-documental-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-documental-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Compliance  = "SUNAT"
  }
}

resource "aws_s3_bucket_versioning" "documental" {
  bucket = aws_s3_bucket.documental.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "documental" {
  bucket                  = aws_s3_bucket.documental.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documental" {
  # checkov:skip=CKV_AWS_145: Usar SSE-S3 (AES256) en lugar de SSE-KMS es requerido para permitir que el servicio de AWS Elastic Load Balancing (ALB) escriba logs de acceso sin requerir politicas complejas de KMS compartidas con cuentas de servicio de AWS.
  bucket = aws_s3_bucket.documental.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "documental" {
  bucket        = aws_s3_bucket.documental.id
  target_bucket = aws_s3_bucket.documental.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "documental" {
  bucket = aws_s3_bucket.documental.id

  rule {
    id     = "facturas-retencion-sunat"
    status = "Enabled"
    filter {
      prefix = "facturas/"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket" "documental_replica" {
  # checkov:skip=CKV2_AWS_62: Bucket réplica de contingencia, sin notificaciones requeridas.
  provider      = aws.replica
  bucket        = "${var.project_name}-documental-replica-${terraform.workspace}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-documental-replica-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Compliance  = "SUNAT-Replica"
  }
}

resource "aws_s3_bucket_versioning" "documental_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.documental_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "documental" {
  bucket = aws_s3_bucket.documental.id
  role   = aws_iam_role.s3_replication_documental.arn

  rule {
    id     = "replicate-all-documental"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.documental_replica.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.documental,
    aws_s3_bucket_versioning.documental_replica
  ]
}