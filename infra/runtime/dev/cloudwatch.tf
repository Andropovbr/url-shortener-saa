resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}/${var.env}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs-${var.env}"
  }

}

resource "aws_cloudwatch_metric_alarm" "5xx_errors" {
  alarm_name          = "${var.project_name}-5xx-errors-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.this.arn_suffix
  
  }
}