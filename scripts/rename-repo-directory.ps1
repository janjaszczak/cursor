# Script to rename repository directory from 'ai' to 'cursor'
# IMPORTANT: Close Cursor and all terminals before running this script!
# Run as Administrator: Right-click PowerShell -> Run as Administrator

$ErrorActionPreference = "Stop"

Write-Host "=== Rename Repository Directory ===" -ForegroundColor Cyan
Write-Host ""

$parentDir = "C:\Users\janja\OneDrive\Dokumenty\GitHub"
$oldDir = Join-Path $parentDir "ai"
$newDir = Join-Path $parentDir "cursor"

# Check if old directory exists
if (-not (Test-Path $oldDir)) {
    Write-Host "[ERROR] Directory not found: $oldDir" -ForegroundColor Red
    Write-Host "Directory may have already been renamed." -ForegroundColor Yellow
    exit 1
}

# Check if new directory already exists
if (Test-Path $newDir) {
    Write-Host "[ERROR] Directory already exists: $newDir" -ForegroundColor Red
    Write-Host "Cannot rename - target directory exists." -ForegroundColor Yellow
    exit 1
}

# Try to rename
Write-Host "Attempting to rename directory..." -ForegroundColor Yellow
Write-Host "  From: $oldDir" -ForegroundColor Gray
Write-Host "  To:   $newDir" -ForegroundColor Gray
Write-Host ""

try {
    Rename-Item -Path $oldDir -NewName "cursor" -Force
    Write-Host "[OK] Directory renamed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Update remote URL if configured
    Push-Location $newDir
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl) {
        if ($remoteUrl -match "janjaszczak/ai") {
            git remote set-url origin "https://github.com/janjaszczak/cursor.git"
            Write-Host "[OK] Remote URL updated to: https://github.com/janjaszczak/cursor.git" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Remote URL: $remoteUrl" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[INFO] No remote configured" -ForegroundColor Yellow
    }
    Pop-Location
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Update CURSOR_CONFIG_DIR environment variable:" -ForegroundColor White
    Write-Host "     Windows: Run .\scripts\setup-env-vars.ps1 (as Administrator)" -ForegroundColor Gray
    Write-Host "     WSL: Run ./scripts/setup-env-vars.sh" -ForegroundColor Gray
    Write-Host "  2. Restart Cursor to apply changes" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "[ERROR] Failed to rename directory!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "The directory may be in use. Please:" -ForegroundColor Yellow
    Write-Host "  1. Close Cursor completely" -ForegroundColor White
    Write-Host "  2. Close all terminals/command prompts" -ForegroundColor White
    Write-Host "  3. Close any file explorers with this directory open" -ForegroundColor White
    Write-Host "  4. Run this script again" -ForegroundColor White
    exit 1
}
