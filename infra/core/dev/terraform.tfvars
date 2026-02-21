project_name = "url-shortener-saa"
env        = "dev"
vpc_name   = "${var.project_name}-vpc-${var.env}"
cidr_block = "10.0.0.0/16"