# Checklist do projeto - NGO Tracker TF

> Última revisão: junho/2026 - progresso geral ~98%.

**Legenda:** `[x]` feito · `[ ]` pendente · `[-]` adiado de propósito

---

## Progresso geral

```
[████████████████████████████]  ~98%

Fundação     ████████████████████  100%
1º recurso   ████████████████████  100%
App infra    ████████████████████  100%
Ops / CI     ████████████████████  100%
App (API)    ████████████████████  100%
AWS deploy   ████████████████████  100%
```

---

## Fase 1 - Fundação

- [x] Estrutura Terraform (`versions.tf`, `variables.tf`, `providers.tf`, `backend.tf`, `locals.tf`)
- [x] FinOps: `use_localstack` + endpoints LocalStack
- [x] Backend remoto (S3 + `use_lockfile` em `config/backend.local.hcl` e `config/backend.aws.hcl`)
- [x] `.gitignore` (state, tfvars, `.terraform/`; lock versionado)
- [x] `terraform init` (provider) + `terraform validate`
- [x] `.terraform.lock.hcl` versionado no Git
- [x] Repositório Git + push GitHub (`ngo-tracker-tf`)
- [x] LocalStack com `LOCALSTACK_AUTH_TOKEN`
- [x] Bootstrap bucket backend (`sre-terraform-state-local`)
- [x] `terraform init -backend-config=config/backend.local.hcl`
- [x] Documentação do processo

---

## Fase 2 - Primeiro recurso

- [x] Bucket S3 inicial (validação do ciclo plan/apply)
- [x] `terraform apply` com sucesso
- [x] Validação no LocalStack (`aws s3 ls` + `--endpoint-url`)
- [x] Validação via `terraform state`
- [x] Revisar/criar documentação

---

## Fase 3 - Infraestrutura da aplicação

- [x] `outputs.tf` (bucket, DynamoDB, Lambda, IAM)
- [x] DynamoDB - tabela single-table `ngo-tracker-{env}-main`
- [x] IAM - role + policy para Lambda (DynamoDB, S3, logs)
- [x] S3 - bucket `ngo-tracker-{env}-data` (versioning, encryption, block public)
- [x] Lambda - API placeholder (`lambda/handler.py`)
- [x] Naming/tags padronizados (`project_name`, `environment`, `locals.name_prefix`)
- [x] Arquivos organizados (`storage.tf`, `dynamodb.tf`, `iam.tf`, `lambda.tf`)
- [x] Documentação - [INFRASTRUCTURE.md](INFRASTRUCTURE.md)
- [x] `terraform apply` da Fase 3 no LocalStack
- [x] Validação completa (state, outputs, S3, DynamoDB, IAM, Lambda invoke)
- [-] Rede (VPC, subnets) - adiado (Lambda sem VPC no MVP)
- [-] EKS / ECS - adiado (fase futura, se necessário)

---

## Fase 4 - Operação e qualidade

- [x] `docker-compose.yml` para LocalStack (persistência + docker.sock)
- [x] Script `scripts/bootstrap-localstack.sh`
- [x] Volume persistente (`PERSISTENCE=1` no compose)
- [x] CI GitHub Actions (`fmt`, `validate`, `plan` opcional com LocalStack)
- [x] API Gateway HTTP (`api_gateway.tf`) — **somente AWS real** (LocalStack free não inclui apigatewayv2)
- [x] Documentação - [OPERACAO_E_QUALIDADE.md](OPERACAO_E_QUALIDADE.md)
- [x] `terraform apply` da Fase 4 no LocalStack (sem API Gateway; validar Lambda invoke)
- [x] Validar Lambda invoke pós-apply (`aws lambda invoke`)
- [x] Outputs `api_gateway_*` registrados no state (vazio no LocalStack)
- [x] Secret `LOCALSTACK_AUTH_TOKEN` configurado no GitHub
- [x] CI verde no repositório remoto (Actions)
- [x] Ambiente AWS real (`use_localstack = false` + `backend.aws.hcl`) — [DEPLOY_AWS.md](DEPLOY_AWS.md)

---

## Rotina do dia a dia

| Rotina | Status |
|--------|--------|
| Retomar após reboot (`docs/RODAR_LOCALMENTE.md` ou `docker compose start`) | [x] |
| `terraform plan` antes de mudar código | [x] |
| `terraform apply` controlado | [x] |

---

## Fase 5 - Aplicação (API)

- [x] API REST em `lambda/` (ONGs, doações, gastos, comprovantes S3)
- [x] DynamoDB single-table (pk/sk + GSI)
- [x] Documentação — [API.md](API.md)
- [x] `terraform apply` com novo código da Lambda
- [x] Testes manuais via `aws lambda invoke` (fluxo completo)
- [x] Postman collection — [POSTMAN.md](POSTMAN.md)

---

## Próximos passos sugeridos

1. ~~**Postman collection**~~ — [POSTMAN.md](POSTMAN.md)
2. ~~**Deploy AWS real**~~ — [DEPLOY_AWS.md](DEPLOY_AWS.md)
3. ~~Testar API na AWS via Postman~~ (`api_gateway_url` + environment ativo)
4. **Frontend** (opcional) — painel para ONGs e doadores

---

## Documentação relacionada

- [Infraestrutura da aplicação](INFRASTRUCTURE.md)
- [Implementação do Terraform.md](TERRAFORM_IMPLEMENTATION.md)
- [Passo a passo - Rodar localmente](RODAR_LOCALMENTE.md)
- [Nomenclatura Padrão](NOMENCLATURA_PADRAO.md)
- [Lambda - API REST](API.md)
- [Postman collection](POSTMAN.md)


