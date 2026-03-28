output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "redis_primary_endpoint_address" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "app_task_role_arn" {
  value = aws_iam_role.app_task_role.arn
}