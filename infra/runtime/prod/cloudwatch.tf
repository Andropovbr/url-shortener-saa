resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}/${var.env}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs-${var.env}"
  }

}