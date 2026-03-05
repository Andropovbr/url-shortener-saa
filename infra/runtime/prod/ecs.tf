resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster-${var.env}"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task-${var.env}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.app_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.repository}/${var.project_name}-${var.env}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}/${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "DDB_TABLE_NAME"
          value = var.dynamodb_table_name
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service-${var.env}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 90

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = data.terraform_remote_state.core.outputs.subnet_ids_private_app
    security_groups  = [data.terraform_remote_state.core.outputs.security_group_app]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_service" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"

  # IMPORTANT: format is service/<cluster-name>/<service-name>
  resource_id = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"

  min_capacity = var.min_capacity
  max_capacity = var.max_capacity
}

resource "aws_appautoscaling_policy" "ecs_req_per_target" {
  name               = "${var.project_name}-as-policy-${var.env}"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"

      # resource_label must be "<lb_arn_suffix>/<tg_arn_suffix>"
      resource_label = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.this.arn_suffix}"
    }

    target_value       = var.target_requests_per_target
    scale_in_cooldown  = 120
    scale_out_cooldown = 30
    disable_scale_in   = false
  }
}