# Script to analyze MCP server usage and identify unused servers
# Checks which MCP servers are actually being used
#
# Usage: .\scripts\analyze-mcp-usage.ps1

$ErrorActionPreference = "Continue"

Write-Host "`n=== Analyzing MCP Server Usage ===" -ForegroundColor Cyan
Write-Host ""

$mcpConfigPath = "$PSScriptRoot\..\mcp.json"

if (-not (Test-Path $mcpConfigPath)) {
    Write-Error "mcp.json not found at: $mcpConfigPath"
    exit 1
}

# Read MCP configuration
$mcpConfig = Get-Content $mcpConfigPath | ConvertFrom-Json
$servers = $mcpConfig.mcpServers.PSObject.Properties | ForEach-Object { $_.Name }

Write-Host "Configured MCP servers:" -ForegroundColor Yellow
foreach ($server in $servers) {
    Write-Host "  - $server" -ForegroundColor Gray
}

Write-Host "`nAnalysis:" -ForegroundColor Yellow
Write-Host "  This script identifies configured servers." -ForegroundColor Gray
Write-Host "  To determine actual usage, check:" -ForegroundColor Gray
Write-Host "    1. Cursor logs (if available)" -ForegroundColor Gray
Write-Host "    2. Manual testing of each server" -ForegroundColor Gray
Write-Host "    3. Project documentation for server purposes" -ForegroundColor Gray

# Check for potential issues
$issues = @()

foreach ($serverName in $servers) {
    $server = $mcpConfig.mcpServers.$serverName
    
    # Check if server has command
    if (-not $server.command) {
        $issues += "Server '$serverName' has no command configured"
    }
    
    # Check if using docker (expected)
    if ($server.command -eq "docker") {
        Write-Host "  [OK] $serverName uses Docker" -ForegroundColor Green
    } else {
        $issues += "Server '$serverName' uses unexpected command: $($server.command) (expected: docker)"
        Write-Host "  [WARN] $serverName uses unexpected command: $($server.command)" -ForegroundColor Yellow
    }
}

# Generate report
$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ConfiguredServers = $servers
    ServerCount = $servers.Count
    Issues = $issues
    Recommendations = @(
        "Review each server's purpose and usage",
        "Test each server to verify it's needed",
        "Consider removing unused servers to simplify configuration"
    )
}

$reportJson = $report | ConvertTo-Json -Depth 5
$outputPath = "$PSScriptRoot\..\test-results\mcp-usage-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$outputDir = Split-Path $outputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$reportJson | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "`nReport saved to: $outputPath" -ForegroundColor Cyan

if ($issues.Count -gt 0) {
    Write-Host "`nIssues found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
    exit 1
}

exit 0
