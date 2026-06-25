resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "frontend_public_block" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration { status = "Enabled" }
}

# Access Logging 
resource "aws_s3_bucket_logging" "frontend_logging" {
  bucket        = aws_s3_bucket.frontend.id
  target_bucket = var.log_bucket_name
  target_prefix = "log/"
}

# Encriptación KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "frontend_lifecycle" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Event notifications
resource "aws_s3_bucket_notification" "frontend_notifications" {
  bucket = aws_s3_bucket.frontend.id
  queue {
    queue_arn = var.event_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Cross-region replication
resource "aws_s3_bucket_replication_configuration" "frontend_replication" {
  depends_on = [aws_s3_bucket_versioning.frontend_versioning]
  role       = var.replication_role_arn
  bucket     = aws_s3_bucket.frontend.id
  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket        = var.replica_bucket_arn
      storage_class = "STANDARD"
    }
  }
}