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
  description = "URL base do LocalStack. Altere apenas se o serviço rodar em outro host/porta."
  type        = string
  default     = "http://localhost:4566"
}
