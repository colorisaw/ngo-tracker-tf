# Checklist do projeto — NGO Tracker TF
 
> Última revisão: maio/2026 — progresso geral ~65%.

**Legenda:** `[x]` feito · `[ ]` pendente

---

## Progresso geral

```
[████████████████████░░░░░░░░]  ~65%

Fundação     ████████████████████  100%
1º recurso   ████████████████████  100%
App infra    ░░░░░░░░░░░░░░░░░░░░    0%
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

- [x] `aws-storage.tf` — bucket `sre-terraform-state`
- [x] `terraform apply` com sucesso
- [x] Validação no LocalStack (`aws s3 ls` + `--endpoint-url`)
- [x] Validação via `terraform state`
- [x] Revisar/criar documentação


---

## Fase 3 — Infraestrutura da aplicação

- [ ] `outputs.tf` (nome/ARN do bucket etc.)
- [ ] DynamoDB (tabela do app NGO Tracker)
- [ ] IAM (roles/policies para serviços)
- [ ] Rede (VPC, subnets) — se necessário
- [ ] Compute (EKS / ECS / Lambda) — conforme arquitetura
- [ ] Organizar em módulos ou arquivos (`network.tf`, `iam.tf`, …)
- [ ] Tags e naming padronizados com `environment`
- [ ] Revisar/criar documentação

---

## Fase 4 — Operação e qualidade

- [ ] `docker-compose.yml` para LocalStack (opcional)
- [ ] Script `scripts/bootstrap-localstack.sh` (opcional)
- [ ] Volume persistente no LocalStack (`PERSISTENCE=1`) — opcional
- [ ] CI GitHub Actions (`fmt`, `validate`, `plan`)
- [ ] Ambiente AWS real (`use_localstack = false` + `backend.aws.hcl`)
- [ ] Revisar/criar documentação

---

## Rotina do dia a dia

| Rotina | Status |
|--------|--------|
| Retomar após reboot (`docs/RODAR_LOCALMENTE.md`) | [x] |
| `terraform plan` antes de mudar código | [x] |
| `terraform apply` controlado | [x] |

---

## Próximos passos sugeridos

1. Configurar CI com `terraform plan` em PRs
