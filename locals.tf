locals {
  is_localstack = var.use_localstack

  # API Gateway v2 não está na licença free do LocalStack — só provisiona na AWS real.
  create_api_gateway = !local.is_localstack

  project_name = var.project_name
  name_prefix  = "${local.project_name}-${var.environment}"

  # Credenciais dummy aceitas pelo LocalStack; em AWS real usa a cadeia padrão (env, profile, IAM role).
  localstack_access_key = "test"
  localstack_secret_key = "test"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = local.project_name
  }
}
