variable "project_name" {
  description = "Nome base do projeto; usado em naming de recursos (ex.: ngo-tracker-dev-data)."
  type        = string
  default     = "ngo-tracker"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "O project_name deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados."
  type        = string
}

variable "environment" {
  description = "Ambiente de deploy (ex.: dev, staging, prod). Usado em tags e no path do state."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.environment))
    error_message = "O environment deve conter apenas letras minúsculas, números e hífens, iniciando com letra."
  }
}

variable "use_localstack" {
  description = "Quando true, redireciona todos os endpoints do provider AWS para o LocalStack (custo zero em desenvolvimento)."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "URL do LocalStack para Terraform/AWS CLI no host (sua máquina)."
  type        = string
  default     = "http://localhost:4566"
}

variable "localstack_lambda_endpoint" {
  description = "URL do LocalStack vista de dentro do container da Lambda. Com docker compose use http://localstack:4566; com docker run use host.docker.internal + LAMBDA_DOCKER_FLAGS."
  type        = string
  default     = "http://localstack:4566"
}
