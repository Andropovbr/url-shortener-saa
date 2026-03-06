from __future__ import annotations

import os
import secrets
import time
from typing import Any, Optional

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, Field, HttpUrl

app = FastAPI(title="URL Shortener (MVP)")

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DDB_TABLE_NAME = os.getenv("DDB_TABLE_NAME")

if not DDB_TABLE_NAME:
    # Fail fast so misconfiguration is obvious in ECS logs.
    raise RuntimeError("Missing required env var: DDB_TABLE_NAME")

ddb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = ddb.Table(DDB_TABLE_NAME)


class ShortenRequest(BaseModel):
    url: HttpUrl
    expires_at: Optional[int] = Field(
        default=None,
        description="Optional Unix timestamp in seconds for URL expiration.",
    )


class ShortenResponse(BaseModel):
    code: str
    short_url: str
    expires_at: Optional[int] = None


@app.get("/api/health/ready")
def ready() -> dict:
    # Keep health check lightweight and dependency-free.
    return {"status": "ok"}


def _generate_code() -> str:
    # Collisions are extremely unlikely; we still handle collision defensively.
    return secrets.token_urlsafe(6).replace("-", "").replace("_", "")[:8]


def _put_mapping(short_code: str, original_url: str, expires_at: Optional[int] = None) -> None:
    item: dict[str, Any] = {
        "short_code": short_code,
        "original_url": original_url,
    }

    # Only include TTL attribute when expiration is requested.
    if expires_at is not None:
        item["expires_at"] = expires_at

    table.put_item(
        Item=item,
        # Prevent overwriting if a collision happens.
        ConditionExpression="attribute_not_exists(short_code)",
    )


def _get_mapping(short_code: str) -> Optional[dict[str, Any]]:
    resp = table.get_item(Key={"short_code": short_code})
    return resp.get("Item")


def _is_expired(item: dict[str, Any]) -> bool:
    expires_at = item.get("expires_at")

    # No TTL attribute means non-expiring URL.
    if expires_at is None:
        return False

    # Defensive conversion in case the value comes back as Decimal/int-compatible.
    return int(expires_at) <= int(time.time())


@app.post("/api/shorten", response_model=ShortenResponse)
def shorten(req: ShortenRequest) -> ShortenResponse:
    # Optional: allow overriding the base URL via env var (useful for prod ALB DNS)
    base_url = os.getenv("BASE_URL", "").rstrip("/")

    # Optional validation: reject clearly invalid expirations for normal usage.
    # Keeping this strict avoids creating already-expired links by accident.
    if req.expires_at is not None and req.expires_at <= int(time.time()):
        raise HTTPException(
            status_code=400,
            detail="expires_at must be a Unix timestamp in the future",
        )

    # Try a few times in the unlikely case of a code collision.
    for _ in range(5):
        code = _generate_code()
        try:
            _put_mapping(code, str(req.url), req.expires_at)
            short_url = f"{base_url}/{code}" if base_url else f"/{code}"
            return ShortenResponse(
                code=code,
                short_url=short_url,
                expires_at=req.expires_at,
            )
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
                # Collision: try a new code.
                continue
            # Surface AWS issues clearly.
            raise HTTPException(status_code=500, detail="Failed to store URL mapping") from e

    raise HTTPException(status_code=500, detail="Failed to generate unique short code")


@app.get("/{code}")
def redirect(code: str):
    try:
        item = _get_mapping(code)
    except ClientError as e:
        raise HTTPException(status_code=500, detail="Failed to read URL mapping") from e

    if not item:
        raise HTTPException(status_code=404, detail="Short code not found")

    if _is_expired(item):
        raise HTTPException(status_code=410, detail="Short code expired")

    url = item.get("original_url")
    if not url:
        raise HTTPException(status_code=500, detail="Stored URL mapping is invalid")

    return RedirectResponse(url=url, status_code=307)