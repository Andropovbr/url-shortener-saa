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

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
}

variable "repository" {
  description = "ECR repository URL"
  type        = string
}

variable "image_tag" {
  description = "ECR image tag"
  type        = string
}

variable "desired_count" {
  type        = number
  description = "Number of tasks to run."
}