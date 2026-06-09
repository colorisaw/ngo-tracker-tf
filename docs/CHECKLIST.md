# Checklist do projeto — NGO Tracker TF

> Última revisão: maio/2026 — progresso geral ~85%.

**Legenda:** `[x]` feito · `[ ]` pendente · `[-]` adiado de propósito

---

## Progresso geral

```
[█████████████████████████░░░]  ~85%

Fundação     ████████████████████  100%
1º recurso   ████████████████████  100%
App infra    █████████████████░░░   85%
CI / AWS     ░░░░░░░░░░░░░░░░░░░░    0%
```

---

## Fase 1 — Fundação

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

## Fase 2 — Primeiro recurso

- [x] Bucket S3 inicial (validação do ciclo plan/apply)
- [x] `terraform apply` com sucesso
- [x] Validação no LocalStack (`aws s3 ls` + `--endpoint-url`)
- [x] Validação via `terraform state`
- [x] Revisar/criar documentação

---

## Fase 3 — Infraestrutura da aplicação

- [x] `outputs.tf` (bucket, DynamoDB, Lambda, IAM)
- [x] DynamoDB — tabela single-table `ngo-tracker-{env}-main`
- [x] IAM — role + policy para Lambda (DynamoDB, S3, logs)
- [x] S3 — bucket `ngo-tracker-{env}-data` (versioning, encryption, block public)
- [x] Lambda — API placeholder (`lambda/handler.py`)
- [x] Naming/tags padronizados (`project_name`, `environment`, `locals.name_prefix`)
- [x] Arquivos organizados (`storage.tf`, `dynamodb.tf`, `iam.tf`, `lambda.tf`)
- [x] Documentação — [FASE_2.md](FASE_2.md)
- [ ] `terraform apply` da Fase 3 no LocalStack
- [-] Rede (VPC, subnets) — adiado (Lambda sem VPC no MVP)
- [-] EKS / ECS — adiado (fase futura, se necessário)

---

## Fase 4 — Operação e qualidade

- [ ] `docker-compose.yml` para LocalStack (opcional)
- [ ] Script `scripts/bootstrap-localstack.sh` (opcional)
- [ ] Volume persistente no LocalStack (`PERSISTENCE=1`) — opcional
- [ ] CI GitHub Actions (`fmt`, `validate`, `plan`)
- [ ] Ambiente AWS real (`use_localstack = false` + `backend.aws.hcl`)
- [ ] API Gateway + rota HTTP para a Lambda (opcional)

---

## Rotina do dia a dia

| Rotina | Status |
|--------|--------|
| Retomar após reboot (`docs/RODAR_LOCALMENTE.md`) | [x] |
| `terraform plan` antes de mudar código | [x] |
| `terraform apply` controlado | [x] |

---

## Próximos passos sugeridos

1. `terraform init` (provider `archive`) + `terraform apply`
2. Validar Lambda e DynamoDB no LocalStack
3. Configurar CI com `terraform plan` em PRs

---

## Documentação relacionada

- [Infraestrutura da aplicação](INFRASTRUCTURE.md)
- [Implementação do Terraform.md](TERRAFORM_IMPLEMENTATION.md)
- [Passo a passo - Rodar localmente](RODAR_LOCALMENTE.md)
