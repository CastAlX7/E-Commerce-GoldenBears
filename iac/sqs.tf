resource "aws_sqs_queue" "billing_dlq" {
  name                    = "${var.project_name}-billing-dlq-${terraform.workspace}"
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.project_name}-billing-dlq-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "billing_queue" {
  name                       = "${var.project_name}-billing-queue-${terraform.workspace}"
  visibility_timeout_seconds = 180
  sqs_managed_sse_enabled    = true

  tags = {
    Name        = "${var.project_name}-billing-queue-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue_redrive_policy" "billing_redrive" {
  queue_url = aws_sqs_queue.billing_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "billing_dlq_allow" {
  queue_url = aws_sqs_queue.billing_dlq.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.billing_queue.arn]
  })
}

resource "aws_sqs_queue_policy" "billing_queue_policy" {
  queue_url = aws_sqs_queue.billing_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.billing_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.orders_topic.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "inventory_dlq" {
  name                    = "${var.project_name}-inventory-dlq-${terraform.workspace}"
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.project_name}-inventory-dlq-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "inventory_queue" {
  name                       = "${var.project_name}-inventory-queue-${terraform.workspace}"
  visibility_timeout_seconds = 180
  sqs_managed_sse_enabled    = true

  tags = {
    Name        = "${var.project_name}-inventory-queue-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue_redrive_policy" "inventory_redrive" {
  queue_url = aws_sqs_queue.inventory_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.inventory_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "inventory_dlq_allow" {
  queue_url = aws_sqs_queue.inventory_dlq.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.inventory_queue.arn]
  })
}

resource "aws_sqs_queue_policy" "inventory_queue_policy" {
  queue_url = aws_sqs_queue.inventory_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSNSPublish"
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.inventory_queue.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.orders_topic.arn
        }
      }
    }]
  })
}
