# Troubleshooting

This document covers common issues and their solutions.

## Understanding Duplicates

**Why duplicates occur:** Cursor automatically creates a `.cursor/` directory in any folder you open. If you have:
- A global `.cursor/` in `%USERPROFILE%\.cursor\` (Windows) or `~/.cursor/` (WSL)
- A project `.cursor/` in the repository
- `CURSOR_CONFIG_DIR` pointing to the repo

Cursor may load configurations from multiple locations, causing duplicates.

**Solution:** Use `CURSOR_CONFIG_DIR` to point to a single source of truth (this repo's `.cursor/`), and minimize global configs to empty `mcpServers: {}`.

This principle applies to **all Cursor configuration** (rules, MCP, CLI config), not just MCP servers.

## Fixing MCP Duplicates

### Problem
- Windows shows duplicate MCP records
- Some MCPs are disabled
- WSL shows no MCPs

### Solution

**Step 1: Fix Windows Configuration**

Run as Administrator:
```powershell
cd C:\Users\janja\.cursor
.\scripts\fix-mcp-duplicates.ps1
```

This script will:
- Set `CURSOR_CONFIG_DIR` to point to user `.cursor` directory
- Backup and minimize global `%USERPROFILE%\.cursor\mcp.json`
- Verify user config is correct

**Step 2: Fix WSL Configuration**

In WSL terminal:
```bash
cd ~/.cursor
./scripts/fix-mcp-duplicates.sh
source ~/.profile
```

This script will:
- Add `CURSOR_CONFIG_DIR` to `~/.profile`
- Backup and minimize global `~/.cursor/mcp.json`
- Verify user config is correct

**Step 3: Set Environment Variables**

**Windows (as Administrator):**
```powershell
.\scripts\setup-env-vars.ps1
```
This sets only `CURSOR_CONFIG_DIR` in Windows (MCP env vars are not needed in Windows).

**WSL:**
```bash
./scripts/setup-env-vars.sh
# Or with sudo for system-wide:
sudo ./scripts/setup-env-vars.sh
```
This sets all MCP environment variables in WSL (where MCPs actually run).

**Note:** All MCP servers run in WSL, so MCP environment variables (NEO4J_*, GITHUB_*, GRAFANA_*) should be set only in WSL, not in Windows.

**Step 4: Restart Cursor**

1. **Completely close Cursor** (not just the window)
2. **Restart Cursor**
3. Check MCP settings - you should see MCPs from repo config only

**Step 5: Verify**

**Windows:**
```powershell
.\scripts\verify-config.ps1
```

**WSL:**
```bash
./scripts/verify-config.sh
```

### Expected Result

- **Single source of truth**: Only user `.cursor/mcp.json` contains MCP definitions
- **No duplicates**: Global configs are minimized (empty `mcpServers`)
- **All MCPs working**: All 6 MCPs should be active
- **WSL accessible**: MCPs run via WSL even from Windows

## Common Issues

### Still seeing duplicates?

1. Check if `CURSOR_CONFIG_DIR` is set correctly
2. Verify global configs are minimized (should have empty `mcpServers`)
3. Restart Cursor completely (close all processes)

### Cursor not loading user config

1. Verify `CURSOR_CONFIG_DIR` is set correctly
2. Restart Cursor completely
3. Check that `.cursor/` directory exists in user home directory

### MCP servers not starting

1. Verify environment variables are set (check with `echo $VAR_NAME` in WSL)
2. Check that WSL is accessible from Windows: `wsl.exe -- echo "WSL_OK"`
3. Verify MCP server dependencies are installed in WSL (Node.js, npm, etc.)

### MCPs not working?

1. Check environment variables are set (run verify script)
2. Verify WSL is accessible: `wsl.exe -- echo "WSL_OK"`
3. Check MCP server paths in user `mcp.json` are correct

### WSL shows no MCPs?

1. Ensure `CURSOR_CONFIG_DIR` is in `~/.profile` and sourced
2. Restart terminal or run `source ~/.profile`
3. Restart Cursor

### Sync script fails

- Ensure Git is configured
- Check network connectivity
- Review error messages for specific issues

### Scripts Requiring Administrator/Sudo

Some scripts require elevated privileges:

- **Windows**: `setup-env-vars.ps1`, `fix-mcp-duplicates.ps1` - Run PowerShell as Administrator
- **WSL**: `setup-env-vars.sh` - Use `sudo` for system-wide variables, or run without for user variables
