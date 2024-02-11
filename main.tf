resource "aws_api_gateway_rest_api" "this" {
  name = "${var.prefix}-rest-api"
}

resource "aws_api_gateway_authorizer" "this" {
  name          = "${var.prefix}-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  provider_arns = [aws_cognito_user_pool.pool.arn]
  type          = "COGNITO_USER_POOLS"
}

module "ms_stroke" {
  source             = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name           = aws_api_gateway_rest_api.this.name
  code_dir           = "${path.module}/files/strokes/"
  cors_enabled       = true
  http_methods       = ["GET", "POST", "DELETE"]
  path_name          = "stroke"
  prefix             = var.prefix
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id      = aws_api_gateway_authorizer.this.id
  runtime            = "python3.11"
  handler            = "main.handle"

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}

module "ms_groups" {
  source             = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name           = aws_api_gateway_rest_api.this.name
  code_dir           = "${path.module}/files/groups/"
  cors_enabled       = true
  http_methods       = ["GET"]
  path_name          = "groups"
  prefix             = var.prefix
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id      = aws_api_gateway_authorizer.this.id
  runtime            = "python3.11"
  handler            = "main.handle"

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}

module "ms_validate" {
  source             = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name           = aws_api_gateway_rest_api.this.name
  code_dir           = "${path.module}/files/validate/"
  cors_enabled       = false
  http_methods       = ["GET"]
  path_name          = "validate"
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id      = aws_api_gateway_authorizer.this.id
  prefix             = var.prefix
  runtime            = "python3.11"
  handler            = "main.handle"

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}

resource "aws_api_gateway_resource" "group" {
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "group"
  rest_api_id = aws_api_gateway_rest_api.this.id
}

module "ms_members" {
  source             = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name           = aws_api_gateway_rest_api.this.name
  code_dir           = "${path.module}/files/members/"
  cors_enabled       = true
  http_methods       = ["DELETE", "POST"]
  path_name          = "{group-id}"
  name_overwrite     = "members"
  prefix             = var.prefix
  parent_id          = aws_api_gateway_resource.group.id
  authorization_type = "COGNITO_USER_POOLS"
  authorizer_id      = aws_api_gateway_authorizer.this.id
  runtime            = "python3.11"
  handler            = "main.handle"

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "dev"

  depends_on = [
    module.ms_groups,
    module.ms_members,
    module.ms_stroke
  ]
}
