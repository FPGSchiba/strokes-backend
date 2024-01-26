resource "aws_api_gateway_rest_api" "this" {
  name = "${var.prefix}-api"
}

resource "aws_api_gateway_authorizer" "this" {
  name        = "${var.prefix}-authorizer"
  rest_api_id = aws_api_gateway_rest_api.this.id
  provider_arns = [aws_cognito_user_pool.pool.arn]
  type = "COGNITO_USER_POOLS"
}

module "test" {
  source = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name = aws_api_gateway_rest_api.this.name
  code_dir = "${path.module}/files/strokes"
  cors_enabled = false
  http_methods = ["GET", "POST", "DELETE"]
  path_name = "stroke"
  prefix = var.prefix
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.this.id
  runtime = "python3.11"
  handler = "main.handle"

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name = "dev"
}
