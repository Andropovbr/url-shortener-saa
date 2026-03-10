resource "aws_secretsmanager_secret" "redis_auth_token" {
  name = "${var.project_name}-${var.env}"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = random_password.redis_auth_token.result
}