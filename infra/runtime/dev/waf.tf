resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project_name}-web-acl-${var.env}"
  description = "Regional WAF Web ACL for the ${var.project_name} ALB in ${var.env}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  ############################################
  # Rule 1 - AWS Managed Common Rule Set
  ############################################
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

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
      metric_name                = "${var.project_name}-common-rules-${var.env}"
      sampled_requests_enabled   = true
    }
  }

  ############################################
  # Rule 2 - AWS Managed Known Bad Inputs
  ############################################
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

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
      metric_name                = "${var.project_name}-known-bad-inputs-${var.env}"
      sampled_requests_enabled   = true
    }
  }

  ############################################
  # Rule 3 - Simple IP-based rate limiting
  ############################################
  rule {
    name     = "RateLimitByIP"
    priority = 30

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit-${var.env}"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-web-acl-${var.env}"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-web-acl-${var.env}"
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}