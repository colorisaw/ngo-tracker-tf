data "archive_file" "lambda_api" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.build/${local.name_prefix}-lambda-api.zip"
  excludes    = ["__pycache__", "*.pyc", ".pytest_cache"]
}

resource "aws_cloudwatch_log_group" "lambda_api" {
  count = local.is_localstack ? 0 : 1

  name              = "/aws/lambda/${local.name_prefix}-api"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-logs"
  })
}

resource "aws_lambda_function" "api" {
  function_name = "${local.name_prefix}-api"
  role          = aws_iam_role.lambda_api.arn
  handler       = "handler.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_api.output_path
  source_code_hash = data.archive_file.lambda_api.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = merge(
      {
        ENVIRONMENT    = var.environment
        DYNAMODB_TABLE = aws_dynamodb_table.main.name
        S3_BUCKET      = aws_s3_bucket.app_data.bucket
      },
      local.is_localstack ? { AWS_ENDPOINT_URL = var.localstack_lambda_endpoint } : {}
    )
  }

  depends_on = [aws_cloudwatch_log_group.lambda_api]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api"
  })
}
