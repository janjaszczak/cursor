# Script to synchronize mcp.json between Windows and WSL
# Ensures both configurations are identical
#
# Usage: .\scripts\sync-mcp-config.ps1 [--direction=windows-to-wsl|wsl-to-windows|both]

param(
    [ValidateSet("windows-to-wsl", "wsl-to-windows", "both")]
    [string]$Direction = "both"
)

$ErrorActionPreference = "Stop"

$windowsConfig = "$PSScriptRoot\..\mcp.json"
$wslConfig = "\\wsl.localhost\Ubuntu\home\janja\.cursor\mcp.json"

Write-Host "`n=== Synchronizing MCP Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Check if files exist
if (-not (Test-Path $windowsConfig)) {
    Write-Error "Windows config not found: $windowsConfig"
    exit 1
}

if (-not (Test-Path $wslConfig)) {
    Write-Error "WSL config not found: $wslConfig"
    exit 1
}

# Read configurations
$windowsContent = Get-Content $windowsConfig -Raw
$wslContent = Get-Content $wslConfig -Raw

# Normalize JSON (remove whitespace differences)
$windowsJson = $windowsContent | ConvertFrom-Json | ConvertTo-Json -Depth 10
$wslJson = $wslContent | ConvertFrom-Json | ConvertTo-Json -Depth 10

if ($windowsJson -eq $wslJson) {
    Write-Host "[OK] Configurations are already synchronized" -ForegroundColor Green
    exit 0
}

Write-Host "Configurations differ. Synchronizing..." -ForegroundColor Yellow

# Create backup
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$windowsBackup = "$windowsConfig.backup.$timestamp"
$wslBackup = "$wslConfig.backup.$timestamp"

Copy-Item $windowsConfig $windowsBackup
Copy-Item $wslConfig $wslBackup

Write-Host "  Backups created:" -ForegroundColor Gray
Write-Host "    Windows: $windowsBackup" -ForegroundColor Gray
Write-Host "    WSL: $wslBackup" -ForegroundColor Gray

# Synchronize based on direction
if ($Direction -eq "windows-to-wsl" -or $Direction -eq "both") {
    Write-Host "`nCopying Windows -> WSL..." -ForegroundColor Yellow
    $windowsJson | Out-File -FilePath $wslConfig -Encoding UTF8 -NoNewline
    Write-Host "  [OK] WSL config updated" -ForegroundColor Green
}

if ($Direction -eq "wsl-to-windows" -or $Direction -eq "both") {
    Write-Host "`nCopying WSL -> Windows..." -ForegroundColor Yellow
    $wslJson | Out-File -FilePath $windowsConfig -Encoding UTF8 -NoNewline
    Write-Host "  [OK] Windows config updated" -ForegroundColor Green
}

# Verify synchronization
$windowsContentNew = Get-Content $windowsConfig -Raw
$wslContentNew = Get-Content $wslConfig -Raw
$windowsJsonNew = $windowsContentNew | ConvertFrom-Json | ConvertTo-Json -Depth 10
$wslJsonNew = $wslContentNew | ConvertFrom-Json | ConvertTo-Json -Depth 10

if ($windowsJsonNew -eq $wslJsonNew) {
    Write-Host "`n[OK] Configurations are now synchronized" -ForegroundColor Green
    exit 0
} else {
    Write-Error "Synchronization failed - configurations still differ"
    exit 1
}
