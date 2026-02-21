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

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "cidr_block" {
  description = "CIDR Block"
  type        = string
}

variable "app_port" {
  description = "Port used by the workload in ECS"
  type        = number
}

variable "db_port" {
  description = "Port used by the database"
  type        = number
}