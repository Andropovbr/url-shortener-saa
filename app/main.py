from __future__ import annotations

import os
import secrets
from typing import Dict

from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from pydantic import BaseModel, HttpUrl

app = FastAPI(title="URL Shortener (MVP)")

# In-memory storage (MVP only). This will reset on task restart and won't be shared across tasks.
URL_STORE: Dict[str, str] = {}


class ShortenRequest(BaseModel):
    url: HttpUrl


class ShortenResponse(BaseModel):
    code: str
    short_url: str


@app.get("/api/health/ready")
def ready() -> dict:
    return {"status": "ok"}


@app.post("/api/shorten", response_model=ShortenResponse)
def shorten(req: ShortenRequest) -> ShortenResponse:
    # Create a short code. Collisions are extremely unlikely for this MVP.
    code = secrets.token_urlsafe(6).replace("-", "").replace("_", "")[:8]
    URL_STORE[code] = str(req.url)

    # Optional: allow overriding the base URL via env var (useful for prod ALB DNS)
    base_url = os.getenv("BASE_URL", "").rstrip("/")
    short_url = f"{base_url}/{code}" if base_url else f"/{code}"

    return ShortenResponse(code=code, short_url=short_url)


@app.get("/{code}")
def redirect(code: str):
    url = URL_STORE.get(code)
    if not url:
        raise HTTPException(status_code=404, detail="Short code not found")

    # 307 keeps method (safe default). 302 is also fine for typical shorteners.
    return RedirectResponse(url=url, status_code=307)