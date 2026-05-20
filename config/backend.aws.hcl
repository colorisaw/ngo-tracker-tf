# Backend remoto em AWS real (staging / produção)
# Ajuste bucket e key conforme sua conta e convenção de naming.
bucket         = "sre-terraform-state"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
use_lockfile   = true
