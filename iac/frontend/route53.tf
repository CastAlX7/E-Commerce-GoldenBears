resource "aws_route53_zone" "main" {
  name = "goldenbears.com" # inventado esto por mientras
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