data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Log Groups — CloudWatch Logs
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda_inventory_logs" {
  name              = "/aws/lambda/${var.project_name}-inventory"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_billing_logs" {
  name              = "/aws/lambda/${var.project_name}-billing"
  retention_in_days = 365
}

# ---------------------------------------------------------------------------
# Lambda Inventario — dentro de VPC (Private Lambda Subnet 10.0.40.0/24)
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "lambda_inventario" {
  filename      = "${path.module}/placeholder.zip"
  function_name = "${var.project_name}-inventory"
  role          = aws_iam_role.rol_lambda_inventario.arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  timeout       = 30

  reserved_concurrent_executions = 10

  vpc_config {
    subnet_ids         = [var.private_lambda_subnet_id]
    security_group_ids = [var.lambda_inv_sg_id]
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.inventory_dlq.arn
  }

  depends_on = [aws_cloudwatch_log_group.lambda_inventory_logs]
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_inventory" {
  event_source_arn = aws_sqs_queue.inventory_queue.arn
  function_name    = aws_lambda_function.lambda_inventario.arn
  batch_size       = 10
}

resource "aws_iam_role" "rol_lambda_inventario" {
  name = "${var.project_name}-lambda-inventory-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "permisos_lambda_inventario" {
  name = "${var.project_name}-lambda-inventory-permissions"
  role = aws_iam_role.rol_lambda_inventario.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaVPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConsumeSQSInventory"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.inventory_queue.arn
      },
      {
        Sid      = "RDSProxyIAMAuth"
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${var.rds_proxy_resource_id}/inventory_user"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-inventory*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Lambda Facturación — fuera de VPC (accede a NubeFact/SUNAT por Internet)
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "lambda_comprobantes" {
  filename      = "${path.module}/placeholder.zip"
  function_name = "${var.project_name}-billing"
  role          = aws_iam_role.rol_lambda_comprobantes.arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  timeout       = 60

  reserved_concurrent_executions = 10

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.billing_dlq.arn
  }

  depends_on = [aws_cloudwatch_log_group.lambda_billing_logs]
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda_billing" {
  event_source_arn = aws_sqs_queue.billing_queue.arn
  function_name    = aws_lambda_function.lambda_comprobantes.arn
  batch_size       = 10
}

resource "aws_iam_role" "rol_lambda_comprobantes" {
  name = "${var.project_name}-lambda-billing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "permisos_lambda_comprobantes" {
  name = "${var.project_name}-lambda-billing-permissions"
  role = aws_iam_role.rol_lambda_comprobantes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConsumeSQSBilling"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.billing_queue.arn
      },
      {
        Sid    = "S3DocumentalStorage"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.documental.arn}/facturas/*"
      },
      {
        Sid      = "ReadNubefactCredentials"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.nubefact_secret_arn
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-billing*"
      }
    ]
  })
}
