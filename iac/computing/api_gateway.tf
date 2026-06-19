# Create Api Gateway HTTP endpoint. 
resource "aws_apigatewayv2_api" "apigw_http_endpoint" {
  name          = "monolito-api"
  protocol_type = "HTTP"
}