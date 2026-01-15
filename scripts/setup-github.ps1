# Setup GitHub repository connection
# Reads GitHub token from env.local and configures remote

$ErrorActionPreference = "Stop"

Write-Host "=== GitHub Repository Setup ===" -ForegroundColor Cyan
Write-Host ""

# Get GitHub token from env.local
$envFile = Join-Path (Split-Path $PSScriptRoot -Parent) "env.local"
if (-not (Test-Path $envFile)) {
    Write-Host "[ERROR] env.local not found!" -ForegroundColor Red
    exit 1
}

$token = (Get-Content $envFile | Select-String "GITHUB_PERSONAL_ACCESS_TOKEN" | ForEach-Object {
    ($_ -split "=")[1].Trim()
})

if (-not $token -or $token -eq "CHANGE_ME") {
    Write-Host "[ERROR] GitHub token not set in env.local!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] GitHub token found" -ForegroundColor Green

# Get GitHub username
$headers = @{
    Authorization = "token $token"
    Accept = "application/vnd.github.v3+json"
}

try {
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
    Write-Host "[OK] GitHub user: $($user.login)" -ForegroundColor Green
    $username = $user.login
} catch {
    Write-Host "[ERROR] Failed to get GitHub user: $_" -ForegroundColor Red
    exit 1
}

# Check if repo exists, create if needed
Write-Host ""
Write-Host "Checking for repository 'ai'..." -ForegroundColor Yellow
try {
    $repos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?per_page=100" -Headers $headers
    $aiRepo = $repos | Where-Object { $_.name -eq "ai" }
    
    if ($aiRepo) {
        Write-Host "[INFO] Repository 'ai' exists: $($aiRepo.html_url)" -ForegroundColor Yellow
        Write-Host "[WARNING] If this is a fork, please delete it manually on GitHub and run this script again." -ForegroundColor Yellow
        Write-Host "[WARNING] Or we will force push to replace its contents." -ForegroundColor Yellow
        $repoUrl = $aiRepo.html_url
    } else {
        Write-Host "[INFO] Repository 'ai' not found. Creating..." -ForegroundColor Yellow
        $body = @{
            name = "ai"
            private = $true
            auto_init = $false
            description = "Cursor configuration and MCP setup"
        } | ConvertTo-Json
        
        $newRepo = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body
        Write-Host "[OK] Created new repository: $($newRepo.html_url)" -ForegroundColor Green
        $repoUrl = $newRepo.html_url
    }
} catch {
    Write-Host "[ERROR] Failed to manage repository: $_" -ForegroundColor Red
    Write-Host "[INFO] You may need to delete the repository manually on GitHub if it's a fork." -ForegroundColor Yellow
    exit 1
}

# Configure git remote
Write-Host ""
Write-Host "Configuring git remote..." -ForegroundColor Yellow
$repoPath = Split-Path $PSScriptRoot -Parent
Push-Location $repoPath

try {
    # Try to add remote (will fail if exists, then update)
    $addResult = git remote add origin $repoUrl 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Added remote 'origin'" -ForegroundColor Green
    } else {
        # Remote exists, update it
        git remote set-url origin $repoUrl
        Write-Host "[OK] Updated remote 'origin' URL" -ForegroundColor Green
    }
    
    # Verify
    Write-Host ""
    Write-Host "Remote configuration:" -ForegroundColor Cyan
    git remote -v
    
    Write-Host ""
    Write-Host "[OK] GitHub repository configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Commit your changes: git add . && git commit -m 'Add Cursor config'" -ForegroundColor White
    Write-Host "  2. Push to GitHub: git push -u origin main" -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] Failed to configure remote: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
