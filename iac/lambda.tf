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
  kms_key_arn                    = aws_kms_key.shared.arn

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

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_inventario.arn

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

  vpc_config {
    subnet_ids         = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
    security_group_ids = [aws_security_group.lambda_comprobantes.id]
  }
  
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

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_comprobantes.arn

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

# Nueva config - Perfil de firma con AWS Signer
resource "aws_signer_signing_profile" "lambda_inventario" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = replace("${var.project_name}inventory${terraform.workspace}", "-", "")

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = {
    Name        = "${var.project_name}-inventory-signing-profile-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Configuración de firma de código
resource "aws_lambda_code_signing_config" "lambda_inventario" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_inventario.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"  # Bloquea despliegues no firmados o alterados
  }

  description = "${var.project_name}-inventory-${terraform.workspace} code signing config"
}

# Perfil de firma para lambda_comprobantes
resource "aws_signer_signing_profile" "lambda_comprobantes" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = replace("${var.project_name}billing${terraform.workspace}", "-", "")

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = {
    Name        = "${var.project_name}-billing-signing-profile-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Configuración de firma de código para lambda_comprobantes
resource "aws_lambda_code_signing_config" "lambda_comprobantes" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_comprobantes.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

  description = "${var.project_name}-billing-${terraform.workspace} code signing config"
}