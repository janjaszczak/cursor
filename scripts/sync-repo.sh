#!/bin/bash
# Git repository sync script for Cursor
# Checks for clean working tree, then syncs with remote

set -e

REPO_PATH="/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai"
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

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
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
    echo "Repository is up to date."
fi

echo ""
echo "Sync completed successfully."
