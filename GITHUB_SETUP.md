# GitHub Repository Setup

## Current Status

- ✅ Repository initialized (branch: `main`)
- ✅ 3 commits exist
- ❌ Remote not configured (no connection to GitHub)

## Setup Steps

### Option 1: Create New Repository on GitHub

1. **Go to GitHub**: https://github.com/new
2. **Create repository**:
   - Repository name: `ai` (or your preferred name)
   - Visibility: Private/Public (your choice)
   - **DO NOT** initialize with README, .gitignore, or license
3. **Copy repository URL** (HTTPS or SSH)

### Option 2: Connect to Existing Repository

If repository already exists on GitHub, just get the URL.

## Connect Local Repository to GitHub

### Using HTTPS:
```powershell
cd C:\Users\janja\OneDrive\Dokumenty\GitHub\ai
git remote add origin https://github.com/YOUR_USERNAME/ai.git
git branch -M main
git push -u origin main
```

### Using SSH:
```powershell
cd C:\Users\janja\OneDrive\Dokumenty\GitHub\ai
git remote add origin git@github.com:YOUR_USERNAME/ai.git
git branch -M main
git push -u origin main
```

## Before Pushing

Make sure to commit current changes:
```powershell
git add .
git commit -m "Add Cursor configuration and MCP setup"
git push -u origin main
```

## Verify Connection

After setup, verify:
```powershell
git remote -v
```

Should show:
```
origin  https://github.com/YOUR_USERNAME/ai.git (fetch)
origin  https://github.com/YOUR_USERNAME/ai.git (push)
```

## Troubleshooting

### Authentication Issues
- Use GitHub Personal Access Token (PAT) for HTTPS
- Or configure SSH keys for SSH
- Token should have `repo` scope

### Repository Already Exists
If you get "repository already exists" error:
```powershell
git remote set-url origin https://github.com/YOUR_USERNAME/ai.git
git push -u origin main
```
