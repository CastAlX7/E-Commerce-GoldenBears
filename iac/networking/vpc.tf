resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-flow-logs-group"
    Environment = var.environment
  }
}

resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type          = "ALL"
  log_destination_type  = "cloud-watch-logs"
  log_group_name        = aws_cloudwatch_log_group.vpc_flow_logs.name
  iam_role_arn          = aws_iam_role.vpc_flow_logs_role.arn

  tags = {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
  }
}