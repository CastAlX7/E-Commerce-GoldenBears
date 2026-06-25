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