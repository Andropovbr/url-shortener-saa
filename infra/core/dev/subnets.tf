data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = data.aws_availability_zones.available.names

  subnets = {
    public-a = {
      cidr_block              = "10.0.0.0/24"
      az_index                = 0
      tier                    = "public"
      component               = "edge"
      map_public_ip_on_launch = true
    }
    public-b = {
      cidr_block              = "10.0.1.0/24"
      az_index                = 1
      tier                    = "public"
      component               = "edge"
      map_public_ip_on_launch = true
    }
    private-app-a = {
      cidr_block              = "10.0.10.0/24"
      az_index                = 0
      tier                    = "private"
      component               = "app"
      map_public_ip_on_launch = false
    }
    private-app-b = {
      cidr_block              = "10.0.11.0/24"
      az_index                = 1
      tier                    = "private"
      component               = "app"
      map_public_ip_on_launch = false
    }
    private-data-a = {
      cidr_block              = "10.0.20.0/24"
      az_index                = 0
      tier                    = "private"
      component               = "data"
      map_public_ip_on_launch = false
    }
    private-data-b = {
      cidr_block              = "10.0.21.0/24"
      az_index                = 1
      tier                    = "private"
      component               = "data"
      map_public_ip_on_launch = false
    }
  }
}

resource "aws_subnet" "this" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = local.availability_zones[each.value.az_index]
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  tags = {
    Name      = "${var.project_name}-subnet-${each.key}-${var.env}"
    Tier      = each.value.tier
    Component = each.value.component
    AZ        = local.availability_zones[each.value.az_index]
  }
}
