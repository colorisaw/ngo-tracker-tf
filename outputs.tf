output "environment" {
  description = "Ambiente atual (dev, staging, prod)."
  value       = var.environment
}

output "name_prefix" {
  description = "Prefixo de naming dos recursos."
  value       = local.name_prefix
}

output "s3_app_data_bucket_name" {
  description = "Bucket S3 de dados da aplicação."
  value       = aws_s3_bucket.app_data.bucket
}

output "s3_app_data_bucket_arn" {
  description = "ARN do bucket S3 de dados."
  value       = aws_s3_bucket.app_data.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB principal."
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB principal."
  value       = aws_dynamodb_table.main.arn
}

output "lambda_api_function_name" {
  description = "Nome da função Lambda da API."
  value       = aws_lambda_function.api.function_name
}

output "lambda_api_arn" {
  description = "ARN da função Lambda da API."
  value       = aws_lambda_function.api.arn
}

output "lambda_api_role_arn" {
  description = "ARN da IAM role de execução da Lambda."
  value       = aws_iam_role.lambda_api.arn
}

output "api_gateway_url" {
  description = "URL da HTTP API. String vazia no LocalStack (apigatewayv2 fora da licença free)."
  value       = try(aws_apigatewayv2_stage.default[0].invoke_url, "")
}

output "api_gateway_id" {
  description = "ID da HTTP API. String vazia no LocalStack."
  value       = try(aws_apigatewayv2_api.main[0].id, "")
}

output "api_gateway_enabled" {
  description = "true quando API Gateway foi provisionado (AWS real)."
  value       = local.create_api_gateway
}
