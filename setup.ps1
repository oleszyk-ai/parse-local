# Parse-Local Setup Script for Windows
# Run with: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Parse-Local — Setup Script        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ─── Check Python ────────────────────────────────────────────
Write-Host "[1/5] Checking Python..." -ForegroundColor Yellow

$python = $null
if (Get-Command python -ErrorAction SilentlyContinue) {
    $python = "python"
} elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
    $python = "python3"
} else {
    Write-Host "X Python 3.10+ is required but not found." -ForegroundColor Red
    Write-Host "  Install it from https://python.org"
    Read-Host "Press Enter to exit"
    exit 1
}

$pyVersion = & $python --version
Write-Host "✓ $pyVersion found" -ForegroundColor Green
Write-Host ""

# ─── Create venv ─────────────────────────────────────────────
Write-Host "[2/5] Creating virtual environment..." -ForegroundColor Yellow

if (-not (Test-Path ".venv")) {
    & $python -m venv .venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
}
Write-Host ""

# ─── Activate venv ───────────────────────────────────────────
$venvPython = ".\.venv\Scripts\python.exe"
$venvPip = ".\.venv\Scripts\pip.exe"

# ─── Upgrade pip ─────────────────────────────────────────────
Write-Host "[3/5] Installing dependencies..." -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Upgrading pip ---"
& $venvPython -m pip install --upgrade pip
Write-Host ""

# ─── Detect GPU ──────────────────────────────────────────────
Write-Host "--- Detecting GPU ---"
Write-Host ""

$hasNvidia = $false
$cudaVersion = ""

if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    Write-Host "  NVIDIA GPU detected!" -ForegroundColor Green
    $hasNvidia = $true
    
    try {
        $smiOutput = & nvidia-smi 2>$null
        $cudaLine = $smiOutput | Select-String "CUDA Version"
        if ($cudaLine) {
            $cudaVersion = ($cudaLine -split "CUDA Version:")[1].Trim().Split()[0]
            Write-Host "  CUDA version: $cudaVersion"
        }
    } catch {
        Write-Host "  Could not detect CUDA version"
    }
} else {
    Write-Host "  No NVIDIA GPU detected."
}
Write-Host ""

# ─── Install llama-cpp-python ────────────────────────────────
Write-Host "--- Installing llama-cpp-python ---"
Write-Host ""

if ($hasNvidia) {
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║  NVIDIA GPU found! Installing CUDA version    ║" -ForegroundColor Green
    Write-Host "  ║  This will be MUCH faster for inference.      ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    # Select CUDA index based on version
    $cudaIndex = "https://abetlen.github.io/llama-cpp-python/whl/cu124"
    
    if ($cudaVersion -like "12.1*") { $cudaIndex = "https://abetlen.github.io/llama-cpp-python/whl/cu121" }
    elseif ($cudaVersion -like "12.2*") { $cudaIndex = "https://abetlen.github.io/llama-cpp-python/whl/cu122" }
    elseif ($cudaVersion -like "12.3*") { $cudaIndex = "https://abetlen.github.io/llama-cpp-python/whl/cu123" }
    
    Write-Host "  Using CUDA wheel index: $cudaIndex"
    Write-Host ""
    
    $result = & $venvPip install llama-cpp-python --extra-index-url $cudaIndex 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ llama-cpp-python (CUDA/GPU) installed" -ForegroundColor Green
        
        if (-not (Test-Path ".env")) {
            "N_GPU_LAYERS=-1" | Out-File -FilePath ".env" -Encoding utf8
            Write-Host "  Created .env with GPU enabled (N_GPU_LAYERS=-1)"
        }
    } else {
        Write-Host "  CUDA install failed, falling back to CPU..." -ForegroundColor Yellow
        $hasNvidia = $false
    }
}

if (-not $hasNvidia) {
    Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  Installing CPU version                       ║" -ForegroundColor Yellow
    Write-Host "  ║  Inference will be slower but still works.    ║" -ForegroundColor Yellow
    Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    $cpuIndex = "https://abetlen.github.io/llama-cpp-python/whl/cpu"
    
    Write-Host "  Using CPU wheel index: $cpuIndex"
    Write-Host ""
    
    & $venvPip install llama-cpp-python --extra-index-url $cpuIndex
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "X llama-cpp-python install failed." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host ""
    Write-Host "✓ llama-cpp-python (CPU) installed" -ForegroundColor Green
    
    if (-not (Test-Path ".env")) {
        "N_GPU_LAYERS=0" | Out-File -FilePath ".env" -Encoding utf8
        Write-Host "  Created .env with CPU mode (N_GPU_LAYERS=0)"
    }
}
Write-Host ""

# ─── Install remaining dependencies ──────────────────────────
Write-Host "--- Installing remaining packages ---"
Write-Host ""
& $venvPip install -r requirements.txt --no-cache-dir

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "X Dependency installation failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# ─── Install Playwright ──────────────────────────────────────
Write-Host "[4/5] Installing Playwright browsers..." -ForegroundColor Yellow
Write-Host "  Downloading Chromium browser..."
Write-Host ""

& .\.venv\Scripts\playwright.exe install chromium

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "X Playwright install failed." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "✓ Playwright ready" -ForegroundColor Green
Write-Host ""

# ─── Download model ──────────────────────────────────────────
Write-Host "[5/5] Checking model..." -ForegroundColor Yellow
Write-Host "  If the model is not downloaded yet this will take a while (~7 GB)."
Write-Host ""

& $venvPython -c "from app.model_manager import ensure_model_exists; ensure_model_exists()"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "X Model setup failed." -ForegroundColor Red
    Write-Host "  See troubleshooting in README.md"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host ""

# ─── Summary ─────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          Setup Complete!                 ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($hasNvidia) {
    Write-Host "  GPU Mode: NVIDIA CUDA (fast!)" -ForegroundColor Cyan
} else {
    Write-Host "  GPU Mode: CPU only (slower)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  To start the server run these two commands:"
Write-Host ""
Write-Host "    .\.venv\Scripts\activate" -ForegroundColor Cyan
Write-Host "    python -m app.main" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Then open: http://localhost:8000" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
