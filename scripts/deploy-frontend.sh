#!/usr/bin/env bash
# Build do frontend e upload para S3 + invalidação CloudFront.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f .env.aws ]; then
  set -a
  # shellcheck source=/dev/null
  source .env.aws
  set +a
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "Erro: credenciais AWS não configuradas."
  exit 1
fi

API_URL="$(./scripts/terraform-aws.sh output -raw api_gateway_url 2>/dev/null || true)"
BUCKET="$(./scripts/terraform-aws.sh output -raw s3_web_bucket_name 2>/dev/null || true)"
DIST_ID="$(./scripts/terraform-aws.sh output -raw cloudfront_distribution_id 2>/dev/null || true)"
CF_URL="$(./scripts/terraform-aws.sh output -raw cloudfront_url 2>/dev/null || true)"

if [ -z "$BUCKET" ] || [ -z "$DIST_ID" ]; then
  echo "Erro: bucket/CloudFront não provisionados."
  echo "Rode primeiro: ./scripts/terraform-aws.sh apply"
  exit 1
fi

if [ -z "$API_URL" ]; then
  echo "Erro: api_gateway_url vazio."
  exit 1
fi

# Vite exige URL sem barra final
API_URL="${API_URL%/}"

echo "→ API URL:    $API_URL"
echo "→ S3 bucket:  $BUCKET"
echo "→ CloudFront: $DIST_ID"
echo ""

echo "→ npm install + build..."
cd frontend
npm ci 2>/dev/null || npm install
VITE_API_URL="$API_URL" npm run build
cd "$ROOT"

echo "→ Upload s3://${BUCKET}/ ..."
aws s3 sync frontend/dist/ "s3://${BUCKET}/" --delete

echo "→ Invalidação CloudFront..."
INVALIDATION="$(aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text)"

echo ""
echo "=== Frontend publicado ==="
echo "URL: ${CF_URL}"
echo "Invalidation: $INVALIDATION (propagação ~1–3 min)"
