#!/usr/bin/env python3
"""
Parse-Local — One command to rule them all.

Usage:
    python start.py          # Setup (if needed) + start server
    python start.py --setup  # Force re-run setup
    python start.py --run    # Skip setup, just run
"""

import subprocess
import sys
import os
import platform
from pathlib import Path

# ─── Config ───────────────────────────────────────────────────
VENV_DIR = Path(".venv")
MODELS_DIR = Path("models")
MODEL_NAME = "Mistral-Nemo-Instruct-2407-Q4_K_M.gguf"
REQUIREMENTS = Path("requirements.txt")

IS_WINDOWS = platform.system() == "Windows"
IS_MAC = platform.system() == "Darwin"
IS_LINUX = platform.system() == "Linux"
IS_ARM_MAC = IS_MAC and platform.machine() == "arm64"


# ─── Colors ───────────────────────────────────────────────────
class C:
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    END = "\033[0m"

    @staticmethod
    def init():
        # Enable colors on Windows
        if IS_WINDOWS:
            os.system("color")


def print_step(num, total, msg):
    print(f"\n{C.YELLOW}[{num}/{total}]{C.END} {C.BOLD}{msg}{C.END}")


def print_ok(msg):
    print(f"{C.GREEN}✓{C.END} {msg}")


def print_err(msg):
    print(f"{C.RED}✗{C.END} {msg}")


def print_info(msg):
    print(f"{C.CYAN}→{C.END} {msg}")


def print_banner():
    print(f"""
{C.CYAN}╔══════════════════════════════════════════╗
║           🔍 Parse-Local                 ║
║     Local AI Web Scraper                 ║
╚══════════════════════════════════════════╝{C.END}
""")


# ─── Helpers ──────────────────────────────────────────────────
def get_venv_python() -> Path:
    if IS_WINDOWS:
        return VENV_DIR / "Scripts" / "python.exe"
    return VENV_DIR / "bin" / "python"


def run(cmd: list, check: bool = True) -> subprocess.CompletedProcess:
    """Run a command, streaming output."""
    try:
        result = subprocess.run(cmd, check=check)
        return result
    except subprocess.CalledProcessError as e:
        print_err(f"Command failed: {' '.join(cmd)}")
        raise


def pip_install(packages: list, extra_index: str = None):
    """Install packages using pip."""
    venv_py = get_venv_python()
    cmd = [str(venv_py), "-m", "pip", "install"] + packages
    if extra_index:
        cmd.extend(["--extra-index-url", extra_index])
    run(cmd)


def check_nvidia_gpu() -> tuple[bool, str]:
    """Check if NVIDIA GPU is available and get CUDA version."""
    try:
        result = subprocess.run(
            ["nvidia-smi"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            # Extract CUDA version
            for line in result.stdout.split("\n"):
                if "CUDA Version" in line:
                    parts = line.split("CUDA Version:")
                    if len(parts) > 1:
                        version = parts[1].strip().split()[0]
                        return True, version
            return True, ""
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return False, ""


def is_setup_needed() -> bool:
    """Check if we need to run setup."""
    venv_py = get_venv_python()
    model_path = MODELS_DIR / MODEL_NAME

    if not VENV_DIR.exists():
        print_info("Virtual environment not found")
        return True

    if not venv_py.exists():
        print_info("Python executable not found in venv")
        return True

    # Check if key packages are installed
    try:
        result = subprocess.run(
            [str(venv_py), "-c", "import scrapegraphai, llama_cpp, fastapi"],
            capture_output=True,
            timeout=30
        )
        if result.returncode != 0:
            print_info("Required packages not installed")
            return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return True

    if not model_path.exists():
        print_info("Model not downloaded yet")
        return True

    return False


# ─── Setup Steps ──────────────────────────────────────────────
def setup_venv():
    """Create virtual environment."""
    print_step(1, 5, "Creating virtual environment")

    if VENV_DIR.exists():
        print_ok("Already exists")
        return

    run([sys.executable, "-m", "venv", str(VENV_DIR)])
    print_ok("Created .venv")


def setup_pip():
    """Upgrade pip."""
    print_step(2, 5, "Upgrading pip")
    venv_py = get_venv_python()
    run([str(venv_py), "-m", "pip", "install", "--upgrade", "pip", "-q"])
    print_ok("Pip upgraded")


def setup_llama_cpp():
    """Install llama-cpp-python with correct backend."""
    print_step(3, 5, "Installing llama-cpp-python")

    has_nvidia, cuda_version = check_nvidia_gpu()

    if has_nvidia:
        print_info(f"NVIDIA GPU detected! CUDA {cuda_version}")
        print_info("Installing CUDA version (faster inference)")

        # Select correct CUDA wheel
        cuda_index = "https://abetlen.github.io/llama-cpp-python/whl/cu124"
        if cuda_version.startswith("12.1"):
            cuda_index = "https://abetlen.github.io/llama-cpp-python/whl/cu121"
        elif cuda_version.startswith("12.2"):
            cuda_index = "https://abetlen.github.io/llama-cpp-python/whl/cu122"
        elif cuda_version.startswith("12.3"):
            cuda_index = "https://abetlen.github.io/llama-cpp-python/whl/cu123"

        try:
            pip_install(["llama-cpp-python"], extra_index=cuda_index)
            print_ok("Installed (CUDA)")
            _write_env("N_GPU_LAYERS=-1")
            return
        except subprocess.CalledProcessError:
            print_info("CUDA install failed, trying CPU fallback...")

    elif IS_ARM_MAC:
        print_info("Apple Silicon detected!")
        print_info("Installing Metal version (faster inference)")

        metal_index = "https://abetlen.github.io/llama-cpp-python/whl/metal"
        try:
            pip_install(["llama-cpp-python"], extra_index=metal_index)
            print_ok("Installed (Metal)")
            _write_env("N_GPU_LAYERS=-1")
            return
        except subprocess.CalledProcessError:
            print_info("Metal install failed, trying CPU fallback...")

    # CPU fallback
    print_info("Installing CPU version")
    cpu_index = "https://abetlen.github.io/llama-cpp-python/whl/cpu"
    pip_install(["llama-cpp-python"], extra_index=cpu_index)
    print_ok("Installed (CPU)")
    _write_env("N_GPU_LAYERS=0")


def _write_env(content: str):
    """Write .env file if it doesn't exist."""
    env_path = Path(".env")
    if not env_path.exists():
        env_path.write_text(content + "\n")
        print_info(f"Created .env with {content}")


def setup_dependencies():
    """Install remaining dependencies."""
    print_step(4, 5, "Installing dependencies")

    if not REQUIREMENTS.exists():
        print_err("requirements.txt not found!")
        sys.exit(1)

    pip_install(["-r", str(REQUIREMENTS)])
    print_ok("All dependencies installed")

def setup_model():
    """Download the model."""
    print_step(5, 5, "Checking model")

    model_path = MODELS_DIR / MODEL_NAME

    if model_path.exists():
        size_gb = model_path.stat().st_size / (1024**3)
        print_ok(f"Model found ({size_gb:.1f} GB)")
        return

    print_info(f"Downloading {MODEL_NAME} (~7 GB)...")
    print_info("This may take a while on first run.")

    venv_py = get_venv_python()
    run([
        str(venv_py), "-c",
        "from app.model_manager import ensure_model_exists; ensure_model_exists()"
    ])

    print_ok("Model ready")


def run_setup():
    """Run full setup."""
    setup_venv()
    setup_pip()
    setup_llama_cpp()
    setup_dependencies()
    setup_model()

    print(f"""
{C.GREEN}╔══════════════════════════════════════════╗
║          Setup Complete! 🎉              ║
╚══════════════════════════════════════════╝{C.END}
""")


# ─── Server ───────────────────────────────────────────────────
def start_server():
    """Start the FastAPI server."""
    print(f"""
{C.CYAN}Starting server...{C.END}
{C.GREEN}→ Open http://localhost:8000 in your browser{C.END}
{C.YELLOW}→ Press Ctrl+C to stop{C.END}
""")

    venv_py = get_venv_python()

    try:
        run([str(venv_py), "-m", "app.main"])
    except KeyboardInterrupt:
        print(f"\n{C.YELLOW}Server stopped.{C.END}")


# ─── Main ─────────────────────────────────────────────────────
def main():
    C.init()
    print_banner()

    # Parse args
    args = sys.argv[1:]
    force_setup = "--setup" in args
    skip_setup = "--run" in args

    # Check Python version
    if sys.version_info < (3, 10):
        print_err("Python 3.10+ required")
        print_info(f"You have Python {sys.version_info.major}.{sys.version_info.minor}")
        sys.exit(1)

    # Setup if needed
    if force_setup or (not skip_setup and is_setup_needed()):
        print_info("Running setup...")
        run_setup()
    else:
        print_ok("Setup already complete")

    # Start server
    start_server()


if __name__ == "__main__":
    main()
