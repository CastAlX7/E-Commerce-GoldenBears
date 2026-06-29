resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name        = "${var.project_name}-zone-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "route53_query_logs" {
  provider          = aws.us_east_1
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.shared.arn

  tags = {
    Name        = "${var.project_name}-route53-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_logs" {
  provider    = aws.us_east_1
  policy_name = "${var.project_name}-route53-logs-policy-${terraform.workspace}"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "route53.amazonaws.com"
      }
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.route53_query_logs.arn}:*"
    }]
  })
}

resource "aws_route53_query_log" "main" {
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_logs.arn
  zone_id                  = aws_route53_zone.main.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_logs]
}


resource "aws_route53_key_signing_key" "main" {
  count                      = var.enable_dnssec ? 1 : 0
  hosted_zone_id             = aws_route53_zone.main.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "${var.project_name}-ksk-${terraform.workspace}"
  status                     = "ACTIVE"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  count          = var.enable_dnssec ? 1 : 0
  hosted_zone_id = aws_route53_key_signing_key.main[0].hosted_zone_id

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