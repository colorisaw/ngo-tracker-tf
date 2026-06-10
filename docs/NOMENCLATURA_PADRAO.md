# Nomenclatura padrão de recursos

Resumo das convenções de naming já adotadas no **ngo-tracker-tf**. Novos recursos devem seguir este padrão.

---

## Fórmula base

```
{project_name}-{environment}-{função}
```

Definida em `locals.tf` como:

```hcl
name_prefix = "${var.project_name}-${var.environment}"
```

| Variável | Padrão | Exemplo |
|----------|--------|---------|
| `project_name` | `ngo-tracker` | Nome do produto |
| `environment` | `dev` | `dev`, `staging`, `prod` |
| `name_prefix` | (calculado) | `ngo-tracker-dev` |

**Regra de caracteres:** apenas letras minúsculas, números e hífens (`^[a-z][a-z0-9-]*$`), validado em `variables.tf` - exigência de S3 e de vários recursos AWS.

---

## Tags obrigatórias

Aplicadas via `default_tags` no provider e `merge(local.common_tags, …)` nos recursos:

| Tag | Valor | Uso |
|-----|-------|-----|
| `Environment` | `var.environment` | Ambiente (dev/staging/prod) |
| `ManagedBy` | `terraform` | Identifica IaC |
| `Project` | `var.project_name` | Alocação de custo / inventário |
| `Name` | `{name_prefix}-{função}` | Nome legível no console AWS |

---

## Recursos da aplicação (Fase 3)

Padrão: **`${local.name_prefix}-<sufixo>`**

| Serviço | Nome em `dev` | Arquivo | Sufixo / função |
|---------|---------------|---------|-----------------|
| S3 (dados) | `ngo-tracker-dev-data` | `storage.tf` | `-data` - anexos, relatórios, exports |
| DynamoDB | `ngo-tracker-dev-main` | `dynamodb.tf` | `-main` - tabela single-table |
| IAM role | `ngo-tracker-dev-lambda-api` | `iam.tf` | `-lambda-api` - execução da API |
| IAM policy | `ngo-tracker-dev-lambda-api` | `iam.tf` | mesmo nome da role (inline) |
| Lambda | `ngo-tracker-dev-api` | `lambda.tf` | `-api` - função HTTP/API |
| CloudWatch Logs | `/aws/lambda/ngo-tracker-dev-api` | `lambda.tf` | path padrão AWS + `name_prefix` |
| GSI DynamoDB | `entity-type-index` | `dynamodb.tf` | kebab-case, descreve o índice |

### Atributos DynamoDB (não mudam por ambiente)

| Atributo | Tipo | Papel |
|----------|------|--------|
| `pk` | String | Partition key |
| `sk` | String | Sort key |
| `entity_type` | String | Hash key do GSI |

---

## Backend Terraform (state) - naming separado

O **state** não usa `name_prefix` da aplicação - evita misturar infra de controle com dados do produto.

| Contexto | Bucket S3 (state) | Key do state |
|----------|-------------------|--------------|
| LocalStack (`backend.local.hcl`) | `sre-terraform-state-local` | `dev/terraform.tfstate` |
| AWS real (`backend.aws.hcl`) | `sre-terraform-state` | `dev/terraform.tfstate` |

Lock: `use_lockfile = true` (arquivo de lock no próprio bucket S3).

> **Não** usar `ngo-tracker-*` para bucket de state; **não** usar `sre-terraform-state*` para dados da aplicação.

---

## Código Terraform (identificadores HCL)

### Arquivos `.tf`

Um domínio por arquivo, em **snake_case** descritivo:

| Arquivo | Domínio |
|---------|---------|
| `storage.tf` | S3 |
| `dynamodb.tf` | DynamoDB |
| `iam.tf` | IAM |
| `lambda.tf` | Lambda + logs |
| `outputs.tf` | Outputs |
| `variables.tf` | Variáveis de entrada |
| `locals.tf` | Valores derivados e tags |

### Blocos `resource`

Formato: `resource "aws_<tipo>" "<nome_lógico>"` - **snake_case**, curto, papel do recurso:

| Recurso lógico | Tipo AWS |
|----------------|----------|
| `app_data` | `aws_s3_bucket` |
| `main` | `aws_dynamodb_table` |
| `lambda_api` | `aws_iam_role`, `aws_cloudwatch_log_group` |
| `api` | `aws_lambda_function` |

### Variáveis de ambiente (Lambda)

UPPER_SNAKE_CASE, sem prefixo de projeto:

- `ENVIRONMENT`
- `DYNAMODB_TABLE`
- `S3_BUCKET`

---

## Exemplos por ambiente

| Ambiente | `name_prefix` | Bucket dados | Tabela DynamoDB | Lambda |
|----------|---------------|--------------|-----------------|--------|
| dev | `ngo-tracker-dev` | `ngo-tracker-dev-data` | `ngo-tracker-dev-main` | `ngo-tracker-dev-api` |
| staging | `ngo-tracker-staging` | `ngo-tracker-staging-data` | `ngo-tracker-staging-main` | `ngo-tracker-staging-api` |
| prod | `ngo-tracker-prod` | `ngo-tracker-prod-data` | `ngo-tracker-prod-main` | `ngo-tracker-prod-api` |

Basta alterar `environment` em `terraform.tfvars` (e o backend/key do state, se necessário).

---

## O que evitar

| Evitar | Preferir |
|--------|----------|
| Nomes fixos sem `environment` (`ngo-tracker-data`) | `${local.name_prefix}-data` |
| Misturar state e app no mesmo bucket | `sre-terraform-state-*` vs `ngo-tracker-*-data` |
| Maiúsculas, underscores em nomes AWS | minúsculas e hífens |
| `Project = sre-terraform` | `Project = ngo-tracker` (`local.project_name`) |
| Nomes genéricos (`bucket1`, `table1`) | sufixos com função (`-data`, `-main`, `-api`) |

---

## Referência no código

- Prefixo e tags: `locals.tf`
- Validação: `variables.tf` (`project_name`, `environment`)
- Lista de nomes em runtime: `terraform output name_prefix`
