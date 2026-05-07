@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo.
echo ╔══════════════════════════════════════════╗
echo ║        Parse-Local — Setup Script        ║
echo ╚══════════════════════════════════════════╝
echo.

:: ─── Check Python ────────────────────────────────────────────
echo [1/5] Checking Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo X Python 3.10+ is required but not found.
    echo   Install it from https://python.org
    pause
    exit /b 1
)
python --version
echo ✓ Python found
echo.

:: ─── Create venv ─────────────────────────────────────────────
echo [2/5] Creating virtual environment...
if not exist ".venv" (
    python -m venv .venv
    echo ✓ Virtual environment created
) else (
    echo ✓ Virtual environment already exists
)
echo.

:: ─── Upgrade pip ─────────────────────────────────────────────
echo [3/5] Installing dependencies...
echo.
echo --- Upgrading pip ---
.venv\Scripts\python.exe -m pip install --upgrade pip
echo.

:: ─── Detect GPU ──────────────────────────────────────────────
echo --- Detecting GPU ---
echo.

set HAS_NVIDIA=0
set CUDA_VERSION=

:: Check if nvidia-smi exists (NVIDIA GPU present)
where nvidia-smi >nul 2>nul
if %errorlevel% equ 0 (
    echo  NVIDIA GPU detected!
    set HAS_NVIDIA=1
    
    :: Try to detect CUDA version
    for /f "tokens=*" %%i in ('nvidia-smi --query-gpu=driver_version --format=csv,noheader 2^>nul') do (
        echo  Driver version: %%i
    )
    
    :: Check for CUDA toolkit
    where nvcc >nul 2>nul
    if %errorlevel% equ 0 (
        for /f "tokens=5" %%i in ('nvcc --version ^| findstr "release"') do (
            set CUDA_VERSION=%%i
            echo  CUDA version: %%i
        )
    ) else (
        echo  CUDA toolkit not found, will try to detect from nvidia-smi...
        for /f "tokens=9" %%i in ('nvidia-smi ^| findstr "CUDA Version"') do (
            set CUDA_VERSION=%%i
            echo  CUDA version: %%i
        )
    )
) else (
    echo  No NVIDIA GPU detected.
)

echo.

:: ─── Install llama-cpp-python ────────────────────────────────
echo --- Installing llama-cpp-python ---
echo.

if %HAS_NVIDIA%==1 (
    echo  ╔═══════════════════════════════════════════════╗
    echo  ║  NVIDIA GPU found! Installing CUDA version    ║
    echo  ║  This will be MUCH faster for inference.      ║
    echo  ╚═══════════════════════════════════════════════╝
    echo.
    
    :: Determine which CUDA version wheel to use
    :: Available: cu121, cu122, cu123, cu124
    set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu124
    
    :: Check CUDA version and select appropriate index
    echo !CUDA_VERSION! | findstr "12.1" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu121
    echo !CUDA_VERSION! | findstr "12.2" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu122
    echo !CUDA_VERSION! | findstr "12.3" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu123
    echo !CUDA_VERSION! | findstr "12.4" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu124
    echo !CUDA_VERSION! | findstr "12.5" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu124
    echo !CUDA_VERSION! | findstr "12.6" >nul && set CUDA_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cu124
    
    echo  Using CUDA wheel index: !CUDA_INDEX!
    echo.
    
    .venv\Scripts\pip.exe install llama-cpp-python --extra-index-url !CUDA_INDEX!
    
    if !errorlevel! neq 0 (
        echo.
        echo  CUDA version failed, trying CPU version as fallback...
        echo.
        goto :install_cpu
    )
    
    echo.
    echo ✓ llama-cpp-python ^(CUDA/GPU^) installed
    echo.
    
    :: Set GPU layers in .env file
    if not exist ".env" (
        echo N_GPU_LAYERS=-1>.env
        echo  Created .env with GPU enabled ^(N_GPU_LAYERS=-1^)
    )
    
) else (
    :install_cpu
    echo  ╔═══════════════════════════════════════════════╗
    echo  ║  Installing CPU version                       ║
    echo  ║  Inference will be slower but still works.    ║
    echo  ║  Tip: Get an NVIDIA GPU for 5-10x speedup!    ║
    echo  ╚═══════════════════════════════════════════════╝
    echo.
    
    set CPU_INDEX=https://abetlen.github.io/llama-cpp-python/whl/cpu
    
    echo  Using CPU wheel index: !CPU_INDEX!
    echo.
    
    .venv\Scripts\pip.exe install llama-cpp-python --extra-index-url !CPU_INDEX!
    
    if !errorlevel! neq 0 (
        echo.
        echo X llama-cpp-python install failed.
        echo   Please check your internet connection and try again.
        pause
        exit /b 1
    )
    
    echo.
    echo ✓ llama-cpp-python ^(CPU^) installed
    echo.
    
    :: Set CPU mode in .env file
    if not exist ".env" (
        echo N_GPU_LAYERS=0>.env
        echo  Created .env with CPU mode ^(N_GPU_LAYERS=0^)
    )
)

:: ─── Install remaining dependencies ──────────────────────────
echo --- Installing remaining packages ---
echo.
.venv\Scripts\pip.exe install -r requirements.txt --no-cache-dir
if %errorlevel% neq 0 (
    echo.
    echo X Dependency installation failed.
    echo   Check the error above and try again.
    pause
    exit /b 1
)
echo.
echo ✓ Dependencies installed
echo.

:: ─── Install Playwright ──────────────────────────────────────
echo [4/5] Installing Playwright browsers...
echo  Downloading Chromium browser...
echo.
.venv\Scripts\playwright.exe install chromium
if %errorlevel% neq 0 (
    echo.
    echo X Playwright install failed.
    pause
    exit /b 1
)
echo.
echo ✓ Playwright ready
echo.

:: ─── Download model ──────────────────────────────────────────
echo [5/5] Checking model...
echo  If the model is not downloaded yet this will take a while (~7 GB).
echo.
.venv\Scripts\python.exe -c "from app.model_manager import ensure_model_exists; ensure_model_exists()"
if %errorlevel% neq 0 (
    echo.
    echo X Model setup failed.
    echo   See troubleshooting in README.md
    pause
    exit /b 1
)
echo.

:: ─── Summary ─────────────────────────────────────────────────
echo ╔══════════════════════════════════════════╗
echo ║          Setup Complete!                 ║
echo ╚══════════════════════════════════════════╝
echo.

if %HAS_NVIDIA%==1 (
    echo   GPU Mode: NVIDIA CUDA ^(fast!^)
) else (
    echo   GPU Mode: CPU only ^(slower^)
)
echo.
echo   To start the server run these two commands:
echo.
echo     .venv\Scripts\activate.bat
echo     python -m app.main
echo.
echo   Then open: http://localhost:8000
echo.
pause
