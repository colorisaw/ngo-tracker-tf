# Backend remoto em AWS real (staging / produção)
# bucket: passado no init (nome global S3 — use sre-terraform-state-<ACCOUNT_ID>)
#   terraform init -backend-config=config/backend.aws.hcl -backend-config="bucket=sre-terraform-state-123456789012"
# Ou use ./scripts/deploy-aws.sh (define o bucket automaticamente).
key          = "dev/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
