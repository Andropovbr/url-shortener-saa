resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_name}-public-rt-${var.env}"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = { for k, v in local.subnets : k => v if v.component == "edge" }
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

// Create a default route for the public route table to the internet gateway
resource "aws_route" "public_rt_default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.project_name}-private-rt-${var.env}"
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       = { for k, v in local.subnets : k => v if v.tier == "private" }
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private_rt.id
}