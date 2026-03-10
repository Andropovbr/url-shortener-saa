resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-redis-subnet-${var.env}"
  subnet_ids = data.terraform_remote_state.core.outputs.subnet_ids_private_data

}

resource "aws_elasticache_replication_group" "this" {
  description                = "Replication group for ${var.project_name} in ${var.env} environment"
  engine                     = "valkey"
  replication_group_id       = "${var.project_name}-redis-${var.env}"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 1
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [data.terraform_remote_state.core.outputs.security_group_data]
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
}