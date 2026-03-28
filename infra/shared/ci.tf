data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

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

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid    = "GitHubActionsAssumeRoleWithOIDC"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subject]
    }
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

output "github_actions_ecr_push_role_arn" {
  value = aws_iam_role.github_ecr_push.arn
}

output "github_actions_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}