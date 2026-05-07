"""
Handles downloading and verifying the GGUF model file.
"""

from pathlib import Path
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, DownloadColumn, TransferSpeedColumn
from huggingface_hub import hf_hub_download

from app.config import MODELS_DIR, MODEL_REPO_ID, MODEL_FILENAME, MODEL_PATH

console = Console()


def ensure_model_exists() -> Path:
    """
    Check if the model file exists. If not, download it from HuggingFace.
    Returns the path to the model file.
    """
    MODELS_DIR.mkdir(parents=True, exist_ok=True)

    if MODEL_PATH.exists():
        size_gb = MODEL_PATH.stat().st_size / (1024 ** 3)
        console.print(
            f"[green]✓[/green] Model found: {MODEL_FILENAME} ({size_gb:.1f} GB)"
        )
        return MODEL_PATH

    console.print(f"[yellow]⬇[/yellow] Model not found locally. Downloading...")
    console.print(f"  Repo:  {MODEL_REPO_ID}")
    console.print(f"  File:  {MODEL_FILENAME}")
    console.print(f"  This is ~7 GB. Please be patient.\n")

    try:
        downloaded_path = hf_hub_download(
            repo_id=MODEL_REPO_ID,
            filename=MODEL_FILENAME,
            local_dir=str(MODELS_DIR),
            local_dir_use_symlinks=False,
        )
        console.print(f"[green]✓[/green] Download complete: {downloaded_path}")
        return Path(downloaded_path)

    except Exception as e:
        console.print(f"[red]✗[/red] Download failed: {e}")
        console.print("\n[yellow]Manual download instructions:[/yellow]")
        console.print(
            f"  1. Go to https://huggingface.co/{MODEL_REPO_ID}"
        )
        console.print(f"  2. Download {MODEL_FILENAME}")
        console.print(f"  3. Place it in the 'models/' directory")
        raise SystemExit(1)