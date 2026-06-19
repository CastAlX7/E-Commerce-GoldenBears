output "s3_bucket_name" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}