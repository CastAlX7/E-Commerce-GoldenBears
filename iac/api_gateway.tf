resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api-${terraform.workspace}"
  protocol_type = "HTTP"

  tags = {
    Name        = "${var.project_name}-api-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-vpclink-${terraform.workspace}"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = [aws_subnet.private_ingress_a.id, aws_subnet.private_ingress_b.id]

  tags = {
    Name        = "${var.project_name}-vpclink-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_apigatewayv2_integration" "main" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.main.arn
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.main.id
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "main" {
  # checkov:skip=CKV_AWS_309: La autenticación y autorización se manejan internamente en los contenedores ECS.
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "apigw_access_logs" {
  name              = "/aws/apigateway/${var.project_name}-access-logs-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.shared.arn

  tags = {
    Name        = "${var.project_name}-apigw-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access_logs.arn
    format = jsonencode({
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

  tags = {
    Name        = "${var.project_name}-apigw-stage-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
