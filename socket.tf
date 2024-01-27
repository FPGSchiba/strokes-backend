resource "aws_apigatewayv2_api" "this" {
  name                       = "${var.prefix}-socket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "auth" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "REQUEST"
  identity_sources = ["route.request.querystring.auth"]
  name             = "cognito-authorizer"
  authorizer_uri   = module.lambda_auth.function_invoke_arn
}

# Connect
module "lambda_connect" {
  source   = "github.com/FPGSchiba/terraform-aws-lambda.git?ref=v1.0.2"
  code_dir = "${path.module}/files/connect"
  name     = "${var.prefix}-connect"
  handler  = "main.handle"
  runtime  = "python3.11"
}

resource "aws_apigatewayv2_integration" "connect" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = module.lambda_connect.function_invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
  authorization_type = "CUSTOM"
  authorizer_id = aws_apigatewayv2_authorizer.auth.id
}

resource "aws_apigatewayv2_route_response" "connect" {
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = aws_apigatewayv2_route.connect.id
  route_response_key = "$default"
}

resource "aws_lambda_permission" "connect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_connect.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.this.id}/*/*$connect"
}

# Default
module "lambda_default" {
  source   = "github.com/FPGSchiba/terraform-aws-lambda.git?ref=v1.0.2"
  code_dir = "${path.module}/files/default"
  name     = "${var.prefix}-default"
  handler  = "main.handle"
  runtime  = "python3.11"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = module.lambda_default.function_invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_apigatewayv2_route_response" "default" {
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = aws_apigatewayv2_route.default.id
  route_response_key = "$default"
}

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_default.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.this.id}/*/*$default"
}

# Disconnect
module "lambda_disconnect" {
  source   = "github.com/FPGSchiba/terraform-aws-lambda.git?ref=v1.0.2"
  code_dir = "${path.module}/files/disconnect"
  name     = "${var.prefix}-disconnect"
  handler  = "main.handle"
  runtime  = "python3.11"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"

  content_handling_strategy = "CONVERT_TO_TEXT"
  description               = "Lambda example"
  integration_method        = "POST"
  integration_uri           = module.lambda_disconnect.function_invoke_arn
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route_response" "disconnect" {
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = aws_apigatewayv2_route.disconnect.id
  route_response_key = "$default"
}

resource "aws_lambda_permission" "disconnect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_disconnect.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.this.id}/*/*$disconnect"
}

resource "aws_apigatewayv2_stage" "example" {
  api_id = aws_apigatewayv2_api.this.id
  name   = "dev"
  auto_deploy = true

  default_route_settings {
    logging_level = "INFO"
    data_trace_enabled = true
    detailed_metrics_enabled = true
    throttling_burst_limit = 10000
    throttling_rate_limit = 10000
  }

  depends_on = [
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.default,
    aws_apigatewayv2_route.disconnect
  ]
}
