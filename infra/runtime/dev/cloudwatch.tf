resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}/${var.env}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs-${var.env}"
  }

}

resource "aws_cloudwatch_metric_alarm" "http_5xx_errors" {
  alarm_name          = "${var.project_name}-http_5xx-errors-${var.env}"
  alarm_description   = "Alarm when the number of 5xx errors exceeds the threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix

  }
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project_name}-high-latency-${var.env}"
  alarm_description   = "Alarm when the average response time exceeds the threshold in seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  }

}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets-${var.env}"
  alarm_description   = "Alarm when the number of unhealthy targets exceeds the threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  }

}