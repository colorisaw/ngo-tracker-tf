# NGO Tracker API

API REST da Lambda `ngo-tracker-{env}-api`. Persiste dados no DynamoDB (single-table) e comprovantes no S3.

## Base URL

| Ambiente | URL |
|----------|-----|
| LocalStack (invoke direto) | N/A — use `aws lambda invoke` com payload HTTP simulado |
| AWS + API Gateway | `terraform output api_gateway_url` |

## Modelo de dados (DynamoDB)

| Entidade | pk | sk | entity_type |
|----------|----|----|-------------|
| ONG | `NGO#{id}` | `PROFILE` | `NGO` |
| Doação | `NGO#{id}` | `DONATION#{id}` | `DONATION` |
| Gasto | `NGO#{id}` | `EXPENSE#{id}` | `EXPENSE` |

## Rotas

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/` | Health check |
| GET | `/ngos` | Listar ONGs |
| POST | `/ngos` | Criar ONG |
| GET | `/ngos/{id}` | Perfil + resumo (totais doações/gastos/saldo) |
| GET | `/ngos/{id}/donations` | Listar doações |
| POST | `/ngos/{id}/donations` | Registrar doação |
| GET | `/ngos/{id}/expenses` | Listar gastos |
| POST | `/ngos/{id}/expenses` | Registrar gasto |
| POST | `/ngos/{id}/receipts` | Upload comprovante (base64) → S3 |

### POST /ngos

```json
{
  "name": "Resgate Patinhas",
  "description": "ONG de resgate animal em SP",
  "city": "São Paulo"
}
```

### POST /ngos/{id}/donations

```json
{
  "amount": 150.50,
  "donor_name": "Maria Silva",
  "notes": "Doação mensal"
}
```

### POST /ngos/{id}/expenses

```json
{
  "amount": 89.90,
  "category": "veterinario",
  "description": "Consulta e medicamentos"
}
```

### POST /ngos/{id}/receipts

```json
{
  "filename": "nota-fiscal.pdf",
  "content_base64": "<base64 do arquivo>"
}
```

## Testar no LocalStack

Após `terraform apply` (atualiza código da Lambda):

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
FN=ngo-tracker-dev-api
EP=http://localhost:4566

# Health
aws lambda invoke --function-name $FN --endpoint-url=$EP \
  --cli-binary-format raw-in-base64-out \
  --payload '{"httpMethod":"GET","path":"/"}' /tmp/out.json && cat /tmp/out.json

# Criar ONG
aws lambda invoke --function-name $FN --endpoint-url=$EP \
  --cli-binary-format raw-in-base64-out \
  --payload '{"httpMethod":"POST","path":"/ngos","body":"{\"name\":\"Resgate Patinhas\",\"city\":\"SP\"}"}' \
  /tmp/out.json && cat /tmp/out.json

# Listar ONGs
aws lambda invoke --function-name $FN --endpoint-url=$EP \
  --cli-binary-format raw-in-base64-out \
  --payload '{"httpMethod":"GET","path":"/ngos"}' /tmp/out.json && cat /tmp/out.json
```

Substitua `{id}` nos paths pelos `ngo_id` retornado no POST.

## Troubleshooting LocalStack

### Health OK, mas POST retorna 500 (`Could not connect to localhost:4566`)

A Lambda roda em **outro container Docker**. Dentro dele, `localhost` é o próprio container — não o LocalStack.

| Quem chama | Endpoint correto |
|------------|------------------|
| Terraform / AWS CLI (host) | `http://localhost:4566` |
| Lambda (container filho, docker compose) | `http://localstack:4566` |
| Lambda (container filho, docker run) | `http://host.docker.internal:4566` + `LAMBDA_DOCKER_FLAGS` |

**Correção:**

1. Em `terraform.tfvars` (docker compose):
   ```hcl
   localstack_lambda_endpoint = "http://localstack:4566"
   ```

2. LocalStack com `host-gateway` (docker compose já inclui `extra_hosts`):
   ```bash
   docker compose down && docker compose up -d
   ```
   Ou com `docker run`:
   ```bash
   --add-host=host.docker.internal:host-gateway
   ```

3. Atualizar env da Lambda:
   ```bash
   terraform apply
   ```

## Estrutura do código

```
lambda/
├── handler.py      # roteamento HTTP
├── http_utils.py   # parse event + respostas JSON
└── repository.py   # DynamoDB + S3
```

## Deploy de código novo

```bash
terraform apply   # recria zip e atualiza Lambda (source_code_hash)
```
