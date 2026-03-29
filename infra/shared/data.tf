data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "github_ecr_push" {
  statement {
    sid    = "AllowGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPushToSharedRepository"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      aws_ecr_repository.this.arn
    ]
  }

  statement {
    sid    = "AllowECSDevDeployment"
    effect = "Allow"

    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPassECSRolesForDevDeployment"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ecs-task-execution-role-dev",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ecs-task-execution-role-prod",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-app-task-role-dev",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-app-task-role-prod"
    ]
  }
}

data "terraform_remote_state" "runtime_dev" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = var.runtime_dev_state_key
    region = var.aws_region
  }
}

data "terraform_remote_state" "runtime_prod" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = var.runtime_prod_state_key
    region = var.aws_region
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
      values = [
        "repo:Andropovbr/url-shortener-saa:ref:refs/heads/main",
        "repo:Andropovbr/url-shortener-saa:environment:production"
      ]
    }
  }
}

data "aws_iam_policy_document" "github_oidc_assume_role_terraform" {
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
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:environment:production"
      ]
    }
  }
}

data "aws_iam_policy_document" "github_terraform_backend" {
  statement {
    sid    = "AllowReadWriteTerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.project_name}-terraform-state"
    ]
  }

  statement {
    sid    = "AllowReadWriteTerraformStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${var.project_name}-terraform-state/*"
    ]
  }

  statement {
    sid    = "AllowTerraformLockTable"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-terraform-locks"
    ]
  }
}

data "aws_iam_policy_document" "github_terraform_workflows" {
  statement {
    sid    = "AllowTerraformReadAcrossServices"
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "dynamodb:Describe*",
      "dynamodb:List*",
      "elasticache:Describe*",
      "elasticache:ListTagsForResource",
      "wafv2:Get*",
      "wafv2:List*",
      "logs:Describe*",
      "logs:Get*",
      "logs:List*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "secretsmanager:Describe*",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:List*",
      "iam:Get*",
      "iam:List*",
      "iam:PassRole",
      "acm:Describe*",
      "acm:List*",
      "route53:Get*",
      "route53:List*",
      "ecr:Describe*",
      "ecr:List*",
      "ecr:GetRepositoryPolicy",
      "application-autoscaling:Describe*",
      "autoscaling:Describe*",
      "tag:GetResources"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformWriteAcrossServices"
    effect = "Allow"

    actions = [
      "ec2:Create*",
      "ec2:Modify*",
      "ec2:Delete*",
      "ec2:Associate*",
      "ec2:Disassociate*",
      "ec2:Attach*",
      "ec2:Detach*",
      "ec2:AuthorizeSecurityGroup*",
      "ec2:RevokeSecurityGroup*",
      "elasticloadbalancing:Create*",
      "elasticloadbalancing:Modify*",
      "elasticloadbalancing:Delete*",
      "elasticloadbalancing:Add*",
      "elasticloadbalancing:Remove*",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "ecs:Create*",
      "ecs:Update*",
      "ecs:Delete*",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "dynamodb:Create*",
      "dynamodb:Update*",
      "dynamodb:Delete*",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "elasticache:Create*",
      "elasticache:Modify*",
      "elasticache:Delete*",
      "elasticache:AddTagsToResource",
      "elasticache:RemoveTagsFromResource",
      "wafv2:Create*",
      "wafv2:Update*",
      "wafv2:Delete*",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "logs:Create*",
      "logs:PutRetentionPolicy",
      "logs:Delete*",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "secretsmanager:Create*",
      "secretsmanager:Update*",
      "secretsmanager:Delete*",
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "acm:AddTagsToCertificate",
      "acm:RemoveTagsFromCertificate",
      "route53:ChangeResourceRecordSets",
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone",
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:TagResource",
      "application-autoscaling:UntagResource"
    ]

    resources = ["*"]
  }
}

