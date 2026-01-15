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
        Write-Host "  ✓ CURSOR_CONFIG_DIR is set: $cursorConfigDir" -ForegroundColor Green
    } else {
        $errors += "CURSOR_CONFIG_DIR points to non-existent path: $cursorConfigDir"
        Write-Host "  ✗ CURSOR_CONFIG_DIR path does not exist" -ForegroundColor Red
    }
} else {
    $errors += "CURSOR_CONFIG_DIR is not set"
    Write-Host "  ✗ CURSOR_CONFIG_DIR is not set" -ForegroundColor Red
}

# Check repo .cursor directory
Write-Host "`nChecking repo .cursor directory..." -ForegroundColor Yellow
$repoCursorPath = "C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor"
if (Test-Path $repoCursorPath) {
    Write-Host "  ✓ Repo .cursor directory exists" -ForegroundColor Green
    
    # Check for required files
    $requiredFiles = @("mcp.json", "cli-config.json")
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $repoCursorPath $file
        if (Test-Path $filePath) {
            Write-Host "    ✓ $file exists" -ForegroundColor Green
        } else {
            $errors += "Required file missing: $file"
            Write-Host "    ✗ $file missing" -ForegroundColor Red
        }
    }
    
    # Check rules directory
    $rulesPath = Join-Path $repoCursorPath "rules"
    if (Test-Path $rulesPath) {
        $ruleCount = (Get-ChildItem $rulesPath -Filter "*.mdc").Count
        Write-Host "    ✓ Rules directory exists ($ruleCount rules)" -ForegroundColor Green
    } else {
        $warnings += "Rules directory not found"
        Write-Host "    ⚠ Rules directory not found" -ForegroundColor Yellow
    }
} else {
    $errors += "Repo .cursor directory does not exist"
    Write-Host "  ✗ Repo .cursor directory does not exist" -ForegroundColor Red
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
    "GRAFANA_API_KEY"
)

foreach ($var in $requiredEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        if ($value -match "^<SET_FROM_KEEPASS>|^$") {
            $warnings += "$var is not set (placeholder or empty)"
            Write-Host "  ⚠ $var is not set (needs KeePass)" -ForegroundColor Yellow
        } else {
            Write-Host "  ✓ $var is set" -ForegroundColor Green
        }
    } else {
        $warnings += "$var is not set"
        Write-Host "  ⚠ $var is not set" -ForegroundColor Yellow
    }
}

# Check WSL accessibility
Write-Host "`nChecking WSL accessibility..." -ForegroundColor Yellow
try {
    $wslTest = wsl.exe -- bash -lc "echo 'WSL_OK'" 2>&1
    if ($wslTest -match "WSL_OK") {
        Write-Host "  ✓ WSL is accessible" -ForegroundColor Green
    } else {
        $errors += "WSL is not accessible"
        Write-Host "  ✗ WSL is not accessible" -ForegroundColor Red
    }
} catch {
    $errors += "Cannot test WSL: $_"
    Write-Host "  ✗ Cannot test WSL" -ForegroundColor Red
}

# Check Shrimp installation
Write-Host "`nChecking Shrimp Task Manager..." -ForegroundColor Yellow
try {
    $shrimpPath = wsl.exe -- bash -lc "test -f ~/mcp-shrimp-task-manager/dist/index.js && echo 'EXISTS' || echo 'MISSING'" 2>&1
    if ($shrimpPath -match "EXISTS") {
        Write-Host "  ✓ Shrimp is installed in WSL" -ForegroundColor Green
    } else {
        $warnings += "Shrimp Task Manager not found in WSL"
        Write-Host "  ⚠ Shrimp not found in WSL" -ForegroundColor Yellow
    }
} catch {
    $warnings += "Cannot check Shrimp installation"
    Write-Host "  ⚠ Cannot check Shrimp" -ForegroundColor Yellow
}

# Check sync scripts
Write-Host "`nChecking sync scripts..." -ForegroundColor Yellow
$syncScripts = @("scripts\sync-repo.ps1", "scripts\sync-repo.sh")
foreach ($script in $syncScripts) {
    if (Test-Path $script) {
        Write-Host "  ✓ $script exists" -ForegroundColor Green
    } else {
        $warnings += "Sync script missing: $script"
        Write-Host "  ⚠ $script missing" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== Verification Summary ===" -ForegroundColor Cyan
if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ All checks passed!" -ForegroundColor Green
    exit 0
} else {
    if ($errors.Count -gt 0) {
        Write-Host "`nErrors ($($errors.Count)):" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }
    }
    if ($warnings.Count -gt 0) {
        Write-Host "`nWarnings ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }
    exit 1
}
