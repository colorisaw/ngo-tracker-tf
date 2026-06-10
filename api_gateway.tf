# HTTP API (API Gateway v2) — apenas na AWS real.
# LocalStack free: apigatewayv2 exige licença paga. Em dev local, use `aws lambda invoke`.
resource "aws_apigatewayv2_api" "main" {
  count = local.create_api_gateway ? 1 : 0

  name          = "${local.name_prefix}-http-api"
  protocol_type = "HTTP"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-http-api"
  })
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = local.create_api_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.main[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "proxy" {
  count = local.create_api_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_apigatewayv2_route" "root" {
  count = local.create_api_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_apigatewayv2_stage" "default" {
  count = local.create_api_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.main[0].id
  name        = var.environment
  auto_deploy = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-http-api-${var.environment}"
  })
}

resource "aws_lambda_permission" "api_gateway" {
  count = local.create_api_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}
