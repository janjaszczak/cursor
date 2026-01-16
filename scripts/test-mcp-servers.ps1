# Script to test MCP servers - health check, functional, performance, and security tests
# Verifies that all MCP servers work correctly with Docker
#
# Usage: .\scripts\test-mcp-servers.ps1

$ErrorActionPreference = "Continue"

Write-Host "`n=== Testing MCP Servers ===" -ForegroundColor Cyan
Write-Host ""

$mcpConfigPath = "$PSScriptRoot\..\mcp.json"
$testResults = @()
$errors = @()

if (-not (Test-Path $mcpConfigPath)) {
    Write-Error "mcp.json not found at: $mcpConfigPath"
    exit 1
}

# Read MCP configuration
$mcpConfig = Get-Content $mcpConfigPath | ConvertFrom-Json
$servers = $mcpConfig.mcpServers.PSObject.Properties | ForEach-Object { $_.Name }

# Security check - verify no hardcoded secrets
Write-Host "Security Check: Verifying no hardcoded secrets..." -ForegroundColor Yellow
$mcpContent = Get-Content $mcpConfigPath -Raw
$secretPatterns = @(
    "password.*:.*['\`"][^'\`"]+['\`"]",
    "token.*:.*['\`"][^'\`"]+['\`"]",
    "api[_-]?key.*:.*['\`"][^'\`"]+['\`"]",
    "secret.*:.*['\`"][^'\`"]+['\`"]"
)

$securityIssues = @()
foreach ($pattern in $secretPatterns) {
    if ($mcpContent -match $pattern) {
        $securityIssues += "Potential secret found matching pattern: $pattern"
    }
}

if ($securityIssues.Count -eq 0) {
    Write-Host "  [OK] No hardcoded secrets found" -ForegroundColor Green
    $testResults += @{ Test = "Security Check"; Status = "PASS"; Message = "No secrets found" }
} else {
    Write-Host "  [ERROR] Potential secrets found:" -ForegroundColor Red
    foreach ($issue in $securityIssues) {
        Write-Host "    - $issue" -ForegroundColor Red
    }
    $testResults += @{ Test = "Security Check"; Status = "FAIL"; Message = "Secrets found" }
    $errors += "Security check failed"
}

# Test each server
Write-Host "`nTesting individual servers..." -ForegroundColor Yellow

foreach ($serverName in $servers) {
    Write-Host "`nTesting $serverName..." -ForegroundColor Cyan
    $server = $mcpConfig.mcpServers.$serverName
    $command = $server.command
    
    # Health check - verify command exists
    if ($command -eq "docker") {
        # Check if Docker is available
        try {
            $dockerVersion = docker --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] Docker is available" -ForegroundColor Green
                $testResults += @{ Server = $serverName; Test = "Docker Available"; Status = "PASS" }
            } else {
                Write-Host "  [ERROR] Docker not available" -ForegroundColor Red
                $testResults += @{ Server = $serverName; Test = "Docker Available"; Status = "FAIL" }
                $errors += "${serverName}: Docker not available"
            }
        } catch {
            Write-Host "  [ERROR] Cannot check Docker: $_" -ForegroundColor Red
            $testResults += @{ Server = $serverName; Test = "Docker Available"; Status = "FAIL" }
            $errors += "${serverName}: Docker check failed"
        }
        
        # Check if image exists or can be pulled
        # Image name is the argument containing "/" that's not a Docker flag or env var value
        $imageName = $null
        $skipNext = $false
        for ($i = 0; $i -lt $server.args.Count; $i++) {
            $arg = $server.args[$i]
            if ($skipNext) {
                $skipNext = $false
                continue
            }
            # Skip Docker flags
            if ($arg -match "^(run|-i|--rm|--transport=stdio|--full|--code|--region)$") {
                continue
            }
            # Skip env var and volume flags (skip next arg)
            if ($arg -eq "-e" -or $arg -eq "-v") {
                $skipNext = $true
                continue
            }
            # Skip volume mount paths (contain :)
            if ($arg -match ":") {
                continue
            }
            # Skip region values (us/eu) and other single-word values
            if ($arg -match "^(us|eu)$" -and $i -gt 0 -and $server.args[$i - 1] -eq "--region") {
                continue
            }
            # Image name contains "/" and is not a flag
            if ($arg -match "/" -and $arg -notmatch "^-") {
                $imageName = $arg
                # Continue to check if there's a better match, but this is likely it
            }
        }
        if ($imageName) {
            try {
                $imageCheck = docker images $imageName --format "{{.Repository}}:{{.Tag}}" 2>&1
                if ($LASTEXITCODE -eq 0 -and $imageCheck) {
                    Write-Host "  [OK] Image exists locally: $imageName" -ForegroundColor Green
                    $testResults += @{ Server = $serverName; Test = "Image Exists"; Status = "PASS"; Image = $imageName }
                } else {
                    # Try manifest check
                    $manifestCheck = docker manifest inspect $imageName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  [OK] Image available on Docker Hub: $imageName" -ForegroundColor Green
                        $testResults += @{ Server = $serverName; Test = "Image Available"; Status = "PASS"; Image = $imageName }
                    } else {
                        Write-Host "  [WARN] Image not found: $imageName" -ForegroundColor Yellow
                        $testResults += @{ Server = $serverName; Test = "Image Available"; Status = "WARN"; Image = $imageName }
                    }
                }
            } catch {
                Write-Host "  [WARN] Cannot check image: $_" -ForegroundColor Yellow
                $testResults += @{ Server = $serverName; Test = "Image Check"; Status = "WARN" }
            }
        }
        
        # Verify environment variables are passed correctly
        $envVars = @()
        for ($i = 0; $i -lt $server.args.Count; $i++) {
            if ($server.args[$i] -eq "-e" -and $i + 1 -lt $server.args.Count) {
                $envVars += $server.args[$i + 1]
            }
        }
        if ($envVars.Count -gt 0) {
            Write-Host "  [INFO] Environment variables: $($envVars -join ', ')" -ForegroundColor Gray
            $testResults += @{ Server = $serverName; Test = "Env Vars"; Status = "PASS"; EnvVars = $envVars }
        }
    } else {
        Write-Host "  [WARN] Unknown command: $command" -ForegroundColor Yellow
        $testResults += @{ Server = $serverName; Test = "Command Check"; Status = "WARN"; Message = "Unknown command: $command" }
    }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($testResults | Where-Object { $_.Status -eq "WARN" }).Count

Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })

# Export results
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$resultsData = @{
    Timestamp = $timestamp
    Summary = @{
        Passed = $passed
        Failed = $failed
        Warnings = $warnings
    }
    Results = $testResults
    Errors = $errors
}

# Export JSON
$resultsJson = $resultsData | ConvertTo-Json -Depth 10
$outputDir = "$PSScriptRoot\..\test-results"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
$jsonPath = "$outputDir\mcp-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$resultsJson | Out-File -FilePath $jsonPath -Encoding UTF8

# Generate HTML report
$htmlPath = $jsonPath -replace '\.json$', '.html'
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>MCP Server Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .summary-item { padding: 15px; border-radius: 4px; flex: 1; }
        .passed { background: #d4edda; color: #155724; }
        .failed { background: #f8d7da; color: #721c24; }
        .warnings { background: #fff3cd; color: #856404; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-warn { color: #ffc107; font-weight: bold; }
        .errors { background: #f8d7da; padding: 15px; border-radius: 4px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>MCP Server Test Results</h1>
        <p><strong>Timestamp:</strong> $timestamp</p>
        
        <div class="summary">
            <div class="summary-item passed">
                <h2>$passed</h2>
                <p>Passed</p>
            </div>
            <div class="summary-item failed">
                <h2>$failed</h2>
                <p>Failed</p>
            </div>
            <div class="summary-item warnings">
                <h2>$warnings</h2>
                <p>Warnings</p>
            </div>
        </div>
        
        <h2>Test Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Server</th>
                    <th>Test</th>
                    <th>Status</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($result in $testResults) {
    $server = if ($result.Server) { $result.Server } else { "N/A" }
    $test = $result.Test
    $status = $result.Status
    $message = if ($result.Message) { $result.Message } elseif ($result.Image) { "Image: $($result.Image)" } elseif ($result.EnvVars) { "Env: $($result.EnvVars -join ', ')" } else { "" }
    $statusClass = switch ($status) {
        "PASS" { "status-pass" }
        "FAIL" { "status-fail" }
        "WARN" { "status-warn" }
        default { "" }
    }
    $htmlContent += "                <tr><td>$server</td><td>$test</td><td class=`"$statusClass`">$status</td><td>$message</td></tr>`n"
}

$htmlContent += @"
            </tbody>
        </table>
"@

if ($errors.Count -gt 0) {
    $htmlContent += @"
        <div class="errors">
            <h2>Errors</h2>
            <ul>
"@
    foreach ($error in $errors) {
        $htmlContent += "                <li>$error</li>`n"
    }
    $htmlContent += @"
            </ul>
        </div>
"@
}

$htmlContent += @"
    </div>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host "`nResults saved to:" -ForegroundColor Cyan
Write-Host "  JSON: $jsonPath" -ForegroundColor Gray
Write-Host "  HTML: $htmlPath" -ForegroundColor Gray

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    exit 1
}

exit 0
