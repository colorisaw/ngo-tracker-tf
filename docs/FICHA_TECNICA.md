# Resumo do que foi feito (e porquê)

Projeto: **ngo-tracker-tf** — infraestrutura como código com Terraform e emulação local (decisão de FinOps para evitar gastos desnecessários).

---

## 1. Base do projeto Terraform

- **O quê:** Criados os arquivos `.gitignore`, `versions.tf`, `variables.tf`, `providers.tf`, `backend.tf` e configs aninhados em `config/`.
- **Por quê:** Estrutura padrão no Terraform 1.5+, mantém o provider AWS versionado e código organizado desde o início.

---

## 2. FinOps com LocalStack

- **O quê:** Variável `use_localstack` (padrão `true`) que redireciona o provider para `http://localhost:4566`.
- **Por quê:** Desenvolver **sem custo** na AWS real; permite testar S3, DynamoDB, IAM etc. localmente.

---

## 3. Backend remoto (state + lock)

- **O quê:** Backend S3 com lock via `use_lockfile`; arquivos `backend.local.hcl` (LocalStack) e `backend.aws.hcl` (AWS real) para usar diferentes backends.
- **Por quê:** State compartilhável, seguro e com bloqueio para evitar dois `apply` ao mesmo tempo, previne sobrescrita e alterações indesejadas que podem causar incidente em ambiente produtivo.

---

## 4. Provider e validação

- **O quê:** `terraform init` baixa o AWS provider; `terraform validate` confere a sintaxe.
- **Por quê:** Permite que recursos sejam criados a partir do código. Nesta ordem porque o `validate` só funciona **depois** do `init`.

---

## 5. Versionamento no Git

- **O quê:** Repositório Git, commit dos `.tf`, **`.terraform.lock.hcl`** versionado; `terraform.tfvars` ignorado.
- **Por quê:** Lock fixa a versão exata do provider (`5.100.0`) para todo o time e CI; tfvars ignorado por questão de segurança: pode ter dados locais.

---

## 6. Push para o GitHub

- **O quê:** `git pull --rebase` + `git push`.
- **Por quê:** Pull feito para integrar histórico remoto e local antes de enviar o código. Rebase feito para resolver conflito com README inicial do GitHub com histórico menos poluído. Push para manter versão remota atualizada.

---

## 7. LocalStack no ar

- **O quê:** Container Docker + `LOCALSTACK_AUTH_TOKEN` (licença gratuita em <app.localstack.cloud>).
- **Por quê:** Versões novas do LocalStack exigem token; sem isso o container encerra com `exit code 55`.

---

## 9. Bootstrap do backend local

- **O quê:** Bucket `sre-terraform-state-local` no LocalStack para gravar o state.
- **Por quê:** O `terraform init` com backend precisa desse bucket antes de armazenar o state remotamente. Armazenamento remoto é mais seguro que local, porque protege de possível perda de dados e permite colaboração entre as pessoas.

---

## 10. Init com backend local

- **O quê:** `terraform init -backend-config=config/backend.local.hcl`.
- **Por quê:** Conectar o Terraform ao S3 do LocalStack para state remoto em ambiente de desenvolvimento.

---

## 11. Primeiro recurso (bucket S3)

- **O quê:** `aws-storage.tf` com bucket `sre-terraform-state` + `terraform apply`.
- **Por quê:** Validar o ciclo completo: código → plan → apply → recurso emulado criado com sucesso.

---

## 12. Validação pós-apply

- **O quê:** `aws s3 ls --endpoint-url=http://localhost:4566`, `head-bucket`, `terraform state show`.
- **Por quê:** Uso da AWS CLI para checar a criação do recurso. O CLI sem `--endpoint-url` consulta a AWS real; com endpoint, confirma o bucket no LocalStack.

---

## Linha do tempo em uma frase

Foi montada a fundação/base Terraform + Git, feita a emulação da AWS com LocalStack para custo zero, a configuração backend remoto local. Foi criado o primeiro bucket e o fluxo de infraestrutura como código de ponta a ponta foi validado.
