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