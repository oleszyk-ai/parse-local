"""
Configuration management for Parse-Local.
All settings in one place, overridable via environment variables.
"""

import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = BASE_DIR / "models"
FRONTEND_DIR = BASE_DIR / "frontend"

# Model settings
MODEL_FILENAME = os.getenv(
    "MODEL_FILENAME",
    "Qwen2.5-14B-Instruct-Q4_K_M.gguf"
)
MODEL_REPO_ID = os.getenv(
    "MODEL_REPO_ID",
    "bartowski/Qwen2.5-14B-Instruct-GGUF"
)
MODEL_PATH = MODELS_DIR / MODEL_FILENAME

# LLM settings
N_GPU_LAYERS = int(os.getenv("N_GPU_LAYERS", "-1"))  # -1 = all layers on GPU
N_CTX = int(os.getenv("N_CTX", "8192"))
TEMPERATURE = float(os.getenv("TEMPERATURE", "0.1"))
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "4096"))
VERBOSE_LLM = os.getenv("VERBOSE_LLM", "false").lower() == "true"

# Server settings
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))

# Scraping settings
HEADLESS = os.getenv("HEADLESS", "true").lower() == "true"
