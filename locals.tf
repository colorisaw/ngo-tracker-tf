locals {
  is_localstack = var.use_localstack

  # Credenciais dummy aceitas pelo LocalStack; em AWS real usa a cadeia padrão (env, profile, IAM role).
  localstack_access_key = "test"
  localstack_secret_key = "test"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "sre-terraform"
  }
}
