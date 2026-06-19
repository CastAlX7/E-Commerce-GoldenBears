resource "aws_s3_bucket" "documental" {
  bucket = "golden-bears-documental"

  tags = {
    Name        = "Bucket Documental Fiscal"
    Environment = "Dev"
    Compliance = SUNAT
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
      sse_algorithm = "AES256" 
    }
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

    # Mueve a Glacier a los 90 días para reducir costos de almacenamiento
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Sin bloque expiration — SUNAT exige retención mínima 5 años.
    # Los objetos NO se eliminan automáticamente.
  }
}