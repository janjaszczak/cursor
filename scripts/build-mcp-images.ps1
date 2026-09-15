# Script to build Docker images for MCP servers
# Builds custom Docker images for servers that don't have official images
#
# Usage: .\scripts\build-mcp-images.ps1 [--all] [--memory] [--duckduckgo] [--shrimp]

param(
    [switch]$All,
    [switch]$Memory,
    [switch]$DuckDuckGo,
    [switch]$Shrimp
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dockerDir = Join-Path $scriptDir "..\docker"

Write-Host "`n=== Building MCP Docker Images ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $dockerDir)) {
    Write-Error "Docker directory not found: $dockerDir"
    exit 1
}

$builtImages = @()

# Build memory image
if ($All -or $Memory) {
    $memoryDir = Join-Path $dockerDir "mcp-memory"
    if (Test-Path $memoryDir) {
        Write-Host "Building mcp/memory..." -ForegroundColor Yellow
        try {
            docker build -t mcp/memory:latest $memoryDir
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] mcp/memory built successfully" -ForegroundColor Green
                $builtImages += "mcp/memory:latest"
            } else {
                Write-Error "Failed to build mcp/memory"
            }
        } catch {
            Write-Error "Error building mcp/memory: $_"
        }
    }
}

# Build duckduckgo image
if ($All -or $DuckDuckGo) {
    $duckduckgoDir = Join-Path $dockerDir "mcp-duckduckgo"
    if (Test-Path $duckduckgoDir) {
        Write-Host "Building mcp/duckduckgo..." -ForegroundColor Yellow
        try {
            docker build -t mcp/duckduckgo:latest $duckduckgoDir
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] mcp/duckduckgo built successfully" -ForegroundColor Green
                $builtImages += "mcp/duckduckgo:latest"
            } else {
                Write-Error "Failed to build mcp/duckduckgo"
            }
        } catch {
            Write-Error "Error building mcp/duckduckgo: $_"
        }
    }
}

# Build shrimp image
if ($All -or $Shrimp) {
    $shrimpDir = Join-Path $dockerDir "mcp-shrimp"
    if (Test-Path $shrimpDir) {
        Write-Host "Building mcp/shrimp..." -ForegroundColor Yellow
        try {
            docker build -t mcp/shrimp:latest $shrimpDir
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] mcp/shrimp built successfully" -ForegroundColor Green
                $builtImages += "mcp/shrimp:latest"
            } else {
                Write-Error "Failed to build mcp/shrimp"
            }
        } catch {
            Write-Error "Error building mcp/shrimp: $_"
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Built images: $($builtImages.Count)" -ForegroundColor Green
foreach ($img in $builtImages) {
    Write-Host "  - $img" -ForegroundColor Gray
}

if ($builtImages.Count -eq 0) {
    Write-Host "`nNo images were built. Use --all, --memory, --duckduckgo, or --shrimp flags." -ForegroundColor Yellow
    exit 1
}

exit 0
