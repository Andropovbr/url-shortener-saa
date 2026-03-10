from __future__ import annotations

import json
import logging
import os
import secrets
import time
from typing import Any, Optional

import boto3
import redis
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, Field, HttpUrl

app = FastAPI(title="URL Shortener (MVP)")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
DDB_TABLE_NAME = os.getenv("DDB_TABLE_NAME")

REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_AUTH_TOKEN = os.getenv("REDIS_AUTH_TOKEN")
CACHE_ENABLED = os.getenv("CACHE_ENABLED", "false").lower() == "true"
CACHE_DEFAULT_TTL_SECONDS = int(os.getenv("CACHE_DEFAULT_TTL_SECONDS", "300"))

if not DDB_TABLE_NAME:
    raise RuntimeError("Missing required env var: DDB_TABLE_NAME")

ddb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = ddb.Table(DDB_TABLE_NAME)

redis_client: Optional[redis.Redis] = None

if CACHE_ENABLED:
    try:
        redis_client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_AUTH_TOKEN,
            ssl=True,
            decode_responses=True,
            socket_connect_timeout=2,
            socket_timeout=2,
        )

        redis_client.ping()
        logger.info("Redis connection established successfully.")
    except Exception as e:
        logger.warning("Redis init failed. Cache disabled. error=%s", e)
        redis_client = None


class ShortenRequest(BaseModel):
    url: HttpUrl
    expires_at: Optional[int] = Field(default=None)


class ShortenResponse(BaseModel):
    code: str
    short_url: str
    expires_at: Optional[int] = None


@app.get("/api/test-error")
def test_error():
    raise HTTPException(status_code=500, detail="Intentional test error")


@app.get("/api/health/ready")
def ready() -> dict:
    return {"status": "ok"}


def _generate_code() -> str:
    return secrets.token_urlsafe(6).replace("-", "").replace("_", "")[:8]


def _put_mapping(short_code: str, original_url: str, expires_at: Optional[int] = None):
    item = {"short_code": short_code, "original_url": original_url}

    if expires_at:
        item["expires_at"] = expires_at

    table.put_item(
        Item=item,
        ConditionExpression="attribute_not_exists(short_code)",
    )


def _get_mapping(short_code: str):
    resp = table.get_item(Key={"short_code": short_code})
    return resp.get("Item")


def _is_expired(item):
    expires_at = item.get("expires_at")

    if expires_at is None:
        return False

    return int(expires_at) <= int(time.time())


def _cache_key(code: str):
    return f"url:{code}"


def _get_from_cache(code: str):

    if not redis_client:
        return None

    try:
        raw = redis_client.get(_cache_key(code))

        if raw is None:
            logger.info("cache_miss code=%s", code)
            return None

        logger.info("cache_hit code=%s", code)
        return json.loads(raw)

    except Exception as e:
        logger.warning("cache_error read code=%s error=%s", code, e)
        return None


def _set_in_cache(code: str, item):

    if not redis_client:
        return

    expires_at = item.get("expires_at")

    if expires_at:
        remaining = int(expires_at) - int(time.time())

        if remaining <= 0:
            return

        ttl = min(CACHE_DEFAULT_TTL_SECONDS, remaining)
    else:
        ttl = CACHE_DEFAULT_TTL_SECONDS

    payload = {
        "original_url": item["original_url"],
        "expires_at": item.get("expires_at"),
    }

    try:
        redis_client.setex(_cache_key(code), ttl, json.dumps(payload))
        logger.info("cache_write code=%s ttl=%s", code, ttl)
    except Exception as e:
        logger.warning("cache_error write code=%s error=%s", code, e)


@app.post("/api/shorten", response_model=ShortenResponse)
def shorten(req: ShortenRequest):

    base_url = os.getenv("BASE_URL", "").rstrip("/")

    if req.expires_at and req.expires_at <= int(time.time()):
        raise HTTPException(
            status_code=400,
            detail="expires_at must be in the future",
        )

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
                continue

            raise HTTPException(status_code=500, detail="Failed to store URL mapping")

    raise HTTPException(status_code=500, detail="Failed to generate unique code")


@app.get("/{code}")
def redirect(code: str):

    cached = _get_from_cache(code)

    if cached:

        if _is_expired(cached):
            raise HTTPException(status_code=410, detail="Short code expired")

        return RedirectResponse(url=cached["original_url"], status_code=307)

    try:
        item = _get_mapping(code)
    except ClientError:
        raise HTTPException(status_code=500, detail="Failed to read mapping")

    if not item:
        raise HTTPException(status_code=404, detail="Short code not found")

    if _is_expired(item):
        raise HTTPException(status_code=410, detail="Short code expired")

    _set_in_cache(code, item)

    return RedirectResponse(url=item["original_url"], status_code=307)