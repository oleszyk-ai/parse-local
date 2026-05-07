"""
Core scraping logic using ScrapeGraphAI with local GGUF model.
"""

import json
from typing import Any, Optional

from scrapegraphai.graphs import SmartScraperGraph
from rich.console import Console

from app.config import (
    MODEL_PATH,
    N_GPU_LAYERS,
    N_CTX,
    TEMPERATURE,
    MAX_TOKENS,
    VERBOSE_LLM,
    HEADLESS,
)

console = Console()

# Singleton-ish: cache the model path string after validation
_model_path_str: Optional[str] = None


def get_model_path() -> str:
    global _model_path_str
    if _model_path_str is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Model not found at {MODEL_PATH}. Run setup first."
            )
        _model_path_str = str(MODEL_PATH)
    return _model_path_str


def build_graph_config(source_type: str = "url") -> dict:
    """
    Build the ScrapeGraphAI configuration dict for local GGUF model.
    """
    model_path = get_model_path()

    graph_config = {
        "llm": {
            "model": f"llama-cpp/{MODEL_PATH.stem}",
            "model_path": model_path,
            "temperature": TEMPERATURE,
            "n_ctx": N_CTX,
            "n_gpu_layers": N_GPU_LAYERS,
            "max_tokens": MAX_TOKENS,
            "verbose": VERBOSE_LLM,
        },
        "embeddings": {
            "model": "ollama/nomic-embed-text",  # fallback if needed
        },
        "verbose": VERBOSE_LLM,
        "headless": HEADLESS,
    }

    # For local models, we can skip embeddings and use a simpler pipeline
    # ScrapeGraphAI SmartScraperGraph doesn't always need embeddings
    # Remove embeddings config to avoid dependency on Ollama
    if "embeddings" in graph_config:
        del graph_config["embeddings"]

    return graph_config


def scrape_url(url: str, prompt: str) -> dict[str, Any]:
    """
    Scrape a URL and extract structured data based on the prompt.

    Args:
        url: The URL to scrape
        prompt: What data to extract (e.g., "Extract all product names and prices")

    Returns:
        Extracted data as a dictionary
    """
    console.print(f"[blue]🔍[/blue] Scraping: {url}")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    graph_config = build_graph_config()

    try:
        scraper = SmartScraperGraph(
            prompt=prompt,
            source=url,
            config=graph_config,
        )

        result = scraper.run()

        console.print(f"[green]✓[/green] Extraction complete")
        return {
            "success": True,
            "data": result,
            "url": url,
            "prompt": prompt,
        }

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
    Extract structured data from raw HTML content.

    Args:
        html: Raw HTML string
        prompt: What data to extract

    Returns:
        Extracted data as a dictionary
    """
    console.print(f"[blue]📝[/blue] Processing HTML ({len(html)} chars)")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    graph_config = build_graph_config(source_type="html")

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