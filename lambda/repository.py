"""Persistência NGO Tracker — DynamoDB single-table + S3."""

import base64
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

import boto3
from boto3.dynamodb.conditions import Key


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _table():
    endpoint = os.environ.get("AWS_ENDPOINT_URL") or None
    resource = boto3.resource(
        "dynamodb",
        **({"endpoint_url": endpoint} if endpoint else {}),
    )
    return resource.Table(os.environ["DYNAMODB_TABLE"])


def _s3():
    endpoint = os.environ.get("AWS_ENDPOINT_URL") or None
    return boto3.client(
        "s3",
        **({"endpoint_url": endpoint} if endpoint else {}),
    )


def _ngo_pk(ngo_id: str) -> str:
    return f"NGO#{ngo_id}"


def _to_float(value: Any) -> float:
    if isinstance(value, Decimal):
        return float(value)
    return float(value)


def create_ngo(name: str, description: str = "", city: str = "") -> dict[str, Any]:
    ngo_id = str(uuid.uuid4())
    item = {
        "pk": _ngo_pk(ngo_id),
        "sk": "PROFILE",
        "entity_type": "NGO",
        "ngo_id": ngo_id,
        "name": name,
        "description": description,
        "city": city,
        "verified": False,
        "created_at": _now_iso(),
    }
    _table().put_item(Item=item)
    return item


def get_ngo(ngo_id: str) -> dict[str, Any] | None:
    resp = _table().get_item(Key={"pk": _ngo_pk(ngo_id), "sk": "PROFILE"})
    return resp.get("Item")


def list_ngos() -> list[dict[str, Any]]:
    resp = _table().query(
        IndexName="entity-type-index",
        KeyConditionExpression=Key("entity_type").eq("NGO") & Key("sk").eq("PROFILE"),
    )
    return resp.get("Items", [])


def list_donations(ngo_id: str) -> list[dict[str, Any]]:
    resp = _table().query(
        KeyConditionExpression=Key("pk").eq(_ngo_pk(ngo_id))
        & Key("sk").begins_with("DONATION#"),
    )
    return resp.get("Items", [])


def list_expenses(ngo_id: str) -> list[dict[str, Any]]:
    resp = _table().query(
        KeyConditionExpression=Key("pk").eq(_ngo_pk(ngo_id))
        & Key("sk").begins_with("EXPENSE#"),
    )
    return resp.get("Items", [])


def create_donation(
    ngo_id: str,
    amount: float,
    donor_name: str = "",
    notes: str = "",
) -> dict[str, Any]:
    donation_id = str(uuid.uuid4())
    item = {
        "pk": _ngo_pk(ngo_id),
        "sk": f"DONATION#{donation_id}",
        "entity_type": "DONATION",
        "ngo_id": ngo_id,
        "donation_id": donation_id,
        "amount": Decimal(str(amount)),
        "donor_name": donor_name,
        "notes": notes,
        "created_at": _now_iso(),
    }
    _table().put_item(Item=item)
    return item


def create_expense(
    ngo_id: str,
    amount: float,
    category: str,
    description: str = "",
) -> dict[str, Any]:
    expense_id = str(uuid.uuid4())
    item = {
        "pk": _ngo_pk(ngo_id),
        "sk": f"EXPENSE#{expense_id}",
        "entity_type": "EXPENSE",
        "ngo_id": ngo_id,
        "expense_id": expense_id,
        "amount": Decimal(str(amount)),
        "category": category,
        "description": description,
        "created_at": _now_iso(),
    }
    _table().put_item(Item=item)
    return item


def ngo_summary(ngo_id: str) -> dict[str, Any]:
    donations = list_donations(ngo_id)
    expenses = list_expenses(ngo_id)
    total_donations = sum(_to_float(d["amount"]) for d in donations)
    total_expenses = sum(_to_float(e["amount"]) for e in expenses)
    return {
        "donation_count": len(donations),
        "expense_count": len(expenses),
        "total_donations": total_donations,
        "total_expenses": total_expenses,
        "balance": total_donations - total_expenses,
    }


def upload_receipt(
    ngo_id: str,
    filename: str,
    content_base64: str,
) -> dict[str, Any]:
    bucket = os.environ["S3_BUCKET"]
    safe_name = filename.replace("/", "_").replace("\\", "_") or "receipt.bin"
    key = f"ngos/{ngo_id}/receipts/{uuid.uuid4()}-{safe_name}"
    body = base64.b64decode(content_base64)
    _s3().put_object(Bucket=bucket, Key=key, Body=body)
    return {"bucket": bucket, "key": key, "size_bytes": len(body)}
