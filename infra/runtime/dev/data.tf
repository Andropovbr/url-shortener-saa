data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket = "url-shortener-saa-tfstate-shared-792025037142"
    key    = "${var.env}/core/terraform.tfstate"
    region = "us-east-1"
  }
}