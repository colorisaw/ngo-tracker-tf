#!/usr/bin/env bash
# Bootstrap do bucket S3 de state no LocalStack
set -euo pipefail

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
BUCKET="${TF_STATE_BUCKET:-sre-terraform-state-local}"

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="$REGION"

echo "→ Endpoint: $ENDPOINT"
echo "→ Bucket:   $BUCKET"

if ! curl -sf "${ENDPOINT}/_localstack/health" >/dev/null; then
  echo "Erro: LocalStack não responde em $ENDPOINT"
  echo "Suba com: docker compose up -d  (ou docker start localstack)"
  exit 1
fi

aws s3 mb "s3://${BUCKET}" --endpoint-url="$ENDPOINT" 2>/dev/null || true

if aws s3 ls "s3://${BUCKET}" --endpoint-url="$ENDPOINT" >/dev/null; then
  echo "✓ Bucket $BUCKET pronto"
else
  echo "Erro: não foi possível confirmar o bucket $BUCKET",
  echo "Verifique se o bucket existe e se tem permissões para acesso"
  echo "Consulte a documentação para mais detalhes > docs/RODAR_LOCALMENTE.md"
  exit 1
fi
