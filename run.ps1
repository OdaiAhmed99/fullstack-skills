<#
.SYNOPSIS
  Run the app locally - no Docker. SQLite database, no Redis needed.
  Always stops the old run first, so it never stays stuck.

.EXAMPLE
  .\run.ps1          # stop old run, free ports 8000/5173, install what is missing, migrate, start both
  .\run.ps1 -Stop    # stop backend and frontend
  .\run.ps1 -Status  # what is running

  Docker instead (Postgres + Redis + nginx): .\run-docker.ps1
#>
param([switch]$Stop, [switch]$Status)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
$runDir = Join-Path $PSScriptRoot ".run"
New-Item -ItemType Directory -Force $runDir | Out-Null
$ports = @{ backend = 8000; frontend = 5173 }

function Say($text, $color = "Cyan") { Write-Host "==> $text" -ForegroundColor $color }

function Stop-Port($port) {
    $pids = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($procId in $pids) {
        if ($procId -le 4) { continue }
        $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($p) {
            Say "Stopping $($p.ProcessName) (PID $procId) on port $port" "Yellow"
            # /T also ends the child processes (Django's autoreloader, Vite's esbuild)
            taskkill /PID $procId /T /F *> $null
        }
    }
}

if ($Status) {
    foreach ($name in $ports.Keys) {
        $up = Get-NetTCPConnection -LocalPort $ports[$name] -State Listen -ErrorAction SilentlyContinue
        Write-Host ("{0,-9} port {1}: {2}" -f $name, $ports[$name], $(if ($up) { "running" } else { "stopped" }))
    }
    exit 0
}

# --- 1. Always stop the old run first ---
Say "Stopping anything left from the last run..."
$ports.Values | ForEach-Object { Stop-Port $_ }
if ($Stop) { Say "Stopped." "Green"; exit 0 }

# --- 2. Tools ---
$python = if (Get-Command py -ErrorAction SilentlyContinue) { "py" } elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { $null }
if (-not $python) { Say "Python 3.11+ is not installed. Get it from https://www.python.org/downloads/ (tick 'Add to PATH'), then run again." "Red"; exit 1 }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { Say "Node.js 20+ is not installed. Get the LTS from https://nodejs.org/, then run again." "Red"; exit 1 }

# --- 3. .env ---
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Say "Created .env from .env.example (SQLite, no Redis)." "Yellow"
}

# --- 4. Backend: venv, packages, migrations ---
$venvPy = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $venvPy)) {
    Say "Creating the Python environment (.venv)..."
    if ($python -eq "py") { & py -3 -m venv .venv } else { & python -m venv .venv }
}
$reqStamp = Join-Path $runDir "requirements.hash"
$reqHash = (Get-FileHash "backend\requirements.txt").Hash
if (-not (Test-Path $reqStamp) -or (Get-Content $reqStamp) -ne $reqHash) {
    Say "Installing backend packages..."
    & $venvPy -m pip install --quiet --upgrade pip
    & $venvPy -m pip install --quiet -r backend\requirements.txt
    if ($LASTEXITCODE -ne 0) { Say "pip install failed - see the error above." "Red"; exit 1 }
    Set-Content $reqStamp $reqHash
}

Push-Location backend
if (-not (Get-ChildItem "users\migrations\0*.py" -ErrorAction SilentlyContinue)) {
    Say "Creating the first users migration (commit backend/users/migrations/0001_initial.py)..." "Yellow"
    & $venvPy manage.py makemigrations users
}
Say "Migrating the SQLite database..."
& $venvPy manage.py migrate --noinput
$migrateOk = $LASTEXITCODE -eq 0
Pop-Location
if (-not $migrateOk) { Say "migrate failed - see the error above." "Red"; exit 1 }

# --- 5. Frontend packages ---
if (-not (Test-Path "frontend\node_modules")) {
    Say "Installing frontend packages (first time only)..."
    Push-Location frontend; npm install --silent; $npmOk = $LASTEXITCODE -eq 0; Pop-Location
    if (-not $npmOk) { Say "npm install failed - see the error above." "Red"; exit 1 }
}

# --- 6. Start both in the background, logs to .run/ ---
Say "Starting backend on :8000 and frontend on :5173..."
Start-Process -FilePath $venvPy -ArgumentList "manage.py", "runserver", "127.0.0.1:8000" `
    -WorkingDirectory "$PSScriptRoot\backend" -WindowStyle Hidden `
    -RedirectStandardOutput "$runDir\backend.log" -RedirectStandardError "$runDir\backend.err.log"
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm run dev" `
    -WorkingDirectory "$PSScriptRoot\frontend" -WindowStyle Hidden `
    -RedirectStandardOutput "$runDir\frontend.log" -RedirectStandardError "$runDir\frontend.err.log"

# --- 7. Wait until the API answers through the frontend's proxy ---
$healthy = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 2
    try {
        if ((Invoke-RestMethod "http://localhost:5173/api/core/health/" -TimeoutSec 3).status -eq "ok") { $healthy = $true; break }
    } catch { }
}

if ($healthy) {
    Say "Running." "Green"
    Write-Host "   App      http://localhost:5173"
    Write-Host "   API docs http://localhost:8000/api/docs/"
    Write-Host "   Admin    http://localhost:8000/admin/   (create a user: .venv\Scripts\python backend\manage.py createsuperuser)"
    Write-Host "   Logs     .run\backend.err.log, .run\frontend.log"
    Write-Host "   Stop     .\run.ps1 -Stop"
} else {
    Say "Did not start in 80 seconds. Last backend log lines:" "Red"
    Get-Content "$runDir\backend.err.log" -Tail 25 -ErrorAction SilentlyContinue
    Say "Last frontend log lines:" "Red"
    Get-Content "$runDir\frontend.log" -Tail 15 -ErrorAction SilentlyContinue
    exit 1
}
