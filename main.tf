resource "aws_api_gateway_rest_api" "this" {
  name = "${var.prefix}-api"
}

module "test" {
  source = "github.com/FPGSchiba/terraform-aws-microservice.git?ref=v1.0.1"
  api_name = aws_api_gateway_rest_api.this.name
  code_dir = ""
  cors_enabled = false
  http_methods = []
  path_name = ""
  prefix = ""

  depends_on = [
    aws_api_gateway_rest_api.this
  ]
}