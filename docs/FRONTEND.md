# Frontend — NGO Tracker Web

Painel web para ONGs e doadores: listar ONGs, cadastrar, registrar doações/gastos e enviar comprovantes.

Código em `frontend/` — Vite + JavaScript vanilla (sem framework).

---

## Pré-requisitos

- Node.js 18+
- API na AWS com CORS habilitado (`api_gateway.tf` → `cors_configuration`)
- URL da API: `terraform output -raw api_gateway_url`

Após adicionar CORS no Terraform:

```bash
./scripts/terraform-aws.sh apply   # CORS no API Gateway (carrega .env.aws)
```

---

## Rodar localmente

```bash
cd frontend
npm install
cp .env.example .env
# edite .env com VITE_API_URL=https://....amazonaws.com/dev
npm run dev
```

Abra http://localhost:5173

Na primeira visita, configure a **URL da API** em ⚙ Configurações (salva no `localStorage` do navegador).

---

## Publicar na AWS (S3 + CloudFront)

**Pré-requisito:** `use_localstack = false` e `./scripts/terraform-aws.sh apply` (cria bucket + CDN).

```bash
chmod +x scripts/deploy-frontend.sh
./scripts/deploy-frontend.sh
```

O script:
1. Lê `api_gateway_url` do Terraform
2. Roda `npm run build` com `VITE_API_URL` embutido
3. Faz upload para `s3://ngo-tracker-dev-web/`
4. Invalida cache do CloudFront

URL pública:

```bash
./scripts/terraform-aws.sh output -raw cloudfront_url
```

Infra em `frontend_hosting.tf` (S3 privado + OAC + CloudFront). Bucket **separado** de `ngo-tracker-dev-data` (comprovantes).

---

## Build para produção (manual)

```bash
cd frontend
VITE_API_URL="$(cd .. && ./scripts/terraform-aws.sh output -raw api_gateway_url)" npm run build
npm run preview   # testar dist/ em http://localhost:4173
```

Artefatos em `frontend/dist/`.

---

## Telas

| Rota | Função |
|------|--------|
| `#/` | Lista ONGs + formulário de cadastro |
| `#/ngos/{id}` | Resumo financeiro, doações, gastos, upload de comprovante |
| Configurações | URL da API |

---

## Variáveis

| Arquivo | Uso |
|---------|-----|
| `frontend/.env` | `VITE_API_URL` — default no dev (gitignored) |
| `localStorage` | `ngo-tracker-api-url` — override pela UI |

---

## CORS

O navegador exige CORS no API Gateway (não basta header na Lambda). O Terraform configura:

```hcl
cors_configuration {
  allow_origins = ["*"]
  allow_methods = ["GET", "POST", "OPTIONS"]
  allow_headers = ["content-type"]
}
```

Se requests falharem no browser mas `curl` funcionar → rode `terraform apply` após atualizar `api_gateway.tf`.

---

## Documentação relacionada

- [API.md](API.md) — rotas REST
- [DEPLOY_AWS.md](DEPLOY_AWS.md) — deploy da infra
- [POSTMAN.md](POSTMAN.md) — testes HTTP
