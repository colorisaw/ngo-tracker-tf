# Operação e qualidade

Passo a passo para CI, automação local com Docker Compose, API Gateway e preparação para AWS real.

> Pré-requisito: [Fase 3 concluída](CHECKLIST.md) (`terraform apply` validado no LocalStack).

---

## Índice

1. [Visão geral](#visão-geral)
2. [Passo 1 - Docker Compose + persistência](#passo-1--docker-compose--persistência)
3. [Passo 2 - Script de bootstrap](#passo-2--script-de-bootstrap)
4. [Passo 3 - API Gateway (HTTP)](#passo-3--api-gateway-http)
5. [Passo 4 - CI no GitHub Actions](#passo-4--ci-no-github-actions)
6. [Passo 5 - AWS real (quando for deploy)](#passo-5--aws-real-quando-for-deploy)
7. [Validação da Fase 4](#validação-da-fase-4)
8. [Troubleshooting](#troubleshooting)

---

## Visão geral

| Entrega | Arquivo | Objetivo |
|---------|---------|----------|
| Docker Compose | `docker-compose.yml` | Subir LocalStack com 1 comando, socket Docker e persistência |
| Bootstrap | `scripts/bootstrap-localstack.sh` | Criar bucket de state automaticamente |
| API Gateway | `api_gateway.tf` | Expor Lambda via HTTP |
| CI | `.github/workflows/terraform-ci.yml` | `fmt`, `validate`, `plan` em PRs |

```
┌─────────────┐     ┌──────────────┐     ┌─────────┐
│ GitHub PR   │────▶│ Terraform CI │────▶│ plan OK │
└─────────────┘     └──────────────┘     └─────────┘

┌──────────┐     ┌─────────────┐     ┌────────┐     ┌──────────┐
│  curl    │────▶│ API Gateway │────▶│ Lambda │────▶│ DynamoDB │
└──────────┘     └─────────────┘     └────────┘     └──────────┘
```

---

## Passo 1 - Docker Compose + persistência

Substitui o `docker run` manual por compose (volume `localstack-data` + `PERSISTENCE=1`).

### 1.1 Token no ambiente

```bash
export LOCALSTACK_AUTH_TOKEN="ls-SEU_TOKEN"
# opcional: echo 'export LOCALSTACK_AUTH_TOKEN="ls-..."' >> ~/.bashrc
```

### 1.2 Subir LocalStack

```bash
cd ~/Claude/projeto-sre/terraform-files

# Se existir container antigo
docker rm -f localstack 2>/dev/null || true

docker compose up -d
sleep 10
curl -s http://localhost:4566/_localstack/health | grep -E '"s3"|"lambda"|"apigateway"'
```

### 1.3 Parar / retomar

```bash
docker compose stop      # parar
docker compose start     # retomar (dados persistem no volume)
docker compose down      # parar e remover container (volume permanece)
docker compose down -v   # apagar volume (zera dados)
```

**Por que:** menos comandos manuais; volume evita perder buckets a cada reboot.

---

## Passo 2 - Script de bootstrap

Cria o bucket de state no LocalStack.

```bash
chmod +x scripts/bootstrap-localstack.sh

export AWS_ACCESS_KEY_ID=test 
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

./scripts/bootstrap-localstack.sh
```

Saída esperada: `✓ Bucket sre-terraform-state-local pronto`

### Init + apply

```bash
terraform init -reconfigure -backend-config=config/backend.local.hcl
terraform plan
terraform apply
```

---

## Passo 3 — API Gateway (HTTP) e teste local

### LocalStack (licença free): **sem** API Gateway

O serviço `apigatewayv2` **não está incluído** na licença gratuita do LocalStack. Por isso, com `use_localstack = true`, o Terraform **não cria** recursos de API Gateway (`local.create_api_gateway = false`).

**Como testar a API localmente:** invoque a Lambda diretamente:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

aws lambda invoke \
  --function-name ngo-tracker-dev-api \
  --endpoint-url=http://localhost:4566 \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-out.json

cat /tmp/lambda-out.json
```

Esperado: JSON com `"ok": true`.

`terraform output api_gateway_url` retorna `""` (vazio) no LocalStack — isso é **esperado**. Use `api_gateway_enabled` para verificar (`false`).

### AWS real: API Gateway habilitado

Com `use_localstack = false`, o `apply` cria HTTP API (v2) com rotas `ANY /` e `ANY /{proxy+}` → Lambda.

```bash
terraform plan   # mostra aws_apigatewayv2_* apenas com use_localstack = false
terraform apply
terraform output api_gateway_url
curl -s "$(terraform output -raw api_gateway_url)/"
```

### Por quê API Gateway na AWS?

- Expõe a Lambda via HTTP (browser, Postman, frontend)
- Padrão serverless na AWS
- Código já pronto em `api_gateway.tf`; só provisiona onde a licença/serviço existe

---

## Passo 4 - CI no GitHub Actions

Workflow: `.github/workflows/terraform-ci.yml`

### 4.1 Job sempre ativo: `fmt-validate`

Em todo push/PR em `main`:

1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`

**Não precisa de secrets** - roda em qualquer PR.

### 4.2 Job opcional: `plan-localstack`

Roda `terraform plan` com LocalStack **somente se** existir secret no repositório.

#### Configurar secret (uma vez)

1. GitHub → repositório `ngo-tracker-tf` → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. Nome: `LOCALSTACK_AUTH_TOKEN`
4. Valor: seu token `ls-...` de [app.localstack.cloud](https://app.localstack.cloud/workspace/auth-tokens)

GitHub → **Actions** → workflow **Terraform CI** → jobs verdes.

### Por que CI?

- Impede PR com HCL mal formatado ou inválido
- `plan` em PR mostra impacto antes do merge
- Demonstra prática SRE/DevOps no portfólio

### Segurança: credenciais nos logs do CI

| Valor | O que é | Usar GitHub Secret? |
|-------|---------|---------------------|
| `AWS_ACCESS_KEY_ID=test` | Credencial **dummy** do LocalStack (documentação pública) | **Não** — não protege nada e dá falsa sensação de segurança |
| `AWS_SECRET_ACCESS_KEY=test` | Idem | **Não** |
| `LOCALSTACK_AUTH_TOKEN` | Token **real** da sua conta LocalStack | **Sim** — único secret necessário |

O workflow define `test`/`test` no bloco `env:` global (não no script `run:`), para os logs não repetirem `export AWS_ACCESS_KEY_ID=test...`. O bootstrap usa `./scripts/bootstrap-localstack.sh`, que lê essas ENVs.

**Quando for AWS real:** use secrets `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (ou OIDC) — nunca commite credenciais reais.

---

## Passo 5 - AWS real (quando for deploy)

**Atenção:** gera custo na AWS. Faça só quando quiser sair do LocalStack.

### 5.1 Pré-requisitos na conta AWS

1. Bucket S3 para state (ex.: `sre-terraform-state`) - região `us-east-1`
2. Credenciais AWS configuradas (`aws configure` ou variáveis de ambiente)
3. Permissões IAM para criar S3, DynamoDB, Lambda, IAM, API Gateway

Criar bucket de state (exemplo):

```bash
aws s3 mb s3://sre-terraform-state --region us-east-1
```

### 5.2 Ajustar variáveis

Em `terraform.tfvars` (local, não commitado):

```hcl
use_localstack = false
aws_region     = "us-east-1"
environment    = "dev"
project_name   = "ngo-tracker"
```

### 5.3 Init com backend AWS

```bash
terraform init -reconfigure -backend-config=config/backend.aws.hcl
terraform plan
terraform apply
```

### 5.4 Diferenças LocalStack vs AWS real

| Aspecto | LocalStack | AWS real |
|---------|------------|----------|
| Custo | Zero (dev) | Pay-per-use |
| CloudWatch log group | Não criado (`count = 0`) | Criado com retenção 14d |
| PITR DynamoDB | Desligado | Ligado |
| Endpoint | `localhost:4566` | Endpoints AWS padrão |

---

## Validação da Fase 4

### LocalStack (dev)

```bash
docker compose ps
./scripts/bootstrap-localstack.sh
terraform apply

# Lambda (substitui API Gateway na licença free)
aws lambda invoke \
  --function-name ngo-tracker-dev-api \
  --endpoint-url=http://localhost:4566 \
  --cli-binary-format raw-in-base64-out /tmp/out.json && cat /tmp/out.json

terraform output api_gateway_url      # esperado: "" (vazio) no LocalStack
terraform output api_gateway_enabled  # esperado: false
```

| Item | OK se… |
|------|--------|
| Docker Compose | `docker compose ps` → `Up` |
| Bootstrap | script retorna ✓ |
| Lambda | invoke retorna `"ok": true` |
| API Gateway | `api_gateway_url` = `""` e `api_gateway_enabled` = `false` (normal no LocalStack) |
| CI fmt/validate | job verde no GitHub |

### AWS real (quando fizer deploy)

| Item | OK se… |
|------|--------|
| API Gateway | `terraform output api_gateway_url` preenchido |
| HTTP | `curl` na URL retorna JSON da API |

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `Defina LOCALSTACK_AUTH_TOKEN` no compose | `export LOCALSTACK_AUTH_TOKEN=ls-...` antes de `docker compose up` |
| Lambda `Docker not available` | Compose já monta `/var/run/docker.sock` - recrie: `docker compose down && docker compose up -d` |
| API Gateway 404 / licença LocalStack | Normal na licença free — use `aws lambda invoke`; API GW só na AWS real |
| CI plan não roda | Adicione secret `LOCALSTACK_AUTH_TOKEN` no GitHub |
| `fmt` falha no CI | Rode `terraform fmt -recursive` localmente e commit |

---

## Próximo passo (pós-Fase 4)

- Código real da API (substituir `lambda/handler.py`)
- Ambiente `staging` / `prod` (workspaces ou pastas)
- Alertas e observabilidade (CloudWatch dashboards)
- Políticas de branch protection exigindo CI verde

---

## Documentação relacionada

- [CHECKLIST.md](CHECKLIST.md)
- [RODAR_LOCALMENTE.md](RODAR_LOCALMENTE.md)
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md)
- [NOMENCLATURA_PADRAO.md](NOMENCLATURA_PADRAO.md)
