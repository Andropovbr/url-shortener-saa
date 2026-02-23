project_name      = "url-shortener-saa"
env               = "dev"
container_port    = 8000
health_check_path = "/api/health/ready"
repository        = "792025037142.dkr.ecr.us-east-1.amazonaws.com"
image_tag = "v0.1.0"
desired_count = 1