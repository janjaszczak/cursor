# Fix MCP Duplicates - Quick Guide

## Problem
- Windows shows duplicate MCP records
- Some MCPs are disabled
- WSL shows no MCPs

## Solution

### Step 1: Fix Windows Configuration

**Run as Administrator:**
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to repo: `cd C:\Users\janja\OneDrive\Dokumenty\GitHub\ai`
4. Run: `.\scripts\fix-mcp-duplicates.ps1`

This script will:
- Set `CURSOR_CONFIG_DIR` to point to repo `.cursor` directory
- Backup and minimize global `%USERPROFILE%\.cursor\mcp.json`
- Verify repo config is correct

### Step 2: Fix WSL Configuration

**In WSL terminal:**
```bash
cd /mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai
./scripts/fix-mcp-duplicates.sh
source ~/.profile
```

This script will:
- Add `CURSOR_CONFIG_DIR` to `~/.profile`
- Backup and minimize global `~/.cursor/mcp.json`
- Verify repo config is correct

### Step 3: Set Environment Variables

**Windows (as Administrator):**
```powershell
.\scripts\setup-env-vars.ps1
```

**WSL:**
```bash
./scripts/setup-env-vars.sh
# Or with sudo for system-wide:
sudo ./scripts/setup-env-vars.sh
```

Then replace `<SET_FROM_KEEPASS>` placeholders with actual secrets from KeePass.

### Step 4: Restart Cursor

1. **Completely close Cursor** (not just the window)
2. **Restart Cursor**
3. Check MCP settings - you should see MCPs from repo config only

### Step 5: Verify

**Windows:**
```powershell
.\scripts\verify-config.ps1
```

**WSL:**
```bash
./scripts/verify-config.sh
```

## Expected Result

- **Single source of truth**: Only repo `.cursor/mcp.json` contains MCP definitions
- **No duplicates**: Global configs are minimized (empty `mcpServers`)
- **All MCPs working**: All 6 MCPs (memory, playwright, duckduckgo, github, grafana, shrimp-task-manager) should be active
- **WSL accessible**: MCPs run via WSL even from Windows

## Troubleshooting

### Still seeing duplicates?
1. Check if `CURSOR_CONFIG_DIR` is set correctly
2. Verify global configs are minimized (should have empty `mcpServers`)
3. Restart Cursor completely (close all processes)

### MCPs not working?
1. Check environment variables are set (run verify script)
2. Verify WSL is accessible: `wsl.exe -- echo "WSL_OK"`
3. Check MCP server paths in repo `mcp.json` are correct

### WSL shows no MCPs?
1. Ensure `CURSOR_CONFIG_DIR` is in `~/.profile` and sourced
2. Restart terminal or run `source ~/.profile`
3. Restart Cursor
