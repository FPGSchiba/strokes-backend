resource "aws_dynamodb_table" "strokes" {
  hash_key     = "groupID"
  name         = var.prefix
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "groupID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "connections" {
  hash_key     = "connectionID"
  name         = "${var.prefix}-connection"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "connectionID"
    type = "S"
  }
}