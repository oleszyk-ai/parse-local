"""
Core scraping logic using local GGUF model via llama-cpp-python directly.
ScrapeGraphAI's llama-cpp provider is broken — we call the model ourselves.
"""

import json
import re
from typing import Any
from rich.console import Console
from llama_cpp import Llama
from bs4 import BeautifulSoup
import httpx

from app.config import (
    MODEL_PATH,
    N_GPU_LAYERS,
    N_CTX,
    TEMPERATURE,
    MAX_TOKENS,
    VERBOSE_LLM,
)

console = Console()

# ── Singleton model instance ──────────────────────────────────
_llm: Llama | None = None


def get_llm() -> Llama:
    """Load model once, reuse on every request."""
    global _llm
    if _llm is None:
        console.print(f"[yellow]⏳[/yellow] Loading model into memory...")
        console.print(f"[dim]   {MODEL_PATH.name}[/dim]")
        _llm = Llama(
            model_path=str(MODEL_PATH),
            n_gpu_layers=N_GPU_LAYERS,
            n_ctx=N_CTX,
            verbose=VERBOSE_LLM,
        )
        console.print(f"[green]✓[/green] Model loaded")
    return _llm


def fetch_page(url: str) -> str:
    """
    Fetch a URL using httpx.
    Returns cleaned HTML text.
    """
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

    soup = BeautifulSoup(response.text, "html.parser")

    # Remove junk
    for tag in soup(["script", "style", "nav", "footer", "head", "meta", "link"]):
        tag.decompose()

    # Get plain text — much shorter than HTML, fits in context better
    text = soup.get_text(separator="\n", strip=True)

    # Collapse excessive blank lines
    lines = [line for line in text.splitlines() if line.strip()]
    clean_text = "\n".join(lines)

    console.print(f"[green]✓[/green] Page fetched ({len(clean_text)} chars)")
    return clean_text


def extract_with_llm(content: str, prompt: str) -> Any:
    """
    Send content + prompt to local LLM and get structured JSON back.
    """
    llm = get_llm()

    # Trim content to fit in context window safely
    # Leave room for prompt + response
    max_content_chars = (N_CTX * 3) - 2000
    if len(content) > max_content_chars:
        console.print(f"[yellow]![/yellow] Content trimmed to fit context window")
        content = content[:max_content_chars] + "\n...[trimmed]"

    system_prompt = (
        "You are a web scraping assistant. "
        "You extract structured data from web page content. "
        "Always respond with valid JSON only. "
        "No explanations. No markdown. No code blocks. Just raw JSON."
    )

    user_message = (
        f"Here is the web page content:\n\n"
        f"{content}\n\n"
        f"---\n\n"
        f"Task: {prompt}\n\n"
        f"Respond with valid JSON only."
    )

    console.print(f"[blue]🤖[/blue] Running LLM extraction...")

    response = llm.create_chat_completion(
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message},
        ],
        temperature=TEMPERATURE,
        max_tokens=MAX_TOKENS,
    )

    raw_output = response["choices"][0]["message"]["content"].strip()

    console.print(f"[green]✓[/green] LLM finished")

    return parse_llm_output(raw_output)


def parse_llm_output(raw: str) -> Any:
    """
    Parse LLM output into Python object.
    Handles cases where the model wraps JSON in markdown code blocks.
    """
    # Strip markdown code blocks if present
    raw = raw.strip()
    raw = re.sub(r"^```(?:json)?", "", raw, flags=re.IGNORECASE).strip()
    raw = re.sub(r"```$", "", raw).strip()

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # Return raw string if JSON parsing fails
        console.print(f"[yellow]![/yellow] Could not parse JSON — returning raw text")
        return {"raw": raw}


# ── Public API ────────────────────────────────────────────────

def scrape_url(url: str, prompt: str) -> dict[str, Any]:
    """Fetch a URL and extract structured data."""
    console.print(f"[blue]🔍[/blue] Scraping: {url}")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    try:
        content = fetch_page(url)
        data = extract_with_llm(content, prompt)

        return {
            "success": True,
            "data": data,
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
    """Extract structured data from raw HTML."""
    console.print(f"[blue]📝[/blue] Processing HTML ({len(html)} chars)")
    console.print(f"[blue]📝[/blue] Prompt: {prompt}")

    try:
        # Clean HTML to plain text
        soup = BeautifulSoup(html, "html.parser")
        for tag in soup(["script", "style", "head", "meta", "link"]):
            tag.decompose()
        lines = [l for l in soup.get_text(separator="\n", strip=True).splitlines() if l.strip()]
        content = "\n".join(lines)

        data = extract_with_llm(content, prompt)

        return {
            "success": True,
            "data": data,
            "prompt": prompt,
        }

    except Exception as e:
        console.print(f"[red]✗[/red] Extraction failed: {e}")
        return {
            "success": False,
            "error": str(e),
            "prompt": prompt,
        }
