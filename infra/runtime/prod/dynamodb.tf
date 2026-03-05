resource "aws_dynamodb_table" "this" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"
  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "short_code"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-dynamodb-${var.env}"
  }
}