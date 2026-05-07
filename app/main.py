"""
FastAPI application — serves the API and frontend.
"""

import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel, HttpUrl
from rich.console import Console

from app.config import HOST, PORT, FRONTEND_DIR
from app.model_manager import ensure_model_exists
from app.scraper import scrape_url, scrape_html

console = Console()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: ensure model is downloaded."""
    console.print("\n[bold cyan]═══ Parse-Local Starting ═══[/bold cyan]\n")
    ensure_model_exists()
    console.print(f"\n[bold green]✓ Ready![/bold green]  →  http://localhost:{PORT}\n")
    yield
    console.print("\n[bold cyan]═══ Parse-Local Stopped ═══[/bold cyan]\n")


app = FastAPI(
    title="Parse-Local",
    description="Local AI-powered web scraper — like Parse.bot but fully local",
    version="1.0.0",
    lifespan=lifespan,
)


# ── Request / Response Models ─────────────────────────────────────

class ScrapeURLRequest(BaseModel):
    url: str
    prompt: str = "Extract all the main data from this page in a structured format"

class ScrapeHTMLRequest(BaseModel):
    html: str
    prompt: str = "Extract all the main data from this content in a structured format"

class ScrapeResponse(BaseModel):
    success: bool
    data: dict | list | None = None
    error: str | None = None
    url: str | None = None
    prompt: str
    elapsed_seconds: float


# ── API Routes ────────────────────────────────────────────────────

@app.post("/api/scrape/url", response_model=ScrapeResponse)
async def api_scrape_url(request: ScrapeURLRequest):
    """Scrape a URL and extract structured data."""
    start = time.time()
    result = scrape_url(str(request.url), request.prompt)
    elapsed = round(time.time() - start, 2)

    if not result["success"]:
        return ScrapeResponse(
            success=False,
            error=result.get("error"),
            url=str(request.url),
            prompt=request.prompt,
            elapsed_seconds=elapsed,
        )

    return ScrapeResponse(
        success=True,
        data=result["data"],
        url=str(request.url),
        prompt=request.prompt,
        elapsed_seconds=elapsed,
    )


@app.post("/api/scrape/html", response_model=ScrapeResponse)
async def api_scrape_html(request: ScrapeHTMLRequest):
    """Extract structured data from raw HTML."""
    start = time.time()
    result = scrape_html(request.html, request.prompt)
    elapsed = round(time.time() - start, 2)

    if not result["success"]:
        return ScrapeResponse(
            success=False,
            error=result.get("error"),
            prompt=request.prompt,
            elapsed_seconds=elapsed,
        )

    return ScrapeResponse(
        success=True,
        data=result["data"],
        prompt=request.prompt,
        elapsed_seconds=elapsed,
    )


@app.get("/api/health")
async def health():
    return {"status": "ok", "model": "Mistral-Nemo-Instruct-2407-Q4_K_M"}


# ── Serve Frontend ───────────────────────────────────────────────

app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR)), name="static")


@app.get("/")
async def serve_frontend():
    return FileResponse(str(FRONTEND_DIR / "index.html"))


# ── CLI Entry Point ──────────────────────────────────────────────

def start_server():
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=HOST,
        port=PORT,
        reload=False,
        log_level="info",
    )


if __name__ == "__main__":
    start_server()
