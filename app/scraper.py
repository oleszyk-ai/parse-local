"""
Core scraping logic using ScrapeGraphAI with local GGUF model.
Uses httpx instead of Playwright to avoid DLL issues on locked-down Windows.
"""

from typing import Any
from rich.console import Console
from scrapegraphai.graphs import SmartScraperGraph

from app.config import (
    MODEL_PATH,
    N_GPU_LAYERS,
    N_CTX,
    TEMPERATURE,
    MAX_TOKENS,
    VERBOSE_LLM,
)

console = Console()


def build_graph_config() -> dict:
    return {
        "llm": {
            "model": f"llama-cpp/{MODEL_PATH.stem}",
            "model_path": str(MODEL_PATH),
            "temperature": TEMPERATURE,
            "n_ctx": N_CTX,
            "n_gpu_layers": N_GPU_LAYERS,
            "max_tokens": MAX_TOKENS,
            "verbose": VERBOSE_LLM,
        },
        "verbose": VERBOSE_LLM,
        "headless": True,
        "playwright_chromium_args": [],
        # Use requests-based fetching instead of playwright
        "loader_kwargs": {
            "requests_per_second": 1,
        },
    }


def fetch_page(url: str) -> str:
    """
    Fetch a URL using httpx instead of Playwright.
    Avoids Device Guard DLL issues on locked-down Windows machines.
    """
    import httpx
    from bs4 import BeautifulSoup

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        )
    }

    console.print(f"[blue]🌐[/blue] Fetching: {url}")

    with httpx.Client(follow_redirects=True, timeout=30, headers=headers) as client:
        response = client.get(url)
        response.raise_for_status()

    # Parse and clean HTML
    soup = BeautifulSoup(response.text, "html.parser")

    # Remove junk tags
    for tag in soup(["script", "style", "nav", "footer", "head", "meta", "link"]):
        tag.decompose()

    clean_html = str(soup)
    console.print(f"[green]✓[/green] Page fetched ({len(clean_html)} chars)")
    return clean_html


def scrape_url(url: str, prompt: str) -> dict[str, Any]:
    """
    Fetch a URL and extract structured data using local LLM.
    """
    console.print(f"[blue]🔍[/blue] Scraping: {url}")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    try:
        # Fetch page ourselves — no Playwright needed
        html = fetch_page(url)
        return scrape_html(html, prompt)

    except Exception as e:
        console.print(f"[red]✗[/red] Scraping failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "url": url,
            "prompt": prompt,
        }


def scrape_html(html: str, prompt: str) -> dict[str, Any]:
    """
    Extract structured data from raw HTML using local LLM.
    """
    console.print(f"[blue]📝[/blue] Processing HTML ({len(html)} chars)")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    graph_config = build_graph_config()

    try:
        scraper = SmartScraperGraph(
            prompt=prompt,
            source=html,
            config=graph_config,
        )

        result = scraper.run()

        console.print(f"[green]✓[/green] Extraction complete")
        return {
            "success": True,
            "data": result,
            "prompt": prompt,
        }

    except Exception as e:
        console.print(f"[red]✗[/red] Extraction failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "prompt": prompt,
        }
