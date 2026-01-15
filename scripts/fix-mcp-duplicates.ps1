# Script to fix MCP duplicates and ensure single source of truth
# Run as Administrator: Right-click PowerShell -> Run as Administrator, then: .\scripts\fix-mcp-duplicates.ps1

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Fixing MCP Configuration Duplicates ===" -ForegroundColor Cyan
Write-Host ""

$repoConfigPath = "C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor\mcp.json"
$globalConfigPath = "$env:USERPROFILE\.cursor\mcp.json"

# Ensure CURSOR_CONFIG_DIR is set
$cursorConfigDir = "C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor"
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", $cursorConfigDir, "User")
Write-Host "✓ CURSOR_CONFIG_DIR set to: $cursorConfigDir" -ForegroundColor Green

# Minimize global config
if (Test-Path $globalConfigPath) {
    $backupPath = $globalConfigPath + ".backup." + (Get-Date -Format "yyyyMMdd-HHmmss")
    Copy-Item $globalConfigPath $backupPath -Force
    Write-Host "✓ Backed up global config to: $backupPath" -ForegroundColor Green
    
    $minimal = @{ mcpServers = @{} }
    $minimal | ConvertTo-Json | Set-Content $globalConfigPath -Encoding UTF8
    Write-Host "✓ Minimized global mcp.json (empty mcpServers)" -ForegroundColor Green
} else {
    Write-Host "⚠ Global mcp.json not found (this is OK)" -ForegroundColor Yellow
}

# Verify repo config exists
if (Test-Path $repoConfigPath) {
    $repoConfig = Get-Content $repoConfigPath | ConvertFrom-Json
    $mcpCount = ($repoConfig.mcpServers.PSObject.Properties | Measure-Object).Count
    Write-Host "✓ Repo mcp.json found with $mcpCount MCP servers" -ForegroundColor Green
    Write-Host "  MCPs: $($repoConfig.mcpServers.PSObject.Properties.Name -join ', ')" -ForegroundColor Cyan
} else {
    Write-Host "✗ Repo mcp.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "1. CURSOR_CONFIG_DIR is set to repo .cursor directory" -ForegroundColor Green
Write-Host "2. Global mcp.json minimized (backed up)" -ForegroundColor Green
Write-Host "3. Repo mcp.json is the single source of truth" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart Cursor completely" -ForegroundColor White
Write-Host "2. Verify MCP servers are loaded from repo config" -ForegroundColor White
Write-Host "3. Check Cursor MCP settings to confirm no duplicates" -ForegroundColor White
