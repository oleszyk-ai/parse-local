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

:: ─── Install llama-cpp-python from prebuilt binary ───────────
echo --- Installing llama-cpp-python (prebuilt binary, no compiling) ---
echo.

:: The correct index URL for prebuilt llama-cpp-python wheels (CPU, Windows)
:: Hosted officially at: https://abetlen.github.io/llama-cpp-python/whl/cpu
set INDEX_URL=https://abetlen.github.io/llama-cpp-python/whl/cpu

echo  Installing from official prebuilt index:
echo  %INDEX_URL%
echo.

.venv\Scripts\pip.exe install llama-cpp-python --extra-index-url %INDEX_URL%

if %errorlevel% neq 0 (
    echo.
    echo X llama-cpp-python install failed from prebuilt index.
    echo   Trying pip fallback with no-binary flag...
    echo.
    .venv\Scripts\pip.exe install llama-cpp-python --no-cache-dir
    if %errorlevel% neq 0 (
        echo.
        echo X llama-cpp-python install failed completely.
        echo   Please check your internet connection and try again.
        pause
        exit /b 1
    )
)

echo.
echo ✓ llama-cpp-python installed
echo.

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

:: ─── Done ────────────────────────────────────────────────────
echo ╔══════════════════════════════════════════╗
echo ║          Setup Complete!                 ║
echo ╚══════════════════════════════════════════╝
echo.
echo   To start the server run these two commands:
echo.
echo     .venv\Scripts\activate.bat
echo     python -m app.main
echo.
echo   Then open: http://localhost:8000
echo.
pause
