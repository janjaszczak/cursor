# Verification script for Cursor configuration
# Checks that all components are properly configured

$ErrorActionPreference = "Continue"
$errors = @()
$warnings = @()

Write-Host "`n=== Cursor Configuration Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check CURSOR_CONFIG_DIR
Write-Host "Checking CURSOR_CONFIG_DIR..." -ForegroundColor Yellow
$cursorConfigDir = [Environment]::GetEnvironmentVariable("CURSOR_CONFIG_DIR", "User")
if ($cursorConfigDir) {
    if (Test-Path $cursorConfigDir) {
        Write-Host "  [OK] CURSOR_CONFIG_DIR is set: $cursorConfigDir" -ForegroundColor Green
    } else {
        $errors += "CURSOR_CONFIG_DIR points to non-existent path: $cursorConfigDir"
        Write-Host "  [ERROR] CURSOR_CONFIG_DIR path does not exist" -ForegroundColor Red
    }
} else {
    $errors += "CURSOR_CONFIG_DIR is not set"
        Write-Host "  [ERROR] CURSOR_CONFIG_DIR is not set" -ForegroundColor Red
}

# Check user .cursor directory
Write-Host "`nChecking user .cursor directory..." -ForegroundColor Yellow
$userCursorPath = "C:\Users\janja\.cursor"
if (Test-Path $userCursorPath) {
    Write-Host "  [OK] User .cursor directory exists" -ForegroundColor Green
    
    # Check for required files
    $requiredFiles = @("mcp.json", "cli-config.json")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $userCursorPath $file
        if (Test-Path $filePath) {
            Write-Host "    [OK] $file exists" -ForegroundColor Green
        } else {
            $errors += "Required file missing: $file"
            Write-Host "    [ERROR] $file missing" -ForegroundColor Red
        }
    }
    
    # Check rules directory
    $rulesPath = Join-Path $userCursorPath "rules"
    if (Test-Path $rulesPath) {
        $ruleCount = (Get-ChildItem $rulesPath -Filter "*.mdc").Count
        Write-Host "    [OK] Rules directory exists ($ruleCount rules)" -ForegroundColor Green
    } else {
        $warnings += "Rules directory not found"
        Write-Host "    [WARN] Rules directory not found" -ForegroundColor Yellow
    }
} else {
    $errors += "User .cursor directory does not exist"
    Write-Host "  [ERROR] User .cursor directory does not exist" -ForegroundColor Red
}

# Check environment variables
Write-Host "`nChecking MCP environment variables..." -ForegroundColor Yellow
$requiredEnvVars = @(
    "NEO4J_URI",
    "NEO4J_USERNAME",
    "NEO4J_PASSWORD",
    "NEO4J_DATABASE",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "GRAFANA_URL",
    "GRAFANA_API_KEY",
    "POSTMAN_API_KEY"
)

foreach ($var in $requiredEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        if ($value -match "^<SET_FROM_KEEPASS>|^$") {
            $warnings += "$var is not set (placeholder or empty)"
            Write-Host "  [WARN] $var is not set (needs KeePass)" -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] $var is set" -ForegroundColor Green
        }
    } else {
        $warnings += "$var is not set"
            Write-Host "  [WARN] $var is not set" -ForegroundColor Yellow
    }
}

# Check WSL accessibility
Write-Host "`nChecking WSL accessibility..." -ForegroundColor Yellow
try {
    $wslTest = wsl.exe -- bash -lc "echo 'WSL_OK'" 2>&1
    if ($wslTest -match "WSL_OK") {
        Write-Host "  [OK] WSL is accessible" -ForegroundColor Green
    } else {
        $errors += "WSL is not accessible"
        Write-Host "  [ERROR] WSL is not accessible" -ForegroundColor Red
    }
} catch {
    $errors += "Cannot test WSL: $_"
        Write-Host "  [ERROR] Cannot test WSL" -ForegroundColor Red
}

# Check Docker availability
Write-Host "`nChecking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Docker is available" -ForegroundColor Green
        
        # Check Docker images for MCP servers
        $mcpImages = @("mcp/grafana", "mcp/playwright", "mcp/duckduckgo", "mcp/neo4j-memory", "mcp/github", "mcp/shrimp", "mcp/postman")
        foreach ($image in $mcpImages) {
            $imageCheck = docker images $image --format "{{.Repository}}:{{.Tag}}" 2>&1
            if ($LASTEXITCODE -eq 0 -and $imageCheck) {
                Write-Host "    [OK] Image exists: $image" -ForegroundColor Green
            } else {
                # Check if available on Docker Hub
                $manifestCheck = docker manifest inspect $image 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    [OK] Image available on Docker Hub: $image" -ForegroundColor Green
                } else {
                    $warnings += "Docker image not found: $image"
                    Write-Host "    [WARN] Image not found: $image" -ForegroundColor Yellow
                }
            }
        }
    } else {
        $errors += "Docker is not available"
        Write-Host "  [ERROR] Docker is not available" -ForegroundColor Red
    }
} catch {
    $errors += "Cannot check Docker: $_"
    Write-Host "  [ERROR] Cannot check Docker" -ForegroundColor Red
}

# Check Shrimp Docker image and volume
Write-Host "`nChecking Shrimp Task Manager..." -ForegroundColor Yellow
try {
    # Check if Docker image exists
    $shrimpImage = docker images mcp/shrimp --format "{{.Repository}}:{{.Tag}}" 2>&1
    if ($LASTEXITCODE -eq 0 -and $shrimpImage) {
        Write-Host "  [OK] Shrimp Docker image exists: mcp/shrimp" -ForegroundColor Green
    } else {
        # Check if available on Docker Hub or needs build
        $manifestCheck = docker manifest inspect mcp/shrimp 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Shrimp image available on Docker Hub: mcp/shrimp" -ForegroundColor Green
        } else {
            $warnings += "Shrimp Docker image (mcp/shrimp) not found - needs build"
            Write-Host "  [WARN] Shrimp image not found - run: .\scripts\build-mcp-images.ps1 --shrimp" -ForegroundColor Yellow
        }
    }
    
    # Check if Docker volume exists
    $shrimpVolume = docker volume ls --format "{{.Name}}" | Select-String -Pattern "^shrimp_data$"
    if ($shrimpVolume) {
        Write-Host "  [OK] Shrimp data volume exists: shrimp_data" -ForegroundColor Green
    } else {
        $warnings += "Shrimp data volume (shrimp_data) not found - will be created on first run"
        Write-Host "  [INFO] Shrimp volume will be created automatically on first run" -ForegroundColor Gray
    }
} catch {
    $warnings += "Cannot check Shrimp Docker setup"
    Write-Host "  [WARN] Cannot check Shrimp" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Verification Summary ===" -ForegroundColor Cyan
if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "[OK] All checks passed!" -ForegroundColor Green
    exit 0
} else {
    if ($errors.Count -gt 0) {
        Write-Host "`nErrors ($($errors.Count)):" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  [ERROR] $error" -ForegroundColor Red
        }
    }
    if ($warnings.Count -gt 0) {
        Write-Host "`nWarnings ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  [WARN] $warning" -ForegroundColor Yellow
        }
    }
    exit 1
}
