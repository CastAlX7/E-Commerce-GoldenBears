output "apigw_http_endpoint" {
  value       = aws_apigatewayv2_api.apigw_http_endpoint.api_endpoint
  description = "Api Gateway Endpoint"
}

output "alb_arn" {
  value       = aws_lb.ecs_alb.arn
  description = "ARN del Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_lb.ecs_alb.dns_name
  description = "DNS del ALB"
}