output "repository_name" {
  value = aws_ecr_repository.this.name
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.this.arn
}

output "github_actions_ecr_push_role_arn" {
  value = aws_iam_role.github_ecr_push.arn
}

output "github_actions_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "github_terraform_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions Terraform workflows."
  value       = aws_iam_role.github_terraform.arn
}