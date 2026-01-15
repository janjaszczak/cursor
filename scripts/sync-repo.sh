#!/bin/bash
# Git repository sync script for Cursor
# Checks for clean working tree, then syncs with remote

set -e

REPO_PATH="$HOME/.cursor"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cd "$REPO_PATH"

# Check if remote is configured
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "No remote 'origin' configured. Use 'git remote add origin <url>' first."
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ] && [ "$FORCE" = false ]; then
    echo "Repository has uncommitted changes:"
    git status --short
    echo ""
    echo "Use --force to sync anyway, or commit/stash changes first."
    exit 1
fi

echo "Fetching from remote..."
git fetch origin

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -z "$CURRENT_BRANCH" ]; then
    echo "No branch checked out. Creating 'main' branch..."
    git checkout -b main
    CURRENT_BRANCH="main"
fi
echo "Current branch: $CURRENT_BRANCH"

# Check if we're behind remote
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse "origin/$CURRENT_BRANCH" 2>/dev/null || echo "")

if [ -n "$REMOTE_COMMIT" ] && [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo "Pulling changes from remote..."
    git pull --rebase origin "$CURRENT_BRANCH"

    # Push any local commits if we have them
    AHEAD=$(git rev-list --count "origin/$CURRENT_BRANCH..HEAD" 2>/dev/null || echo "0")
    if [ "$AHEAD" -gt 0 ]; then
        echo "Pushing local commits..."
        git push origin "$CURRENT_BRANCH"
    fi
else
    # Push local commits if we're ahead
    AHEAD=$(git rev-list --count "origin/$CURRENT_BRANCH..HEAD" 2>/dev/null || echo "0")
    if [ "$AHEAD" -gt 0 ]; then
        echo "Pushing local commits..."
        git push origin "$CURRENT_BRANCH"
    else
        echo "Repository is up to date."
    fi
fi

echo ""
echo "Sync completed successfully."
