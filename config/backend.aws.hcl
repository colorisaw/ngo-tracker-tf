# Backend remoto em AWS real (staging / produção)
# Ajuste bucket, key e dynamodb_table conforme sua conta e convenção de naming.
bucket         = "sre-terraform-state"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "sre-terraform-state-lock"
