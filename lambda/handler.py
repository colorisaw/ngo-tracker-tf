"""
NGO Tracker API — auditoria de doações e gastos de ONGs.

Rotas:
  GET  /                              health
  GET  /ngos                          listar ONGs
  POST /ngos                          criar ONG
  GET  /ngos/{id}                     perfil + resumo financeiro
  GET  /ngos/{id}/donations           listar doações
  POST /ngos/{id}/donations           registrar doação
  GET  /ngos/{id}/expenses            listar gastos
  POST /ngos/{id}/expenses            registrar gasto
  POST /ngos/{id}/receipts            upload de comprovante (base64) → S3
"""

import os

from http_utils import cors_preflight_response, error_response, json_response, match_route, parse_event
import repository as repo


def handler(event, context):
    try:
        method, path, body = parse_event(event or {})

        if method == "OPTIONS":
            return cors_preflight_response()

        route, params = match_route(path)

        if route is None:
            return error_response(404, "Rota não encontrada", path=path)

        if route == "health":
            return json_response(
                200,
                {
                    "service": "ngo-tracker-api",
                    "environment": os.environ.get("ENVIRONMENT", "unknown"),
                    "ok": True,
                },
            )

        if route == "ngos_collection":
            if method == "GET":
                ngos = repo.list_ngos()
                return json_response(200, {"ngos": ngos, "count": len(ngos)})
            if method == "POST":
                name = (body.get("name") or "").strip()
                if not name:
                    return error_response(400, "Campo 'name' é obrigatório")
                ngo = repo.create_ngo(
                    name=name,
                    description=(body.get("description") or "").strip(),
                    city=(body.get("city") or "").strip(),
                )
                return json_response(201, {"ngo": ngo})
            return error_response(405, "Método não permitido", allowed=["GET", "POST"])

        ngo_id = params.get("ngo_id", "")
        if not repo.get_ngo(ngo_id):
            return error_response(404, "ONG não encontrada", ngo_id=ngo_id)

        if route == "ngo_item" and method == "GET":
            summary = repo.ngo_summary(ngo_id)
            return json_response(
                200,
                {"ngo": repo.get_ngo(ngo_id), "summary": summary},
            )

        if route == "ngo_donations":
            if method == "GET":
                items = repo.list_donations(ngo_id)
                return json_response(200, {"donations": items, "count": len(items)})
            if method == "POST":
                amount = body.get("amount")
                if amount is None or float(amount) <= 0:
                    return error_response(400, "Campo 'amount' deve ser > 0")
                item = repo.create_donation(
                    ngo_id=ngo_id,
                    amount=float(amount),
                    donor_name=(body.get("donor_name") or "").strip(),
                    notes=(body.get("notes") or "").strip(),
                )
                return json_response(201, {"donation": item})
            return error_response(405, "Método não permitido", allowed=["GET", "POST"])

        if route == "ngo_expenses":
            if method == "GET":
                items = repo.list_expenses(ngo_id)
                return json_response(200, {"expenses": items, "count": len(items)})
            if method == "POST":
                amount = body.get("amount")
                category = (body.get("category") or "").strip()
                if amount is None or float(amount) <= 0:
                    return error_response(400, "Campo 'amount' deve ser > 0")
                if not category:
                    return error_response(400, "Campo 'category' é obrigatório")
                item = repo.create_expense(
                    ngo_id=ngo_id,
                    amount=float(amount),
                    category=category,
                    description=(body.get("description") or "").strip(),
                )
                return json_response(201, {"expense": item})
            return error_response(405, "Método não permitido", allowed=["GET", "POST"])

        if route == "ngo_receipts" and method == "POST":
            filename = (body.get("filename") or "receipt.bin").strip()
            content = body.get("content_base64") or ""
            if not content:
                return error_response(400, "Campo 'content_base64' é obrigatório")
            uploaded = repo.upload_receipt(ngo_id, filename, content)
            return json_response(201, {"receipt": uploaded})

        if route == "ngo_receipts":
            return error_response(405, "Método não permitido", allowed=["POST"])

        return error_response(404, "Rota não encontrada", path=path)

    except ValueError as exc:
        return error_response(400, str(exc))
    except Exception as exc:  # noqa: BLE001 — log em CloudWatch na AWS
        return error_response(500, "Erro interno", detail=str(exc))
