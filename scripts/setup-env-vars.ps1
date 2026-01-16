# Setup script for Windows environment variables
# Sets CURSOR_CONFIG_DIR and MCP environment variables for Docker Desktop on Windows
#
# Run this script as Administrator to set environment variables
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

# Load environment variables from .env file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$envFile = Join-Path $repoRoot ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "[WARN] .env file not found at: $envFile" -ForegroundColor Yellow
    Write-Host "Creating template file..." -ForegroundColor Yellow
    
    $templateContent = @"
# Local environment variables for Cursor MCP configuration
NEO4J_URI=neo4j://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=CHANGE_ME
NEO4J_DATABASE=neo4j
GITHUB_PERSONAL_ACCESS_TOKEN=CHANGE_ME
GRAFANA_URL=http://localhost:3001
GRAFANA_API_KEY=CHANGE_ME
POSTMAN_API_KEY=CHANGE_ME
"@
    $templateContent | Out-File -FilePath $envFile -Encoding UTF8
    Write-Host "[OK] Template created. Please edit .env and run script again." -ForegroundColor Green
    exit 0
}

Write-Host "Loading variables from .env..." -ForegroundColor Cyan

# Read and parse .env
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if ($key -and $value) {
            $envVars[$key] = $value
        }
    }
}

# CURSOR_CONFIG_DIR
$cursorConfigDir = "C:\Users\janja\.cursor"
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", $cursorConfigDir, "User")
Write-Host "[OK] CURSOR_CONFIG_DIR set to: $cursorConfigDir" -ForegroundColor Green

# MCP Environment Variables
$mcpVars = @(
    "NEO4J_URI",
    "NEO4J_USERNAME",
    "NEO4J_PASSWORD",
    "NEO4J_DATABASE",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "GRAFANA_URL",
    "GRAFANA_API_KEY",
    "POSTMAN_API_KEY"
)

Write-Host ""
Write-Host "Setting MCP environment variables..." -ForegroundColor Cyan

foreach ($varName in $mcpVars) {
    if ($envVars.ContainsKey($varName)) {
        $value = $envVars[$varName]
        if ($value -ne "CHANGE_ME" -and $value -ne "") {
            [Environment]::SetEnvironmentVariable($varName, $value, "User")
            Write-Host "  [OK] $varName set" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] $varName is not set (CHANGE_ME or empty)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [WARN] $varName not found in .env" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Windows configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host '  1. Restart Cursor for changes to take effect' -ForegroundColor White
Write-Host '  2. Restart Docker Desktop if it is running' -ForegroundColor White
