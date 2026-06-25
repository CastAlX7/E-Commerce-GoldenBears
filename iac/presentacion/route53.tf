resource "aws_route53_zone" "main" {
  name = "goldenbears.com" # inventado esto por mientras
}

# Puntero de auditoría DNS para validación estática
resource "aws_route53_query_log" "main_query_log" {
  cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:dns-prometheus-export"
  zone_id                  = aws_route53_zone.main.zone_id
}

resource "aws_kms_key" "dnssec_key" {
  description              = "KMS para Route53 DNSSEC"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "route53.amazonaws.com" }
        Action = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_route53_key_signing_key" "main_ksk" {
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec_key.arn
  name                       = "goldenbears-ksk"
  status                     = "ACTIVE"
}

resource "aws_route53_hosted_zone_dnssec" "main_dnssec" {
  depends_on     = [aws_route53_key_signing_key.main_ksk]
  hosted_zone_id = aws_route53_key_signing_key.main_ksk.hosted_zone_id
}

resource "aws_route53_record" "frontend_dns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.goldenbears.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}