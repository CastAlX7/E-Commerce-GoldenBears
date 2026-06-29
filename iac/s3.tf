# --- Bucket de logs (access logs + cloudfront) ---

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${terraform.workspace}"

  tags = {
    Name        = "${var.project_name}-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      # CloudFront classic logging no soporta SSE-KMS — requiere AES256
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }    
    expiration {
      days = var.log_retention_days
    }
  }
}
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}


# --- Bucket WAF Logs (nombre obligatorio aws-waf-logs-* para WAFv2) ---

resource "aws_s3_bucket" "waf_logs" {
  bucket = "aws-waf-logs-${var.project_name}-${terraform.workspace}"

  tags = {
    Name        = "aws-waf-logs-${var.project_name}-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.waf.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    id     = "expire-waf-logs"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }    
    expiration {
      days = var.log_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket     = aws_s3_bucket.waf_logs.id
  depends_on = [aws_s3_bucket_public_access_block.waf_logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.waf_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = [data.aws_caller_identity.current.account_id]
          }
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource = aws_s3_bucket.waf_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = [data.aws_caller_identity.current.account_id]
          }
          ArnLike = {
            "aws:SourceArn" = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
          }
        }
      }
    ]
  })
}

# --- Bucket Frontend (SPA / activos estáticos) ---

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${terraform.workspace}"

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
      kms_master_key_id = aws_kms_key.shared.arn
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

# --- Bucket Documental (comprobantes SUNAT + access logs ALB) ---

resource "aws_s3_bucket" "documental" {
  bucket = "${var.project_name}-documental-${terraform.workspace}"

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
  bucket = aws_s3_bucket.documental.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared.arn
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

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket     = aws_s3_bucket.documental.id
  depends_on = [aws_kms_key.shared]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBAccessLogsLegacy"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.documental.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid    = "AllowALBDeliveryPut"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.documental.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowALBDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource = aws_s3_bucket.documental.arn
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "documental" {
  bucket = aws_s3_bucket.documental.id

  queue {
    queue_arn     = aws_sqs_queue.billing_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "facturas/"
  }

  depends_on = [aws_sqs_queue_policy.billing_queue_policy]
}

resource "aws_s3_bucket" "documental_replica" {
  provider = aws.replica
  bucket   = "${var.project_name}-documental-replica-${terraform.workspace}"

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