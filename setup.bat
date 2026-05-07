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
echo  Detecting Python version...
echo.

for /f "tokens=*" %%i in ('.venv\Scripts\python.exe -c "import sys; print(f\"{sys.version_info.major}{sys.version_info.minor}\")"') do set PYVER=%%i
for /f "tokens=*" %%i in ('.venv\Scripts\python.exe -c "import platform; print(platform.machine().lower())"') do set ARCH=%%i

echo  Python version : %PYVER%
echo  Architecture   : %ARCH%
echo.

:: Map architecture to wheel tag
set WHEELTAG=win_amd64
if "%ARCH%"=="arm64" set WHEELTAG=win_arm64

:: Prebuilt wheels hosted by abetlen (official llama-cpp-python releases)
set WHEEL_URL=https://github.com/abetlen/llama-cpp-python/releases/download/v0.3.4/llama_cpp_python-0.3.4-cp%PYVER%-cp%PYVER%-win_amd64.whl

echo  Downloading prebuilt wheel from:
echo  %WHEEL_URL%
echo.

.venv\Scripts\pip.exe install "%WHEEL_URL%"

if %errorlevel% neq 0 (
    echo.
    echo  Prebuilt wheel not found for your Python version.
    echo  Trying fallback: installing from source...
    echo  You need Visual Studio Build Tools for this.
    echo  Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo.
    .venv\Scripts\pip.exe install llama-cpp-python --no-cache-dir
    if %errorlevel% neq 0 (
        echo.
        echo X llama-cpp-python install failed.
        echo   Please install Visual Studio Build Tools and try again.
        echo   Or download a prebuilt wheel manually from:
        echo   https://github.com/abetlen/llama-cpp-python/releases
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
