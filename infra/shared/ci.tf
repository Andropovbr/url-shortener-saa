locals {
  github_repo_full_name = "${var.github_owner}/${var.github_repo}"

  github_oidc_subject = "repo:${local.github_repo_full_name}:ref:refs/heads/${var.github_branch}"

  ecr_push_role_name = "${var.project_name}-github-ecr-push-role"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

resource "aws_iam_role" "github_ecr_push" {
  name               = local.ecr_push_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json

  tags = {
    Name = local.ecr_push_role_name
  }
}

resource "aws_iam_role_policy" "github_ecr_push" {
  name   = "${var.project_name}-github-ecr-push-policy"
  role   = aws_iam_role.github_ecr_push.id
  policy = data.aws_iam_policy_document.github_ecr_push.json
}

resource "aws_iam_role" "github_terraform" {
  name               = "${var.project_name}-github-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role_terraform.json

  tags = {
    Project   = var.project_name
    Owner     = "Andre Santos"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "github_terraform_backend" {
  name   = "${var.project_name}-github-terraform-backend-policy"
  policy = data.aws_iam_policy_document.github_terraform_backend.json
}

resource "aws_iam_role_policy_attachment" "github_terraform_backend" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = aws_iam_policy.github_terraform_backend.arn
}

resource "aws_iam_policy" "github_terraform_workflows" {
  name   = "${var.project_name}-github-terraform-workflows-policy"
  policy = data.aws_iam_policy_document.github_terraform_workflows.json
}

resource "aws_iam_role_policy_attachment" "github_terraform_workflows" {
  role       = aws_iam_role.github_terraform.name
  policy_arn = aws_iam_policy.github_terraform_workflows.arn
}