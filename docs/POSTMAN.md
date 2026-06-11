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

## O que esperar do **Flow — Full audit**

Rode só a pasta **Flow — Full audit** (não a collection inteira), com o environment AWS ativo.

| Passo | Método | Status | Body (resumo) |
|-------|--------|--------|----------------|
| 1. Health | GET `/` | **200** | `{"ok":true,"service":"ngo-tracker-api",...}` |
| 2. Create NGO | POST `/ngos` | **201** | `{"ngo":{"ngo_id":"uuid-...",...}}` — salva `ngo_id` |
| 3. Register donation | POST `/ngos/{id}/donations` | **201** | `{"donation":{"amount":200,...}}` |
| 4. Register expense | POST `/ngos/{id}/expenses` | **201** | `{"expense":{"amount":75,"category":"racao",...}}` |
| 5. Upload receipt | POST `/ngos/{id}/receipts` | **201** | `{"receipt":{"bucket":"...","key":"ngos/.../receipts/..."}}` |
| 6. Summary | GET `/ngos/{id}` | **200** | `{"ngo":{...},"summary":{"total_donations":200,"total_expenses":75,"balance":125,...}}` |

No **Collection Runner**, ao final deve aparecer algo como **11 tests passed** (não "no tests found").

### "no tests found" com status 201 — o que significa?

- **201/200 = a API respondeu corretamente** (isso é o que importa para o fluxo).
- **"no tests found"** = aquele request **não tinha** script `pm.test(...)` na aba **Tests** — o Postman só reporta testes automatizados, não valida sozinho o body.
- As pastas **Health**, **NGOs**, etc. têm testes completos; a pasta **Flow** foi atualizada para incluir testes em todos os 6 passos.

Se o passo 3+ falhar com 404, o passo 2 não gravou `ngo_id` — confira **Environment → ngo_id** após o Create NGO.

## Testes automáticos

Requests nas pastas individuais e no **Flow** incluem scripts de teste (status + campos). Use **Run folder** na pasta Flow ou **Run collection** na collection inteira.

## LocalStack

A licença free do LocalStack **não inclui API Gateway v2**. A collection HTTP **não funciona** contra LocalStack diretamente.

Para testes locais, use `aws lambda invoke` conforme [API.md](API.md). A Postman collection entra em cena após o deploy AWS.

## Estrutura

```
postman/
├── ngo-tracker-api.postman_collection.json
└── aws-dev.postman_environment.json
```
