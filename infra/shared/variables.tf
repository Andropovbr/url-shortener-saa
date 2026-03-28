variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "main"
}


variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}
variable "runtime_dev_state_key" {
  type = string
}

variable "runtime_prod_state_key" {
  type = string
}