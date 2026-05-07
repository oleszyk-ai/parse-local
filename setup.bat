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
    echo ✗ Python 3.10+ is required but not found.
    echo   Install it from https://python.org
    pause
    exit /b 1
)
python --version
echo ✓ Python found

:: ─── Create venv ─────────────────────────────────────────────
echo [2/5] Creating virtual environment...
if not exist ".venv" (
    python -m venv .venv
    echo ✓ Virtual environment created
) else (
    echo ✓ Virtual environment already exists
)

:: Activate
call .venv\Scripts\activate.bat

:: ─── Install dependencies ────────────────────────────────────
echo [3/5] Installing dependencies...
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo ✓ Dependencies installed

:: ─── Install Playwright ──────────────────────────────────────
echo [4/5] Installing Playwright browsers...
playwright install chromium
echo ✓ Playwright ready

:: ─── Download model ──────────────────────────────────────────
echo [5/5] Checking model...
python -c "from app.model_manager import ensure_model_exists; ensure_model_exists()"

:: ─── Done ────────────────────────────────────────────────────
echo.
echo ╔══════════════════════════════════════════╗
echo ║          Setup Complete!                 ║
echo ╚══════════════════════════════════════════╝
echo.
echo   To start the server:
echo     .venv\Scripts\activate.bat
echo     python -m app.main
echo.
echo   Then open: http://localhost:8000
echo.
pause