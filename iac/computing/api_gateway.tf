# Create Api Gateway HTTP endpoint. 
resource "aws_apigatewayv2_api" "apigw_http_endpoint" {
  name          = "monolito-api"
  protocol_type = "HTTP"
}

# Configuracion para VPC
resource "aws_apigatewayv2_vpc_link" "vpclink_apigw_to_alb" {
  name               = "vpclink_apigw_to_alb"
  security_group_ids = [var.vpc_link_sg_id]
  subnet_ids         = var.private_subnets
}

#Integracion con vpc link y ALB
resource "aws_apigatewayv2_integration" "apigw_integration" {
  api_id            = aws_apigatewayv2_api.apigw_http_endpoint.id
  integration_type  = "HTTP_PROXY"
  integration_uri   = aws_lb_listener.front_end.arn

  integration_method        = "ANY"
  connection_type           = "VPC_LINK"
  connection_id             = aws_apigatewayv2_vpc_link.vpclink_apigw_to_alb.id
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version    = "1.0"
  depends_on                = [aws_apigatewayv2_vpc_link.vpclink_apigw_to_alb,
                                aws_apigatewayv2_api.apigw_http_endpoint,
                                aws_lb_listener.front_end]
}

resource "aws_apigatewayv2_route" "apigw_route" {
  api_id    = aws_apigatewayv2_api.apigw_http_endpoint.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.apigw_integration.id}"

  authorization_type = "NONE"

  depends_on = [aws_apigatewayv2_integration.apigw_integration]
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/${var.project_name}-access-logs"
  retention_in_days = 365
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  api_id      = aws_apigatewayv2_api.apigw_http_endpoint.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_apigatewayv2_api.apigw_http_endpoint]

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    
    format          = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}