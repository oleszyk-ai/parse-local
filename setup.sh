#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# ─── Create venv ──────────────────────────────────────────────
echo -e "${YELLOW}[2/5]${NC} Creating virtual environment..."
if [ ! -d ".venv" ]; then
    $PYTHON -m venv .venv
    echo -e "${GREEN}✓${NC} Virtual environment created"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Activate
source .venv/bin/activate

# ─── Install dependencies ─────────────────────────────────────
echo -e "${YELLOW}[3/5]${NC} Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo -e "${GREEN}✓${NC} Dependencies installed"

# ─── Install Playwright browsers ──────────────────────────────
echo -e "${YELLOW}[4/5]${NC} Installing Playwright browsers (for JS-heavy sites)..."
playwright install chromium --quiet 2>/dev/null || playwright install chromium
echo -e "${GREEN}✓${NC} Playwright ready"

# ─── Download model ───────────────────────────────────────────
echo -e "${YELLOW}[5/5]${NC} Checking model..."
$PYTHON -c "from app.model_manager import ensure_model_exists; ensure_model_exists()"

# ─── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Setup Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  To start the server:"
echo -e "    ${CYAN}source .venv/bin/activate${NC}"
echo -e "    ${CYAN}python -m app.main${NC}"
echo ""
echo -e "  Then open: ${CYAN}http://localhost:8000${NC}"
echo ""