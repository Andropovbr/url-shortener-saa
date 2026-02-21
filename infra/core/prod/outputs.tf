output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "subnet_ids_public" {
  description = "List of public subnets ID => id (component = edge)"
  value       = [for k, v in local.subnets : aws_subnet.this[k].id if v.component == "edge"]
}

output "subnet_ids_private_app" {
  description = "List of private app subnets ID => id (component = app)"
  value       = [for k, v in local.subnets : aws_subnet.this[k].id if v.component == "app"]
}

output "subnet_ids_private_data" {
  description = "List of private data subnets ID => id (component = data)"
  value       = [for k, v in local.subnets : aws_subnet.this[k].id if v.component == "data"]
}