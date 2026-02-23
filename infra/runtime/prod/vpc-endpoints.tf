locals {
  vpc_endpoints = {
    ecr-api = {
      service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
      vpc_endpoint_type = "Interface"
      subnet_ids        = data.terraform_remote_state.core.outputs.subnet_ids_private_app
      security_group_ids = [
        data.terraform_remote_state.core.outputs.security_group_vpce
      ]
      private_dns_enabled = true
    }
    ecr-dkr = {
      service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
      vpc_endpoint_type = "Interface"
      subnet_ids        = data.terraform_remote_state.core.outputs.subnet_ids_private_app
      security_group_ids = [
        data.terraform_remote_state.core.outputs.security_group_vpce
      ]
      private_dns_enabled = true
    }
    logs = {
      service_name      = "com.amazonaws.${var.aws_region}.logs"
      vpc_endpoint_type = "Interface"
      subnet_ids        = data.terraform_remote_state.core.outputs.subnet_ids_private_app
      security_group_ids = [
        data.terraform_remote_state.core.outputs.security_group_vpce
      ]
      private_dns_enabled = true
    }
    sts = {
      service_name      = "com.amazonaws.${var.aws_region}.sts"
      vpc_endpoint_type = "Interface"
      subnet_ids        = data.terraform_remote_state.core.outputs.subnet_ids_private_app
      security_group_ids = [
        data.terraform_remote_state.core.outputs.security_group_vpce
      ]
      private_dns_enabled = true
    }
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.vpc_endpoints

  vpc_id              = data.terraform_remote_state.core.outputs.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  subnet_ids          = each.value.subnet_ids
  security_group_ids  = each.value.security_group_ids
  private_dns_enabled = each.value.private_dns_enabled

  tags = {
    Name = "${var.project_name}-vpce-${each.key}-${var.env}"
  }
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = data.terraform_remote_state.core.outputs.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.terraform_remote_state.core.outputs.route_table_private]

  tags = {
    Name = "${var.project_name}-vpce-s3-gateway-${var.env}"
  }
}