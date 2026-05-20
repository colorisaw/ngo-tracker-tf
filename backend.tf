# O bloco backend não aceita variáveis. Para LocalStack (FinOps / custo zero),
# use: terraform init -backend-config=config/backend.local.hcl
# Para AWS real: terraform init -backend-config=config/backend.aws.hcl
terraform {
  backend "s3" {
    encrypt = true
  }
}
