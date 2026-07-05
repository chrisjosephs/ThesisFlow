#Requires -Version 5.1
<#
.SYNOPSIS
    Start the full ThesisFlow dev environment.
#>

$ErrorActionPreference = 'Stop'
$root   = $PSScriptRoot
$engine = Join-Path $root 'thesisflow-engine'

function Write-Step($msg) { Write-Host "  -> $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "     $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "     ERROR: $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  ThesisFlow" -ForegroundColor Cyan
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ── 1. Ensure Docker Desktop is running ───────────────────────────────────────

docker info | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Step "Starting Docker Desktop..."
    $dockerExe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path $dockerExe)) { Write-Fail "Docker Desktop not found at '$dockerExe'. Start it manually." }
    Start-Process $dockerExe
    Write-Host "     Waiting for Docker daemon..." -ForegroundColor DarkGray
    for ($i = 1; $i -le 60; $i++) {
        Start-Sleep -Seconds 2
        docker info | Out-Null
        if ($LASTEXITCODE -eq 0) { break }
        if ($i -eq 60) { Write-Fail "Docker Desktop did not start in time. Try starting it manually." }
    }
    Write-Ok "Docker Desktop ready."
} else {
    Write-Ok "Docker already running."
}
Write-Host ""

# ── 2. Start Docker services ──────────────────────────────────────────────────

Write-Step "Starting Docker services..."
docker compose -f (Join-Path $root 'docker-compose.yml') up -d | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Fail "docker compose up failed." }
Write-Ok "Services started."
Write-Host ""

# ── 3. Wait for PostgreSQL ────────────────────────────────────────────────────

Write-Step "Waiting for PostgreSQL..."
for ($i = 1; $i -le 30; $i++) {
    docker compose exec -T postgres pg_isready -U postgres | Out-Null
    if ($LASTEXITCODE -eq 0) { break }
    if ($i -eq 30) { Write-Fail "PostgreSQL did not become ready after 30s." }
    Start-Sleep -Seconds 1
}
Write-Ok "PostgreSQL ready."
Write-Host ""

# ── 4. Status panel ───────────────────────────────────────────────────────────

Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Services ready" -ForegroundColor Green
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Engine API   http://localhost:3001/api" -ForegroundColor White
Write-Host "  Health       http://localhost:3001/api/health" -ForegroundColor White
Write-Host ""
Write-Host "  pgAdmin      http://localhost:5050" -ForegroundColor DarkGray
Write-Host "               (start with: docker compose --profile tools up -d)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Starting engine  (Ctrl+C to stop)" -ForegroundColor Yellow
Write-Host "  -----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ── 5. Start engine in foreground ────────────────────────────────────────────

Set-Location $engine
pnpm start:dev
