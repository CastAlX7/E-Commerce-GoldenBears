resource "aws_cloudwatch_log_group" "lambda_inventory" {
  name              = "/aws/lambda/${var.project_name}-inventory-${terraform.workspace}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn

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
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name        = "${var.project_name}-lambda-billing-logs-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "lambda_inventario" {
  # checkov:skip=CKV_AWS_116: Las funciones Lambda de este proyecto no requieren una Dead Letter Queue (DLQ) para el manejo de fallos.
  # checkov:skip=CKV_AWS_115: El entorno Sandbox de AWS tiene un limite de concurrencia de 10, lo que impide reservar concurrencia sin violar el minimo de 10 ejecuciones no reservadas de la cuenta.
  filename         = "${path.module}/lambda_inventario.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_inventario.zip")
  function_name    = "${var.project_name}-inventory-${terraform.workspace}"
  role             = aws_iam_role.lambda_inventario.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 30

  # reserved_concurrent_executions = 10

  kms_key_arn = aws_kms_key.compute.arn

  depends_on = [
    aws_iam_role_policy.lambda_inventario,
    aws_cloudwatch_log_group.lambda_inventory
  ]

  vpc_config {
    subnet_ids         = [aws_subnet.private_lambda_a.id]
    security_group_ids = [aws_security_group.lambda_inventario.id]
  }

  environment {
    variables = {
      ENVIRONMENT            = terraform.workspace
      PROJECT_NAME           = var.project_name
      DB_HOST                = aws_db_proxy.aurora_proxy.endpoint
      DB_PORT                = "5432"
      DB_USER                = "dbadmin"
      DB_NAME                = "goldenbearsdb"
      DB_PASSWORD_SECRET_ARN = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
    }
  }

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_inventario.arn

  tags = {
    Name        = "${var.project_name}-inventory-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_inventory" {
  event_source_arn = aws_sqs_queue.inventory_queue.arn
  function_name    = aws_lambda_function.lambda_inventario.arn
  batch_size       = 10
  # El handler devuelve batchItemFailures para los registros que fallan —
  # sin esto, Lambda ignora ese campo y SQS trata todo el batch como
  # exitoso aunque haya fallado, sin reintentar ni caer al DLQ.
  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_lambda_function" "lambda_comprobantes" {
  # checkov:skip=CKV_AWS_116: Las funciones Lambda de este proyecto no requieren una Dead Letter Queue (DLQ) para el manejo de fallos.
  # checkov:skip=CKV_AWS_115: El entorno Sandbox de AWS tiene un limite de concurrencia de 10, lo que impide reservar concurrencia sin violar el minimo de 10 ejecuciones no reservadas de la cuenta.
  filename         = "${path.module}/lambda_comprobantes.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_comprobantes.zip")
  function_name    = "${var.project_name}-billing-${terraform.workspace}"
  role             = aws_iam_role.lambda_comprobantes.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 60

  # reserved_concurrent_executions = 10

  kms_key_arn = aws_kms_key.compute.arn

  depends_on = [
    aws_iam_role_policy.lambda_comprobantes,
    aws_cloudwatch_log_group.lambda_billing
  ]

  vpc_config {
    subnet_ids         = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
    security_group_ids = [aws_security_group.lambda_comprobantes.id]
  }

  environment {
    variables = {
      ENVIRONMENT            = terraform.workspace
      PROJECT_NAME           = var.project_name
      DB_HOST                = aws_db_proxy.aurora_proxy.endpoint
      DB_PORT                = "5432"
      DB_USER                = "dbadmin"
      DB_NAME                = "goldenbearsdb"
      DB_PASSWORD_SECRET_ARN = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
      GMAIL_SECRET_ARN       = aws_secretsmanager_secret.gmail_credentials.arn
    }
  }

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_comprobantes.arn

  tags = {
    Name        = "${var.project_name}-billing-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_billing" {
  event_source_arn = aws_sqs_queue.billing_queue.arn
  function_name    = aws_lambda_function.lambda_comprobantes.arn
  batch_size       = 10
  # Mismo motivo que sqs_to_lambda_inventory.
  function_response_types = ["ReportBatchItemFailures"]
}

resource "random_id" "signer_suffix" {
  byte_length = 4
}

resource "aws_signer_signing_profile" "lambda_inventario" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = replace("${var.project_name}inventory${terraform.workspace}${random_id.signer_suffix.hex}", "-", "")

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
    untrusted_artifact_on_deployment = "Warn" # Warn en lugar de Enforce para permitir placeholders en dev
  }

  description = "${var.project_name}-inventory-${terraform.workspace} code signing config"
}

resource "aws_signer_signing_profile" "lambda_comprobantes" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = replace("${var.project_name}billing${terraform.workspace}${random_id.signer_suffix.hex}", "-", "")

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
    untrusted_artifact_on_deployment = "Warn"
  }

  description = "${var.project_name}-billing-${terraform.workspace} code signing config"
}
