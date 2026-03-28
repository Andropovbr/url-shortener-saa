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
      data.terraform_remote_state.runtime_dev.outputs.ecs_task_execution_role_arn,
      data.terraform_remote_state.runtime_dev.outputs.app_task_role_arn,
      data.terraform_remote_state.runtime_prod.outputs.ecs_task_execution_role_arn,
      data.terraform_remote_state.runtime_prod.outputs.app_task_role_arn
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