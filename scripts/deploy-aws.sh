#!/usr/bin/env bash
# Deploy NGO Tracker na AWS real (use_localstack = false).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Credenciais locais opcionais (gitignored) — veja .env.aws.example
if [ -f .env.aws ]; then
  set -a
  # shellcheck source=/dev/null
  source .env.aws
  set +a
fi

# Remove só credenciais dummy do LocalStack; preserva keys reais e ~/.aws/credentials
if [ "${AWS_ACCESS_KEY_ID:-}" = "test" ]; then unset AWS_ACCESS_KEY_ID; fi
if [ "${AWS_SECRET_ACCESS_KEY:-}" = "test" ]; then unset AWS_SECRET_ACCESS_KEY; fi
unset AWS_ENDPOINT_URL 2>/dev/null || true

echo "=== NGO Tracker — deploy AWS ==="
echo ""

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Erro: credenciais AWS não configuradas."
  echo ""
  echo "Opções (nunca commite credenciais):"
  echo "  aws configure          # salva em ~/.aws/credentials (recomendado)"
  echo "  aws login              # SSO / IAM Identity Center"
  echo "  cp .env.aws.example .env.aws   # variáveis locais gitignored"
  echo ""
  exit 1
fi

aws sts get-caller-identity
echo ""

if [ ! -f terraform.tfvars ]; then
  echo "Erro: terraform.tfvars não encontrado."
  echo "Copie terraform.tfvars.example e ajuste use_localstack = false"
  exit 1
fi

if grep -q 'use_localstack[[:space:]]*=[[:space:]]*true' terraform.tfvars; then
  echo "Aviso: terraform.tfvars ainda tem use_localstack = true"
  echo "Altere para use_localstack = false antes do deploy AWS."
  echo ""
  read -r -p "Continuar mesmo assim? [y/N] " ans
  [[ "${ans,,}" == "y" ]] || exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
TF_STATE_BUCKET="${TF_STATE_BUCKET:-sre-terraform-state-${ACCOUNT}}"
export TF_STATE_BUCKET

echo "→ Bootstrap bucket de state ($TF_STATE_BUCKET)..."
./scripts/bootstrap-aws-state.sh
echo ""

echo "→ terraform init (backend AWS)..."
terraform init -reconfigure \
  -backend-config=config/backend.aws.hcl \
  -backend-config="bucket=${TF_STATE_BUCKET}"
echo ""

echo "→ terraform plan..."
terraform plan -out=tfplan-aws
echo ""

read -r -p "Aplicar na AWS real? Isso gera custo. [y/N] " confirm
if [[ "${confirm,,}" != "y" ]]; then
  echo "Plan salvo em tfplan-aws. Rode: terraform apply tfplan-aws"
  exit 0
fi

terraform apply tfplan-aws
rm -f tfplan-aws

echo ""
echo "=== Deploy concluído ==="
terraform output api_gateway_url
terraform output api_gateway_enabled
echo ""
echo "Teste: curl -s \"\$(terraform output -raw api_gateway_url)/\""
echo "Postman: cole api_gateway_url em base_url (docs/POSTMAN.md)"
