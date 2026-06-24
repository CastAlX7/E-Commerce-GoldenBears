# Comprobantes

resource "aws_sqs_queue" "billing_dlq" {
  name = "golden-bears-billing-dlq"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "billing_queue" {
  name = "golden-bears-billing-queue"
  visibility_timeout_seconds = 180 
  sqs_managed_sse_enabled    = true
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
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.billing_queue.arn]
  })
}

data "aws_iam_policy_document" "sns_to_billing_queue" {
  statement {
    sid    = "AllowSNSPublishToBilling"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.billing_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.orders_topic.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "billing_queue_policy" {
  queue_url = aws_sqs_queue.billing_queue.id
  policy    = data.aws_iam_policy_document.sns_to_billing_queue.json
}

# Inventario

resource "aws_sqs_queue" "inventory_dlq" {
  name = "golden-bears-inventory-dlq"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "inventory_queue" {
  name = "golden-bears-inventory-queue"
  visibility_timeout_seconds = 180 
  sqs_managed_sse_enabled    = true
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
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.inventory_queue.arn]
  })
}

data "aws_iam_policy_document" "sns_to_inventory_queue" {
  statement {
    sid    = "AllowSNSPublishToInventory"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.inventory_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.orders_topic.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "inventory_queue_policy" {
  queue_url = aws_sqs_queue.inventory_queue.id
  policy    = data.aws_iam_policy_document.sns_to_inventory_queue.json
}