from __future__ import annotations

import os
import secrets
from typing import Optional

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, HttpUrl

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


class ShortenResponse(BaseModel):
    code: str
    short_url: str


@app.get("/api/health/ready")
def ready() -> dict:
    # Keep health check lightweight and dependency-free.
    return {"status": "ok"}


def _generate_code() -> str:
    # Collisions are extremely unlikely; we still handle collision defensively.
    return secrets.token_urlsafe(6).replace("-", "").replace("_", "")[:8]


def _put_mapping(short_code: str, original_url: str) -> None:
    table.put_item(
        Item={
            "short_code": short_code,
            "original_url": original_url,
        },
        # Prevent overwriting if a collision happens.
        ConditionExpression="attribute_not_exists(short_code)",
    )


def _get_mapping(short_code: str) -> Optional[str]:
    resp = table.get_item(Key={"short_code": short_code})
    item = resp.get("Item")
    if not item:
        return None
    return item.get("original_url")


@app.post("/api/shorten", response_model=ShortenResponse)
def shorten(req: ShortenRequest) -> ShortenResponse:
    # Optional: allow overriding the base URL via env var (useful for prod ALB DNS)
    base_url = os.getenv("BASE_URL", "").rstrip("/")

    # Try a few times in the unlikely case of a code collision.
    for _ in range(5):
        code = _generate_code()
        try:
            _put_mapping(code, str(req.url))
            short_url = f"{base_url}/{code}" if base_url else f"/{code}"
            return ShortenResponse(code=code, short_url=short_url)
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
        url = _get_mapping(code)
    except ClientError as e:
        raise HTTPException(status_code=500, detail="Failed to read URL mapping") from e

    if not url:
        raise HTTPException(status_code=404, detail="Short code not found")

    return RedirectResponse(url=url, status_code=307)