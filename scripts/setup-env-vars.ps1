# Setup script for Windows environment variables
# Run this script as Administrator to set all required Cursor/MCP environment variables
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

Write-Host "Setting up Cursor environment variables (as Administrator)..." -ForegroundColor Cyan

# CURSOR_CONFIG_DIR
$cursorConfigDir = "C:\Users\janja\OneDrive\Dokumenty\GitHub\ai\.cursor"
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", $cursorConfigDir, "User")
Write-Host "[OK] CURSOR_CONFIG_DIR set to: $cursorConfigDir" -ForegroundColor Green

# Load environment variables from env.local file
# Script is in scripts/, env.local is in repo root (one level up)
$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) "env.local"
if (-not (Test-Path $envFile)) {
    Write-Host "[WARNING] env.local file not found at: $envFile" -ForegroundColor Yellow
    Write-Host "Creating template file..." -ForegroundColor Yellow
    @"
# Local environment variables for Cursor MCP configuration
NEO4J_URI=neo4j://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=CHANGE_ME
NEO4J_DATABASE=neo4j
GITHUB_PERSONAL_ACCESS_TOKEN=CHANGE_ME
GRAFANA_URL=http://localhost:3001
GRAFANA_API_KEY=CHANGE_ME
"@ | Set-Content $envFile -Encoding UTF8
    Write-Host "[OK] Template created. Please edit env.local and run script again." -ForegroundColor Green
    exit 0
}

Write-Host "Loading variables from env.local..." -ForegroundColor Cyan
$envVars = @{}

# Parse env.local file
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        if ($line -match "^([^=]+)=(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $envVars[$key] = $value
        }
    }
}

# Set environment variables
foreach ($var in $envVars.GetEnumerator()) {
    if ($var.Value -eq "CHANGE_ME" -or $var.Value -eq "") {
        Write-Host "[WARNING] $($var.Key) is not set (CHANGE_ME or empty)" -ForegroundColor Yellow
    } else {
        [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
        Write-Host "[OK] $($var.Key) set" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Environment variables configured." -ForegroundColor Green
Write-Host "Variables marked with CHANGE_ME need to be set in env.local file." -ForegroundColor Yellow
Write-Host "Restart Cursor for changes to take effect." -ForegroundColor Cyan
