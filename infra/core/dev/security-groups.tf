resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.env}"
  description = "Security group for ALB in edge tier"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-alb-sg-${var.env}"
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg-${var.env}"
  description = "Security group for app in app tier"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-app-sg-${var.env}"
  }
}

resource "aws_security_group" "data_sg" {
  name        = "${var.project_name}-data-sg-${var.env}"
  description = "Security group for database in data tier"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-data-sg-${var.env}"
  }
}

resource "aws_security_group" "vpce_sg" {
  name        = "${var.project_name}-vpce-sg-${var.env}"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-vpce-sg-${var.env}"
  }
}

resource "aws_security_group_rule" "alb_to_app" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_to_app_egress" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_to_data" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.data_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_to_redis" {
  type                     = "ingress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.data_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_to_data_egress" {
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.data_sg.id
}

resource "aws_security_group_rule" "app_to_vpce_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.vpce_sg.id
}

//The rule below allows the app to access S3 via the VPC endpoint, which is necessary for ECS task execution role to pull images and send logs to CloudWatch
resource "aws_security_group_rule" "app_to_s3_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app_sg.id
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
}

resource "aws_security_group_rule" "internet_to_alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "internet_to_alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_to_vpce" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpce_sg.id
  source_security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "app_egress_dynamodb_443" {
  type              = "egress"
  security_group_id = aws_security_group.app_sg.id

  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  prefix_list_ids = [data.aws_prefix_list.dynamodb.id]

  description = "Allow HTTPS egress to DynamoDB via prefix list (no NAT)"
}

