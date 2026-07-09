resource "aws_sns_topic" "orders_topic" {
  name              = "${var.project_name}-orders-topic-${terraform.workspace}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.project_name}-orders-topic-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "sns_to_sqs_inventory" {
  topic_arn            = aws_sns_topic.orders_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.inventory_queue.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "sns_to_sqs_billing" {
  topic_arn            = aws_sns_topic.orders_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.billing_queue.arn
  raw_message_delivery = true
}
