# =============================================================================
# ThesisFlow — PostgreSQL Backup Script
# Dumps the live database from Docker, saves a compressed .dump file locally,
# prunes backups older than 14 days, and optionally uploads to cloud storage.
#
# Usage:
#   .\database\backup.ps1
#
# Scheduled backups (Windows Task Scheduler):
#   Action: powershell.exe
#   Arguments: -NonInteractive -File "D:\Projects\ThesisFlow\database\backup.ps1"
#
# Cloud upload:
#   Install AWS CLI (https://aws.amazon.com/cli/) — works with:
#     AWS S3          s3://your-bucket/thesisflow-backups
#     Backblaze B2    s3://your-b2-bucket/thesisflow-backups  (via S3-compatible endpoint)
#     Cloudflare R2   s3://your-r2-bucket/thesisflow-backups  (via S3-compatible endpoint)
#   Set BACKUP_BUCKET in your .env or as a system environment variable.
# =============================================================================

param(
    [string]$BackupDir   = (Join-Path $PSScriptRoot "backups"),
    [string]$DbName      = ($env:POSTGRES_DB      ?? "thesisflow"),
    [string]$DbUser      = "thesisflow_migrator",
    [string]$DbPassword  = $env:THESISFLOW_MIGRATOR_PASSWORD,
    [string]$Container   = "thesisflow_postgres",
    [string]$CloudBucket = $env:BACKUP_BUCKET,
    [int]$RetainDays     = 14
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Ensure backup directory exists
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm"
$filename   = "thesisflow_${timestamp}.dump"
$backupPath = Join-Path $BackupDir $filename

# Verify the container is running
$running = docker inspect --format "{{.State.Running}}" $Container 2>$null
if ($running -ne "true") {
    Write-Error "Container '$Container' is not running. Start it with: docker compose up -d"
    exit 1
}

Write-Host "[$timestamp] Starting backup of '$DbName'..."

# pg_dump with custom format (-Fc): compressed, restoreable with pg_restore
docker exec `
    -e PGPASSWORD=$DbPassword `
    $Container `
    pg_dump `
        --username  $DbUser `
        --format    custom `
        --no-password `
        $DbName | Set-Content -Path $backupPath -AsByteStream

if ($LASTEXITCODE -ne 0) {
    Write-Error "pg_dump failed (exit $LASTEXITCODE). Check container logs: docker logs $Container"
    exit 1
}

$sizeMB = [math]::Round((Get-Item $backupPath).Length / 1MB, 2)
Write-Host "Backup written: $backupPath ($sizeMB MB)"

# Prune old local backups
$pruned = Get-ChildItem $BackupDir -Filter "thesisflow_*.dump" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetainDays) }

if ($pruned) {
    $pruned | Remove-Item -Force
    Write-Host "Pruned $($pruned.Count) local backup(s) older than $RetainDays days."
}

# Cloud upload (S3-compatible — AWS CLI required)
if ($CloudBucket) {
    Write-Host "Uploading to $CloudBucket..."
    aws s3 cp $backupPath "$CloudBucket/$filename"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Cloud upload complete: $CloudBucket/$filename"
    } else {
        Write-Warning "Cloud upload failed — local backup retained at $backupPath"
    }
} else {
    Write-Host "BACKUP_BUCKET not set — skipping cloud upload."
}

Write-Host "Done."
