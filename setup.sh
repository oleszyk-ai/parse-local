#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║        Parse-Local — Setup Script        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Check Python ─────────────────────────────────────────────
echo -e "${YELLOW}[1/5]${NC} Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON=python3
elif command -v python &> /dev/null; then
    PYTHON=python
else
    echo -e "${RED}✗ Python 3.10+ is required but not found.${NC}"
    echo "  Install it from https://python.org"
    exit 1
fi

PY_VERSION=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}✓${NC} Found Python ${PY_VERSION}"
echo ""

# ─── Create venv ──────────────────────────────────────────────
echo -e "${YELLOW}[2/5]${NC} Creating virtual environment..."
if [ ! -d ".venv" ]; then
    $PYTHON -m venv .venv
    echo -e "${GREEN}✓${NC} Virtual environment created"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi
echo ""

# Activate
source .venv/bin/activate

# ─── Upgrade pip ──────────────────────────────────────────────
echo -e "${YELLOW}[3/5]${NC} Installing dependencies..."
echo ""
echo "--- Upgrading pip ---"
pip install --upgrade pip
echo ""

# ─── Detect GPU ───────────────────────────────────────────────
echo "--- Detecting GPU ---"
echo ""

HAS_NVIDIA=0
HAS_METAL=0
CUDA_VERSION=""

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    echo -e "  ${GREEN}NVIDIA GPU detected!${NC}"
    HAS_NVIDIA=1
    
    # Get CUDA version
    CUDA_VERSION=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}' 2>/dev/null || echo "")
    if [ -n "$CUDA_VERSION" ]; then
        echo "  CUDA version: $CUDA_VERSION"
    fi
fi

# Check for Apple Silicon
if [[ "$(uname)" == "Darwin" ]]; then
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        echo -e "  ${GREEN}Apple Silicon detected!${NC}"
        HAS_METAL=1
    fi
fi

if [ $HAS_NVIDIA -eq 0 ] && [ $HAS_METAL -eq 0 ]; then
    echo "  No GPU detected, will use CPU."
fi
echo ""

# ─── Install llama-cpp-python ─────────────────────────────────
echo "--- Installing llama-cpp-python ---"
echo ""

if [ $HAS_NVIDIA -eq 1 ]; then
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║  NVIDIA GPU found! Installing CUDA version    ║"
    echo "  ║  This will be MUCH faster for inference.      ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
    
    # Select CUDA version index
    CUDA_INDEX="https://abetlen.github.io/llama-cpp-python/whl/cu124"
    
    if [[ "$CUDA_VERSION" == 12.1* ]]; then
        CUDA_INDEX="https://abetlen.github.io/llama-cpp-python/whl/cu121"
    elif [[ "$CUDA_VERSION" == 12.2* ]]; then
        CUDA_INDEX="https://abetlen.github.io/llama-cpp-python/whl/cu122"
    elif [[ "$CUDA_VERSION" == 12.3* ]]; then
        CUDA_INDEX="https://abetlen.github.io/llama-cpp-python/whl/cu123"
    fi
    
    echo "  Using CUDA wheel index: $CUDA_INDEX"
    echo ""
    
    if pip install llama-cpp-python --extra-index-url "$CUDA_INDEX"; then
        echo ""
        echo -e "${GREEN}✓${NC} llama-cpp-python (CUDA/GPU) installed"
        
        # Set GPU mode in .env
        if [ ! -f ".env" ]; then
            echo "N_GPU_LAYERS=-1" > .env
            echo "  Created .env with GPU enabled (N_GPU_LAYERS=-1)"
        fi
    else
        echo "  CUDA install failed, falling back to CPU..."
        HAS_NVIDIA=0
    fi

elif [ $HAS_METAL -eq 1 ]; then
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║  Apple Silicon found! Installing Metal ver.   ║"
    echo "  ║  This will be MUCH faster for inference.      ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
    
    METAL_INDEX="https://abetlen.github.io/llama-cpp-python/whl/metal"
    
    echo "  Using Metal wheel index: $METAL_INDEX"
    echo ""
    
    if pip install llama-cpp-python --extra-index-url "$METAL_INDEX"; then
        echo ""
        echo -e "${GREEN}✓${NC} llama-cpp-python (Metal/GPU) installed"
        
        # Set GPU mode in .env
        if [ ! -f ".env" ]; then
            echo "N_GPU_LAYERS=-1" > .env
            echo "  Created .env with GPU enabled (N_GPU_LAYERS=-1)"
        fi
    else
        echo "  Metal install failed, falling back to CPU..."
        HAS_METAL=0
    fi
fi

# CPU fallback
if [ $HAS_NVIDIA -eq 0 ] && [ $HAS_METAL -eq 0 ]; then
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║  Installing CPU version                       ║"
    echo "  ║  Inference will be slower but still works.    ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo ""
    
    CPU_INDEX="https://abetlen.github.io/llama-cpp-python/whl/cpu"
    
    echo "  Using CPU wheel index: $CPU_INDEX"
    echo ""
    
    pip install llama-cpp-python --extra-index-url "$CPU_INDEX"
    
    echo ""
    echo -e "${GREEN}✓${NC} llama-cpp-python (CPU) installed"
    
    # Set CPU mode in .env
    if [ ! -f ".env" ]; then
        echo "N_GPU_LAYERS=0" > .env
        echo "  Created .env with CPU mode (N_GPU_LAYERS=0)"
    fi
fi
echo ""

# ─── Install remaining dependencies ───────────────────────────
echo "--- Installing remaining packages ---"
echo ""
pip install -r requirements.txt --no-cache-dir
echo ""
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# ─── Install Playwright browsers ──────────────────────────────
echo -e "${YELLOW}[4/5]${NC} Installing Playwright browsers..."
echo "  Downloading Chromium browser..."
echo ""
playwright install chromium
echo ""
echo -e "${GREEN}✓${NC} Playwright ready"
echo ""

# ─── Download model ───────────────────────────────────────────
echo -e "${YELLOW}[5/5]${NC} Checking model..."
echo "  If the model is not downloaded yet this will take a while (~7 GB)."
echo ""
$PYTHON -c "from app.model_manager import ensure_model_exists; ensure_model_exists()"
echo ""

# ─── Summary ──────────────────────────────────────────────────
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Setup Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

if [ $HAS_NVIDIA -eq 1 ]; then
    echo "  GPU Mode: NVIDIA CUDA (fast!)"
elif [ $HAS_METAL -eq 1 ]; then
    echo "  GPU Mode: Apple Metal (fast!)"
else
    echo "  GPU Mode: CPU only (slower)"
fi

echo ""
echo "  To start the server:"
echo -e "    ${CYAN}source .venv/bin/activate${NC}"
echo -e "    ${CYAN}python -m app.main${NC}"
echo ""
echo -e "  Then open: ${CYAN}http://localhost:8000${NC}"
echo ""
