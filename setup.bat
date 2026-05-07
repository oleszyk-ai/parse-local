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
echo --- Installing packages from requirements.txt ---
echo  This may take 5-10 minutes depending on your internet speed.
echo  You will see each package being downloaded and installed below.
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
echo  Downloading Chromium — this may take a few minutes.
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
