# Deploy na AWS real

Guia para sair do LocalStack e provisionar NGO Tracker na AWS (com API Gateway HTTP).

> **Gera custo** (pay-per-use). Estimativa MVP dev: poucos dólares/mês com uso leve.

---

## Pré-requisitos

1. Conta AWS ativa
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado
3. Credenciais com permissão para: S3, DynamoDB, Lambda, IAM, API Gateway, CloudWatch Logs

### Configurar credenciais (uma vez)

O Terraform AWS provider lê credenciais nesta ordem: variáveis de ambiente → `~/.aws/credentials` → IAM role (EC2/CI).

**Nunca** coloque access keys em arquivos versionados (`terraform.tfvars`, scripts, workflow sem secrets).

#### Opção A — `aws configure` (recomendado no seu laptop)

Salva em `~/.aws/credentials` (fora do repositório):

```bash
aws configure
# AWS Access Key ID, Secret, região us-east-1
```

#### Opção B — arquivo local `.env.aws` (gitignored)

```bash
cp .env.aws.example .env.aws
chmod 600 .env.aws
# edite com suas keys IAM
```

O `deploy-aws.sh` carrega `.env.aws` automaticamente. O arquivo está no `.gitignore`.

#### Opção C — variáveis no terminal (sessão atual)

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

Válido para testes rápidos; some ao fechar o terminal.

#### Opção D — CI (GitHub Actions)

Use **Secrets** do repositório (Settings → Secrets → Actions). No workflow, passe via bloco `env:` — o GitHub **mascara** valores de secrets nos logs:

```yaml
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_DEFAULT_REGION: us-east-1
```

Melhor ainda: [OIDC com IAM role](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services) (sem access key estática).

O CI atual usa `test`/`test` **só** para LocalStack — não reutilize essas ENVs no job de deploy AWS.

#### Validar

```bash
aws sts get-caller-identity
```

**LocalStack no mesmo terminal:** se `AWS_ACCESS_KEY_ID=test`, o `deploy-aws.sh` remove só essas credenciais dummy e preserva keys reais ou `~/.aws/credentials`.

---

## Passo 1 — Ajustar `terraform.tfvars`

Arquivo local (não commitado). Exemplo para AWS:

```hcl
project_name   = "ngo-tracker"
aws_region     = "us-east-1"
environment    = "dev"
use_localstack = false
```

Remova ou comente `localstack_endpoint` e `localstack_lambda_endpoint` — não são usados na AWS.

---

## Passo 2 — Bucket de state remoto

```bash
chmod +x scripts/bootstrap-aws-state.sh scripts/deploy-aws.sh
./scripts/bootstrap-aws-state.sh
```

Cria `sre-terraform-state-<ACCOUNT_ID>` (ex.: `sre-terraform-state-706742315782`).

> **Por quê o sufixo?** Nomes de bucket S3 são **globais** em toda a AWS. `sre-terraform-state` sem sufixo provavelmente pertence a outra conta — você vê `BucketAlreadyExists` no create e **403** no console.

Override opcional: `TF_STATE_BUCKET=meu-bucket-unico ./scripts/bootstrap-aws-state.sh`

---

## Passo 3 — Init + apply

### Automático (recomendado)

```bash
./scripts/deploy-aws.sh
```

### Manual

```bash
terraform init -reconfigure -backend-config=config/backend.aws.hcl
terraform plan
terraform apply
```

---

## Passo 4 — Validar

```bash
terraform output api_gateway_url
terraform output api_gateway_enabled   # deve ser true

curl -s "$(terraform output -raw api_gateway_url)/"
```

Esperado:

```json
{"service":"ngo-tracker-api","environment":"dev","ok":true}
```

### Postman

1. Importe `postman/ngo-tracker-api.postman_collection.json`
2. Environment **NGO Tracker — AWS Dev** → `base_url` = `terraform output -raw api_gateway_url` (sem barra final)
3. Rode **Flow — Full audit**

---

## O que muda vs LocalStack

| Recurso | LocalStack | AWS real |
|---------|------------|----------|
| API Gateway | Não criado | HTTP API + stage `dev` |
| CloudWatch Logs | Não criado | Log group 14 dias |
| DynamoDB PITR | Off | On |
| `AWS_ENDPOINT_URL` na Lambda | `http://localstack:4566` | Não definido |
| State backend | `sre-terraform-state-local` | `sre-terraform-state` |

O state é **separado** — deploy AWS não migra o state do LocalStack (começa limpo na AWS).

---

## Voltar ao LocalStack (dev local)

```bash
# terraform.tfvars
use_localstack = true

terraform init -reconfigure -backend-config=config/backend.local.hcl
docker compose up -d
./scripts/bootstrap-localstack.sh
terraform apply
```

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `InvalidClientTokenId` | Credenciais inválidas ou ainda `test` do LocalStack → `unset` ENVs |
| `NoCredentials` | `aws configure` ou `aws login` |
| `BucketAlreadyExists` em `sre-terraform-state` | Nome global já usado por **outra conta** — use `sre-terraform-state-<ACCOUNT_ID>` (script já faz isso) |
| Bucket não aparece no console | Bucket de outra conta; ou região errada no console S3 |
| `AccessDenied` no bucket state | IAM precisa `s3:*` no bucket ou permissões admin |
| `api_gateway_url` vazio | `use_localstack` ainda `true` no tfvars |
| Custo inesperado | Destrua com `terraform destroy` quando não usar |

---

## Destruir recursos (parar custo)

```bash
terraform init -reconfigure -backend-config=config/backend.aws.hcl
terraform destroy
```

O bucket de state (`sre-terraform-state`) **não** é removido pelo destroy — delete manualmente se quiser.

---

## Documentação relacionada

- [OPERACAO_E_QUALIDADE.md](OPERACAO_E_QUALIDADE.md) — visão geral Fase 4/5
- [POSTMAN.md](POSTMAN.md) — testes HTTP
- [API.md](API.md) — rotas e payloads
