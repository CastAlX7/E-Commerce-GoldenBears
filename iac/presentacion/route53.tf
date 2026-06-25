resource "aws_route53_zone" "main" {
  name = "goldenbears.com" # inventado esto por mientras
}

# Puntero de auditoría DNS para validación estática
resource "aws_route53_query_log" "main_query_log" {
  cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:dns-prometheus-export"
  zone_id                  = aws_route53_zone.main.zone_id
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