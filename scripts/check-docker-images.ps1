# Script to check availability of Docker images from Docker Hub MCP Catalog
# Verifies which MCP server images are available and can be used
#
# Usage: .\scripts\check-docker-images.ps1

$ErrorActionPreference = "Continue"

Write-Host "`n=== Checking Docker Images from MCP Catalog ===" -ForegroundColor Cyan
Write-Host ""

# List of MCP servers to check
$mcpServers = @(
    @{ Name = "grafana"; Image = "mcp/grafana"; AltImage = ""; Required = $true },
    @{ Name = "github"; Image = "mcp/github"; AltImage = ""; Required = $true },
    @{ Name = "playwright"; Image = "mcp/playwright"; AltImage = ""; Required = $true },
    @{ Name = "duckduckgo"; Image = "mcp/duckduckgo"; AltImage = ""; Required = $true },
    @{ Name = "memory"; Image = "mcp/neo4j-memory"; AltImage = ""; Required = $true },
    @{ Name = "shrimp"; Image = "mcp/shrimp"; AltImage = ""; Required = $true },
    @{ Name = "postman"; Image = "mcp/postman"; AltImage = ""; Required = $true }
)

$results = @()
$availableImages = @()
$missingImages = @()

foreach ($server in $mcpServers) {
    Write-Host "Checking $($server.Name)..." -ForegroundColor Yellow
    
    $found = $false
    $imageName = ""
    
    # Check primary image
    try {
        $testResult = docker images $server.Image --format "{{.Repository}}:{{.Tag}}" 2>&1
        if ($LASTEXITCODE -eq 0 -and $testResult) {
            $found = $true
            $imageName = $server.Image
            Write-Host "  [OK] Found locally: $imageName" -ForegroundColor Green
        } else {
            # Try to pull (dry run check)
            Write-Host "  Checking Docker Hub for: $($server.Image)..." -ForegroundColor Gray
            $pullTest = docker manifest inspect $server.Image 2>&1
            if ($LASTEXITCODE -eq 0) {
                $found = $true
                $imageName = $server.Image
                Write-Host "  [OK] Available on Docker Hub: $imageName" -ForegroundColor Green
            }
        }
    } catch {
        # Image not found, continue
    }
    
    # Check alternative image if primary not found
    if (-not $found -and $server.AltImage) {
        try {
            $testResult = docker images $server.AltImage --format "{{.Repository}}:{{.Tag}}" 2>&1
            if ($LASTEXITCODE -eq 0 -and $testResult) {
                $found = $true
                $imageName = $server.AltImage
                Write-Host "  [OK] Found locally (alt): $imageName" -ForegroundColor Green
            } else {
                $pullTest = docker manifest inspect $server.AltImage 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $found = $true
                    $imageName = $server.AltImage
                    Write-Host "  [OK] Available on Docker Hub (alt): $imageName" -ForegroundColor Green
                }
            }
        } catch {
            # Alt image not found
        }
    }
    
    if ($found) {
        $availableImages += @{ Name = $server.Name; Image = $imageName }
        $results += @{ Name = $server.Name; Status = "Available"; Image = $imageName }
    } else {
        $missingImages += $server.Name
        $results += @{ Name = $server.Name; Status = "Missing"; Image = "" }
        Write-Host "  [WARN] Image not found - will need Dockerfile" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Available images: $($availableImages.Count)" -ForegroundColor Green
Write-Host "Missing images: $($missingImages.Count)" -ForegroundColor $(if ($missingImages.Count -gt 0) { "Yellow" } else { "Green" })

if ($availableImages.Count -gt 0) {
    Write-Host "`nAvailable Docker images:" -ForegroundColor Green
    foreach ($img in $availableImages) {
        Write-Host "  - $($img.Name): $($img.Image)" -ForegroundColor Gray
    }
}

if ($missingImages.Count -gt 0) {
    Write-Host "`nImages requiring Dockerfile:" -ForegroundColor Yellow
    foreach ($name in $missingImages) {
        Write-Host "  - $name" -ForegroundColor Gray
    }
}

# Export results to JSON
$resultsJson = $results | ConvertTo-Json -Depth 3
$outputPath = "$PSScriptRoot\..\test-results\docker-images-check-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$outputDir = Split-Path $outputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$resultsJson | Out-File -FilePath $outputPath -Encoding UTF8
Write-Host "`nResults saved to: $outputPath" -ForegroundColor Cyan

exit $(if ($missingImages.Count -gt 0) { 1 } else { 0 })
