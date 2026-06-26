resource "aws_cloudwatch_log_group" "lambda_inventory" {
  name              = "/aws/lambda/${var.project_name}-inventory-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.shared.arn

  tags = {
    Name        = "${var.project_name}-lambda-inventory-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "lambda_billing" {
  name              = "/aws/lambda/${var.project_name}-billing-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.shared.arn

  tags = {
    Name        = "${var.project_name}-lambda-billing-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# CRÍTICO: REEMPLAZAR placeholder.zip CON EL ARTIFACT REAL DE LA LAMBDA ANTES DE APLICAR EN PRODUCCIÓN
resource "aws_lambda_function" "lambda_inventario" {
  filename                       = "${path.module}/placeholder.zip"
  function_name                  = "${var.project_name}-inventory-${terraform.workspace}"
  role                           = aws_iam_role.lambda_inventario.arn
  runtime                        = "python3.12"
  handler                        = "handler.lambda_handler"
  timeout                        = 30
  reserved_concurrent_executions = 10

  vpc_config {
    subnet_ids         = [aws_subnet.private_lambda_a.id]
    security_group_ids = [aws_security_group.lambda_inventario.id]
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.inventory_dlq.arn
  }

  environment {
    variables = {
      ENVIRONMENT  = terraform.workspace
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-inventory-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_inventory]
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_inventory" {
  event_source_arn = aws_sqs_queue.inventory_queue.arn
  function_name    = aws_lambda_function.lambda_inventario.arn
  batch_size       = 10
}

# CRÍTICO: REEMPLAZAR placeholder.zip CON EL ARTIFACT REAL DE LA LAMBDA ANTES DE APLICAR EN PRODUCCIÓN
resource "aws_lambda_function" "lambda_comprobantes" {
  filename                       = "${path.module}/placeholder.zip"
  function_name                  = "${var.project_name}-billing-${terraform.workspace}"
  role                           = aws_iam_role.lambda_comprobantes.arn
  runtime                        = "python3.12"
  handler                        = "handler.lambda_handler"
  timeout                        = 60
  reserved_concurrent_executions = 10

  # Lambda fuera de VPC: accede a NubeFact/SUNAT por Internet directamente
  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.billing_dlq.arn
  }

  environment {
    variables = {
      ENVIRONMENT  = terraform.workspace
      PROJECT_NAME = var.project_name
    }
  }

  tags = {
    Name        = "${var.project_name}-billing-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_billing]
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_billing" {
  event_source_arn = aws_sqs_queue.billing_queue.arn
  function_name    = aws_lambda_function.lambda_comprobantes.arn
  batch_size       = 10
}
