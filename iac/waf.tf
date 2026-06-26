resource "aws_wafv2_web_acl" "frontend" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-frontend-waf-${terraform.workspace}"
  scope       = "CLOUDFRONT"
  description = "WAF para la distribución CloudFront del marketplace Golden Bears"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules-${terraform.workspace}"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-bad-inputs-rules-${terraform.workspace}"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-${terraform.workspace}"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-frontend-waf-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "frontend" {
  provider                = aws.us_east_1
  log_destination_configs = ["arn:aws:s3:::${var.log_bucket_name}"]
  resource_arn            = aws_wafv2_web_acl.frontend.arn
}
