#!/usr/bin/env bash
# Cria o bucket S3 de state remoto na AWS real (idempotente).
set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Erro: credenciais AWS não configuradas."
  echo "Configure com: aws configure   ou   aws login"
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
# Nomes S3 são globais — sre-terraform-state pode pertencer a outra conta (403 no console)
BUCKET="${TF_STATE_BUCKET:-sre-terraform-state-${ACCOUNT}}"
echo "→ Conta AWS: $ACCOUNT"
echo "→ Região:    $REGION"
echo "→ Bucket:    $BUCKET"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "✓ Bucket $BUCKET já existe"
else
  echo "→ Criando bucket..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration "LocationConstraint=$REGION"
  fi
  echo "✓ Bucket criado"
fi

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "✓ Versioning e block public access habilitados"
echo ""
echo "Próximo passo:"
echo "  terraform init -reconfigure -backend-config=config/backend.aws.hcl -backend-config=\"bucket=${BUCKET}\""
