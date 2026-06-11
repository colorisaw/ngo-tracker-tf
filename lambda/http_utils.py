"""Utilitários HTTP para API Gateway v2 e invoke direto (LocalStack)."""

import base64
import json
import re
from typing import Any


def parse_event(event: dict[str, Any]) -> tuple[str, str, dict[str, Any]]:
    """Retorna (method, path, body_dict)."""
    if "requestContext" in event and "http" in event.get("requestContext", {}):
        http = event["requestContext"]["http"]
        method = http.get("method", "GET").upper()
        path = event.get("rawPath") or http.get("path", "/")
        # API Gateway HTTP API inclui o stage no path (ex.: /dev/ngos → /ngos)
        stage = event.get("requestContext", {}).get("stage")
        if stage and stage != "$default" and path.startswith(f"/{stage}"):
            path = path[len(stage) + 1 :] or "/"
            if not path.startswith("/"):
                path = f"/{path}"
    elif "httpMethod" in event:
        method = event["httpMethod"].upper()
        path = event.get("path", "/")
    else:
        method = "GET"
        path = "/"

    body: dict[str, Any] = {}
    raw = event.get("body") or ""
    if raw:
        if event.get("isBase64Encoded"):
            raw = base64.b64decode(raw).decode("utf-8")
        try:
            body = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"JSON inválido: {exc}") from exc

    return method, path, body


def json_response(status: int, payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(payload, default=str),
    }


def error_response(status: int, message: str, **extra: Any) -> dict[str, Any]:
    body = {"error": message, **extra}
    return json_response(status, body)


ROUTE_PATTERNS = [
    (re.compile(r"^/ngos/?$"), "ngos_collection"),
    (re.compile(r"^/ngos/(?P<ngo_id>[^/]+)/donations/?$"), "ngo_donations"),
    (re.compile(r"^/ngos/(?P<ngo_id>[^/]+)/expenses/?$"), "ngo_expenses"),
    (re.compile(r"^/ngos/(?P<ngo_id>[^/]+)/receipts/?$"), "ngo_receipts"),
    (re.compile(r"^/ngos/(?P<ngo_id>[^/]+)/?$"), "ngo_item"),
    (re.compile(r"^/?$"), "health"),
]


def match_route(path: str) -> tuple[str | None, dict[str, str]]:
    for pattern, name in ROUTE_PATTERNS:
        m = pattern.match(path)
        if m:
            return name, m.groupdict()
    return None, {}
