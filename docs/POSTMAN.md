# Postman — NGO Tracker API

Collection para testar a API via **HTTP** (API Gateway na AWS). Arquivos em `postman/`.

## Importar

1. Abra o Postman → **Import**
2. Selecione:
   - `postman/ngo-tracker-api.postman_collection.json`
   - `postman/aws-dev.postman_environment.json`
3. Ative o environment **NGO Tracker — AWS Dev**

## Configurar `base_url` (AWS)

Após deploy na AWS (`use_localstack = false` + `terraform apply`):

```bash
terraform output -raw api_gateway_url
```

Cole o valor (sem barra final) em **Environment → base_url**, por exemplo:

```
https://abc123xyz.execute-api.us-east-1.amazonaws.com/dev
```

## Variáveis

| Variável | Descrição |
|----------|-----------|
| `base_url` | URL do API Gateway (`terraform output api_gateway_url`) |
| `ngo_id` | Preenchido automaticamente ao rodar **POST /ngos — Create NGO** |

## Fluxo recomendado

1. **GET /** — health
2. **POST /ngos** — cria ONG e salva `ngo_id`
3. Demais requests usam `{{ngo_id}}` nas rotas
4. Ou rode a pasta **Flow — Full audit** no Collection Runner (ordem já definida)

## Testes automáticos

Cada request inclui scripts de teste (status code + campos esperados). Use **Run collection** para validar o fluxo inteiro.

## LocalStack

A licença free do LocalStack **não inclui API Gateway v2**. A collection HTTP **não funciona** contra LocalStack diretamente.

Para testes locais, use `aws lambda invoke` conforme [API.md](API.md). A Postman collection entra em cena após o deploy AWS.

## Estrutura

```
postman/
├── ngo-tracker-api.postman_collection.json
└── aws-dev.postman_environment.json
```
