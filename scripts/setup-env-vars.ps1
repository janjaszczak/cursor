# Setup script for Windows environment variables
# NOTE: Only CURSOR_CONFIG_DIR is needed in Windows!
# All MCP servers run in WSL, so MCP environment variables (NEO4J_*, GITHUB_*, GRAFANA_*)
# should be set in WSL only (use scripts/setup-env-vars.sh)
#
# Run this script as Administrator to set CURSOR_CONFIG_DIR
# Right-click PowerShell and select "Run as Administrator", then run: .\scripts\setup-env-vars.ps1

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Setting up Cursor environment variables (Windows)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Only CURSOR_CONFIG_DIR is set in Windows." -ForegroundColor Yellow
Write-Host "All MCP servers run in WSL, so MCP env vars are set in WSL only." -ForegroundColor Yellow
Write-Host "Run scripts/setup-env-vars.sh in WSL to set MCP environment variables." -ForegroundColor Cyan
Write-Host ""

# CURSOR_CONFIG_DIR - only variable needed in Windows
$cursorConfigDir = "C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor"
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", $cursorConfigDir, "User")
Write-Host "[OK] CURSOR_CONFIG_DIR set to: $cursorConfigDir" -ForegroundColor Green

Write-Host ""
Write-Host "Windows configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run scripts/setup-env-vars.sh in WSL to set MCP environment variables" -ForegroundColor White
Write-Host "  2. Restart Cursor for changes to take effect" -ForegroundColor White
