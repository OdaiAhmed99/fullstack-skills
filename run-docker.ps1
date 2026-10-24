<#
.SYNOPSIS
  Start (or restart) the whole Docker stack cleanly (Postgres, Redis, nginx). Local run without Docker: .\run.ps1, so it never stays half-running.

.EXAMPLE
  .\run-docker.ps1            # stop anything old, free the port, build, start, wait until healthy
  .\run-docker.ps1 -Logs      # same, then follow the logs (Ctrl+C stops following, not the app)
  .\run-docker.ps1 -Stop      # stop everything
  .\run-docker.ps1 -Reset     # stop and DELETE the database/media volumes, then start fresh
  .\run-docker.ps1 -Status    # show what is running
#>
param(
    [switch]$Stop,
    [switch]$Logs,
    [switch]$Reset,
    [switch]$Status
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Say($text, $color = "Cyan") { Write-Host "==> $text" -ForegroundColor $color }

# --- 1. Docker must be running ---
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Say "Docker is not running. Starting Docker Desktop..." "Yellow"
    $desktop = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $desktop) { Start-Process $desktop } else { Say "Open Docker Desktop, then run this again." "Red"; exit 1 }
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 2
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { break }
    }
    if ($LASTEXITCODE -ne 0) { Say "Docker did not start in 2 minutes. Open Docker Desktop and run this again." "Red"; exit 1 }
}

if ($Status) { docker compose ps; exit 0 }

# --- 2. Always stop the old stack first (no stuck containers) ---
Say "Stopping the old stack..."
if ($Reset) {
    Say "Reset: deleting database and media volumes." "Yellow"
    docker compose down --remove-orphans --volumes
} else {
    docker compose down --remove-orphans
}
if ($Stop) { Say "Stopped." "Green"; exit 0 }

# --- 3. .env must exist ---
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Say "Created .env from .env.example - change the change-me values before going live." "Yellow"
}

# --- 4. Free the port nginx needs (something outside Docker may hold it) ---
$port = 80
$line = Select-String -Path ".env" -Pattern "^NGINX_PORT=(\d+)" | Select-Object -First 1
if ($line) { $port = [int]$line.Matches[0].Groups[1].Value }

$holders = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
foreach ($procId in $holders) {
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    if (-not $proc -or $procId -le 4) {
        Say "Port $port is held by a Windows service (PID $procId, e.g. IIS/http.sys). Set NGINX_PORT=8080 in .env and run again." "Red"
        exit 1
    }
    if ($proc.ProcessName -match "docker|com.docker|wslrelay|vpnkit") { continue }
    Say "Port $port is used by $($proc.ProcessName) (PID $procId) - stopping it." "Yellow"
    Stop-Process -Id $procId -Force -Confirm:$false
}

# --- 5. Build and start ---
Say "Building and starting (first time takes a few minutes)..."
docker compose up --build -d
if ($LASTEXITCODE -ne 0) {
    Say "Start failed. Last logs:" "Red"
    docker compose logs --tail 40
    exit 1
}

# --- 6. Wait until the backend answers through nginx ---
$url = if ($port -eq 80) { "http://localhost" } else { "http://localhost:$port" }
Say "Waiting for $url/api/core/health/ ..."
$healthy = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $r = Invoke-RestMethod "$url/api/core/health/" -TimeoutSec 3
        if ($r.status -eq "ok") { $healthy = $true; break }
    } catch { }
    Start-Sleep -Seconds 3
}

if ($healthy) {
    Say "Running." "Green"
    Write-Host "   App      $url"
    Write-Host "   API docs $url/api/docs/"
    Write-Host "   Admin    $url/admin/   (create a user: docker compose exec backend python manage.py createsuperuser)"
    Write-Host "   Stop     .\run-docker.ps1 -Stop"
} else {
    Say "The backend did not become healthy in 3 minutes. Backend logs:" "Red"
    docker compose ps
    docker compose logs backend --tail 40
    exit 1
}

if ($Logs) { docker compose logs -f }
