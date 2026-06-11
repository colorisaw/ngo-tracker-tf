#!/usr/bin/env bash
# Roda terraform na AWS carregando credenciais de .env.aws (exportadas ao processo filho).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Remove credenciais dummy do LocalStack
if [ "${AWS_ACCESS_KEY_ID:-}" = "test" ]; then unset AWS_ACCESS_KEY_ID; fi
if [ "${AWS_SECRET_ACCESS_KEY:-}" = "test" ]; then unset AWS_SECRET_ACCESS_KEY; fi
unset AWS_ENDPOINT_URL 2>/dev/null || true

if [ -f .env.aws ]; then
  set -a
  # shellcheck source=/dev/null
  source .env.aws
  set +a
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Erro: credenciais AWS indisponíveis para o Terraform."
  echo ""
  echo "Use uma das opções:"
  echo "  ./scripts/terraform-aws.sh apply"
  echo "  set -a && source .env.aws && set +a && terraform apply"
  echo "  aws configure"
  exit 1
fi

exec terraform "$@"
