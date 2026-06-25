resource "aws_s3_bucket" "documental" {
  bucket = "golden-bears-documental"

  tags = {
    Name        = "Bucket Documental Fiscal"
    Environment = "Dev"
    Compliance = "SUNAT"
  }
}

resource "aws_s3_bucket_public_access_block" "seguridad_comprobantes" {
  bucket = aws_s3_bucket.documental.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encriptacion_comprobantes" {
  bucket = aws_s3_bucket.documental.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "versiones_comprobantes" {
  bucket = aws_s3_bucket.documental.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "logging_comprobantes" {
  bucket        = aws_s3_bucket.documental.id
  target_bucket = aws_s3_bucket.documental.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_comprobantes" {
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

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.documental.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.documental.arn}/alb/*"
      }
    ]
  })
}