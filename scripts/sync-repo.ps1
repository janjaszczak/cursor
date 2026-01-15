# Git repository sync script for Cursor
# Checks for clean working tree, then syncs with remote

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoPath = "C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor"

Push-Location $repoPath

try {
    # Check for uncommitted changes
    $status = git status --porcelain
    if ($status -and -not $Force) {
        Write-Host "Repository has uncommitted changes:" -ForegroundColor Yellow
        Write-Host $status
        Write-Host "`nUse -Force to sync anyway, or commit/stash changes first." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Fetching from remote..." -ForegroundColor Cyan
    git fetch origin

    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

    # Check if we're behind remote
    $localCommit = git rev-parse HEAD
    $remoteCommit = git rev-parse "origin/$currentBranch" 2>$null

    if ($remoteCommit -and $localCommit -ne $remoteCommit) {
        Write-Host "Pulling changes from remote..." -ForegroundColor Cyan
        git pull --rebase origin $currentBranch

        # Push any local commits if we have them
        $ahead = git rev-list --count "origin/$currentBranch..HEAD" 2>$null
        if ($ahead -gt 0) {
            Write-Host "Pushing local commits..." -ForegroundColor Cyan
            git push origin $currentBranch
        }
    } else {
        Write-Host "Repository is up to date." -ForegroundColor Green
    }

    Write-Host "`nSync completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error during sync: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
