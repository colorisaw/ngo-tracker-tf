locals {
  is_localstack = var.use_localstack

  create_api_gateway = !local.is_localstack

  create_frontend_hosting = !local.is_localstack

  project_name = var.project_name
  name_prefix  = "${local.project_name}-${var.environment}"

  localstack_access_key = "test"
  localstack_secret_key = "test"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = local.project_name
  }
}
