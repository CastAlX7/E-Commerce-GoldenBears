resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.project_name}-zone-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_query_log" "main" {
  cloudwatch_log_group_arn = var.route53_query_log_group_arn
  zone_id                  = aws_route53_zone.main.zone_id
}

resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "${var.project_name}-ksk-${terraform.workspace}"
  status                     = "ACTIVE"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  hosted_zone_id = aws_route53_key_signing_key.main.hosted_zone_id

  depends_on = [aws_route53_key_signing_key.main]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
