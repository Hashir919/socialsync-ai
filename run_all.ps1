## run_all.ps1 - One‑click starter for SocialSync AI
# ------------------------------------------------------
# This script sets up the Python virtual‑env for the backend, installs its
# Python dependencies, starts the FastAPI server, and then launches the
# Flutter frontend.
# Run it from PowerShell (e.g., `.un_all.ps1`).
# ------------------------------------------------------

$ErrorActionPreference = 'Stop'

# Determine repository root (directory containing this script)
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------- Backend ----------
Push-Location "$RepoRoot\backend"

# Create virtual environment if missing
if (-not (Test-Path '.venv')) {
    Write-Host "Creating Python virtual environment..."
    python -m venv .venv
}

# Activate virtual environment
& ".\.venv\Scripts\Activate.ps1"

# Upgrade pip and install requirements
python -m pip install --upgrade pip
pip install -r requirements.txt

# Start FastAPI backend (uvicorn) in a new process
Write-Host "Starting backend server..."
Start-Process -FilePath "uvicorn" -ArgumentList "main:app","--host","0.0.0.0","--port","8000" -WorkingDirectory "$RepoRoot\backend" -NoNewWindow

Pop-Location

# ---------- Frontend ----------
Push-Location "$RepoRoot\frontend"

# Ensure Flutter packages are up‑to‑date
flutter pub get

# Run the Flutter app (will prompt to select device if multiple are attached)
Write-Host "Launching Flutter frontend..."
flutter run

Pop-Location
