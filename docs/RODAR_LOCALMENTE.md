Guia para rodar a partir do repositório `terraform-files` em sua máquina local. Sobe o ambiente com LocalStack para permitir o desenvolvimento  de infra sem gerar custos na AWS.

> Clique aqui para ver o [andamento geral do projeto](CHECKLIST.md)

## Pré-requisitos

- Este repositório clonado localmente
- [Docker](https://docs.docker.com/engine/install/), [Terraform](https://developer.hashicorp.com/terraform/install), [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalados
- Conta criada no [LocalStack](https://www.localstack.cloud/)

## Visão geral

```
1. Abrir terminal no repositório `terraform-files`
2. Definir variáveis de ambiente (AWS CLI + token LocalStack)
3. Subir LocalStack (Docker)
4. Health check
5. Bootstrap S3 (backend) - se LocalStack estiver “vazio”
6. Terraform (init se precisar → validate → plan → apply)
7. Validar recursos (state, outputs, AWS CLI, invoke Lambda)
```

Tempo estimado: **3–8 minutos**.

---

## Passo a passo detalhado

### 1. Ir para a pasta do projeto

```bash
cd <PATH_ATÉ_A_PASTA_TERRAFORM-FILES_NA_SUA_MÁQUINA>
```

---

### 2. Variáveis de ambiente (ENVs)

```bash
# Credenciais fake do LocalStack (para usar a AWS CLI)
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:4566 #pode trocar a porta se quiser

# Token LocalStack (substitua pelo seu - ou tenha no ~/.bashrc)
export LOCALSTACK_AUTH_TOKEN="ls-SEU_TOKEN_AQUI"
```

Se quiser persistir as ENVs no `~/.bashrc`:

```bash
echo 'export LOCALSTACK_AUTH_TOKEN="ls-..."' >> ~/.bashrc
echo 'export AWS_ACCESS_KEY_ID=test' >> ~/.bashrc
echo 'export AWS_SECRET_ACCESS_KEY=test' >> ~/.bashrc
echo 'export AWS_DEFAULT_REGION=us-east-1' >> ~/.bashrc
echo 'export AWS_ENDPOINT_URL=http://localhost:4566' >> ~/.bashrc
```

Depois: `source ~/.bashrc`

> [!NOTE]
> Alguns comandos/saídas usarão a porta do endpoint da AWS definido na última ENV. Lembre-se de usar/esperar a mesma porta caso tenha customizado a sua.

---

### 3. Subir o LocalStack (Docker)

#### 3a) Container já existe (nome `localstack`)

```bash
docker start localstack
```

Use `docker container list` para checar os containeres existentes.

#### 3b) Primeira vez ou container foi removido

```bash
docker rm -f localstack 2>/dev/null

docker run -d --name localstack \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e LOCALSTACK_AUTH_TOKEN="${LOCALSTACK_AUTH_TOKEN}" \
  -e SERVICES=s3,dynamodb,ec2,iam,sts,eks,lambda,logs \
  localstack/localstack
```

#### 3c) Conferir se está rodando

```bash
docker ps
```

Esperado: linha com `localstack` e `0.0.0.0:4566->4566/tcp`.

Aguarde **5–15 segundos** antes dos próximos passos.

---

### 4. Health check

```bash
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool | grep -E '"s3"|"dynamodb"'
```

Esperado: `"s3": "available"`.

Se vazio ou `Connection refused` use `docker logs localstack --tail 30`. Irá mostrar as últimas 30 linhas dos logs do container, o que deve trazer um código de erro ou motivo para investigação e correção :bulb:

---

### 5. Bootstrap do backend (S3 de state)

Vai criar um bucket para armazenar os arquivos de estado do Terraform.

> [!TIP] 
> Após desligar o PC, o LocalStack costuma **perder dados** (porque não tem volume persistente). Use estes mesmos passos para recriar o bucket do backend sempre que reiniciar a máquina.

```bash
aws s3 mb s3://sre-terraform-state-local \
  --endpoint-url=http://localhost:4566 2>/dev/null || true

aws s3 ls --endpoint-url=http://localhost:4566
```

Deve listar `sre-terraform-state-local`.

> O `config/backend.local.hcl` usa `use_lockfile = true` (lock no S3). Não é necessário criar tabela DynamoDB para lock.

---

### 6. Terraform

#### 6a) Init (se necessário)

Rode se:

- é a primeira vez na máquina após clone, ou
- mudou backend/provider, ou
- apagou a pasta `.terraform`

```bash
terraform init -backend-config=config/backend.local.hcl
```

Se já inicializou antes e nada mudou, pode pular.

#### 6b) Validar e planejar

```bash
terraform validate
terraform plan
```


| Resultado do `plan`     | O que fazer                          |
| ----------------------- | ------------------------------------ |
| `No changes`            | Ambiente alinhado - pode codar       |
| Quer **criar** recursos | LocalStack vazio → `terraform apply` |
| Erro de backend/state   | Ver **Problemas** abaixo             |


#### 6c) Aplicar (se o plan mostrar recursos a criar)

```bash
terraform apply
```

---

### 7. Validar recursos após o `apply`

Use **três camadas**: Terraform (state/outputs), AWS CLI no LocalStack e teste funcional.

#### 7a) Preparar atalho do endpoint

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export LS=http://localhost:4566
```

#### 7b) Terraform - state e outputs

```bash
terraform state list
terraform output
```

**`terraform state list` - 9 itens esperados:**

```text
data.archive_file.lambda_api          # zip local da Lambda (não é recurso AWS)
aws_dynamodb_table.main
aws_iam_role.lambda_api
aws_iam_role_policy.lambda_api
aws_lambda_function.api
aws_s3_bucket.app_data
aws_s3_bucket_public_access_block.app_data
aws_s3_bucket_server_side_encryption_configuration.app_data
aws_s3_bucket_versioning.app_data
```

> `data.archive_file.lambda_api` é normal: empacota `lambda/handler.py` antes do deploy.

**`terraform output` - 9 valores esperados:**

| Output | Exemplo em `dev` |
|--------|------------------|
| `environment` | `dev` |
| `name_prefix` | `ngo-tracker-dev` |
| `s3_app_data_bucket_name` | `ngo-tracker-dev-data` |
| `s3_app_data_bucket_arn` | `arn:aws:s3:::ngo-tracker-dev-data` |
| `dynamodb_table_name` | `ngo-tracker-dev-main` |
| `dynamodb_table_arn` | `arn:aws:dynamodb:...` |
| `lambda_api_function_name` | `ngo-tracker-dev-api` |
| `lambda_api_arn` | `arn:aws:lambda:...` |
| `lambda_api_role_arn` | `arn:aws:iam::...` |

Outputs com sufixo `_arn` são intencionais (IAM, CI, integrações).

#### 7c) S3 - bucket de dados

```bash
aws s3 ls --endpoint-url=$LS | grep ngo-tracker

aws s3api head-bucket --bucket ngo-tracker-dev-data --endpoint-url=$LS

echo "validacao" > /tmp/teste-ngo.txt
aws s3 cp /tmp/teste-ngo.txt s3://ngo-tracker-dev-data/validacao/teste.txt --endpoint-url=$LS
aws s3 ls s3://ngo-tracker-dev-data/validacao/ --endpoint-url=$LS
```

#### 7d) DynamoDB - tabela principal

```bash
aws dynamodb describe-table \
  --table-name ngo-tracker-dev-main \
  --endpoint-url=$LS \
  --query 'Table.{Name:TableName,Status:TableStatus,Keys:KeySchema}'
```

Esperado: `Status: ACTIVE`, chaves `pk` e `sk`.

#### 7e) IAM - role da Lambda

```bash
aws iam get-role \
  --role-name ngo-tracker-dev-lambda-api \
  --endpoint-url=$LS \
  --query 'Role.{Name:RoleName,Arn:Arn}'
```

#### 7f) Lambda - invoke

```bash
aws lambda get-function \
  --function-name ngo-tracker-dev-api \
  --endpoint-url=$LS \
  --query 'Configuration.{Name:FunctionName,State:State,Runtime:Runtime}'

aws lambda invoke \
  --function-name ngo-tracker-dev-api \
  --endpoint-url=$LS \
  --cli-binary-format raw-in-base64-out \
  /tmp/lambda-out.json

cat /tmp/lambda-out.json
```

Esperado: `State: Active` e JSON com `"ok": true`.

#### 7g) Script único (checklist rápido)

```bash
cd ~/Claude/projeto-sre/terraform-files
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
LS=http://localhost:4566

echo "=== STATE ===" && terraform state list
echo "=== OUTPUTS ===" && terraform output
echo "=== S3 ===" && aws s3 ls --endpoint-url=$LS | grep ngo-tracker
echo "=== DYNAMODB ===" && aws dynamodb describe-table --table-name ngo-tracker-dev-main --endpoint-url=$LS --query 'Table.TableStatus' --output text
echo "=== LAMBDA ===" && aws lambda get-function --function-name ngo-tracker-dev-api --endpoint-url=$LS --query 'Configuration.State' --output text
echo "=== INVOKE ===" && aws lambda invoke --function-name ngo-tracker-dev-api --endpoint-url=$LS --cli-binary-format raw-in-base64-out /tmp/lambda-out.json && cat /tmp/lambda-out.json
```

> Sempre use `--endpoint-url` (ou `$LS`). Sem isso, o CLI consulta a AWS real.

---

## Cenários após reiniciar

### A) Só o Docker parou (dados do LocalStack ainda existem)

```bash
docker start localstack
terraform plan   # muitas vezes: No changes
```

### B) LocalStack “zerado” (comum)

1. Passos 3–5 (subir + bucket de backend)
2. `terraform plan` → pode pedir **create** de recursos
3. `terraform apply`

---

## Problemas comuns


| Erro                           | Solução                                                                                                                                      |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `permission denied` no docker  | [adicione docker a groups](https://medium.com/@gildembergleite/como-utilizar-os-comandos-do-docker-sem-o-sudo-no-debian-ubuntu-8c504dfc0b51) |
| Exit 55 LocalStack             | `export LOCALSTACK_AUTH_TOKEN=...` antes do `docker run`                                                                                     |
| `curl` vazio na 4566           | `docker ps` + `docker logs localstack`                                                                                                       |
| Backend / state não encontrado | Recriar bucket `sre-terraform-state-local` + `terraform init -reconfigure -backend-config=config/backend.local.hcl`                          |
| State dessincronizado          | `terraform refresh` ou `terraform apply` em dev                                                                                              |
| Lambda `Docker not available`  | Recriar LocalStack com `-v /var/run/docker.sock:/var/run/docker.sock` (ver abaixo)                                                           |


---

## Lambda: `Docker not available`

O LocalStack executa Lambdas criando **containers Docker filhos**. Para isso, o container do LocalStack precisa acessar o Docker do host:

```bash
-v /var/run/docker.sock:/var/run/docker.sock
```

Se o `apply` falhar com `Error while creating lambda: Docker not available`:

```bash
# 1. Recriar LocalStack COM o socket do Docker
docker rm -f localstack

docker run -d --name localstack \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e LOCALSTACK_AUTH_TOKEN="${LOCALSTACK_AUTH_TOKEN}" \
  -e SERVICES=s3,dynamodb,ec2,iam,sts,eks,lambda,logs \
  localstack/localstack

sleep 10

# 2. Recriar bucket de state (se LocalStack perdeu dados)
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
aws s3 mb s3://sre-terraform-state-local --endpoint-url=http://localhost:4566 2>/dev/null || true

# 3. Reaplicar Terraform (S3/DynamoDB/IAM já podem existir no state)
cd ~/Claude/projeto-sre/terraform-files
terraform init -reconfigure -backend-config=config/backend.local.hcl
terraform apply
```

> Se a Lambda continuar em estado `Failed`, force recriação: `terraform taint aws_lambda_function.api && terraform apply`

---

## OPCIONAL: Persistir LocalStack entre reboots

```bash
docker rm -f localstack 2>/dev/null

docker run -d --name localstack \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v localstack-data:/var/lib/localstack \
  -e LOCALSTACK_AUTH_TOKEN="${LOCALSTACK_AUTH_TOKEN}" \
  -e SERVICES=s3,dynamodb,ec2,iam,sts,eks,lambda,logs \
  -e PERSISTENCE=1 \
  localstack/localstack
```

Com isso, muitas vezes basta `docker start localstack` + `terraform plan` para voltar a trabalhar depois de desligar a máquina.