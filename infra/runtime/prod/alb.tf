resource "aws_lb" "this" {
  name               = "${var.project_name}-alb-${var.env}"
  internal           = false
  security_groups    = [data.terraform_remote_state.core.outputs.security_group_alb]
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.core.outputs.subnet_ids_public

  tags = {
    Name = "${var.project_name}-alb-${var.env}"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-tg-${var.env}"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg-${var.env}"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
