# Cursor Configuration Guide

This repository serves as the **single source of truth** for Cursor configuration across Windows and WSL environments.

## Configuration Structure

All Cursor configuration files are located in `.cursor/`:

- **`.cursor/rules/`** - Project rules and conventions (workspace-level)
- **`.cursor/mcp.json`** - MCP server configurations (no secrets embedded)
- **`.cursor/cli-config.json`** - CLI permissions and editor settings

## Environment Setup

### CURSOR_CONFIG_DIR

Set this environment variable to point to the repo's `.cursor` directory:

**Windows (PowerShell):**
```powershell
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", "C:\Users\janja\OneDrive\Dokumenty\GitHub\ai\.cursor", "User")
```

**WSL (add to `~/.profile` or `~/.bashrc`):**
```bash
export CURSOR_CONFIG_DIR="/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai/.cursor"
```

After setting, restart Cursor for changes to take effect.

### MCP Environment Variables

MCP servers require environment variables for secrets. These should be set in your system environment (not in `mcp.json`):

**Required variables:**
- `NEO4J_URI` - Neo4j connection URI (e.g., `neo4j://localhost:7687`)
- `NEO4J_USERNAME` - Neo4j username
- `NEO4J_PASSWORD` - Neo4j password (use KeePass to manage)
- `NEO4J_DATABASE` - Database name (default: `neo4j`)
- `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub PAT (use KeePass)
- `GRAFANA_URL` - Grafana instance URL
- `GRAFANA_API_KEY` - Grafana API key (use KeePass)

**Setting in Windows:**
```powershell
[Environment]::SetEnvironmentVariable("NEO4J_URI", "neo4j://localhost:7687", "User")
# ... repeat for other variables
```

**Setting in WSL:**
Add to `~/.profile`:
```bash
export NEO4J_URI="neo4j://localhost:7687"
# ... repeat for other variables
```

### KeePass Integration

For secure secret management:

1. Store all secrets in KeePass
2. Use KeePassXC CLI or a startup script to populate environment variables before launching Cursor
3. Never commit secrets to Git

Example KeePassXC CLI usage:
```bash
# Export secret to env var
export GITHUB_PAT=$(keepassxc-cli show -a Password /path/to/db.kdbx "GitHub Token")
```

## MCP Server Execution

All MCP servers are configured to run via **WSL**, even when Cursor is launched from Windows. This ensures consistent behavior across environments.

The `mcp.json` configuration uses `wsl.exe` wrappers to route commands to WSL for execution.

## Repository Synchronization

Use the sync script to keep the repository synchronized across machines:

**Windows:**
```powershell
.\scripts\sync-repo.ps1
```

**WSL:**
```bash
./scripts/sync-repo.sh
```

**From Cursor:**
Add a keyboard shortcut in Cursor settings to run the sync script on demand.

The script will:
- Check for uncommitted changes (fails if found, unless `--force` is used)
- Fetch from remote
- Pull and rebase if behind
- Push local commits if ahead

## Shrimp Task Manager

Shrimp is installed globally in WSL at `~/mcp-shrimp-task-manager/`. Data is stored in `~/.shrimp_data/` (not synced via Git).

To update Shrimp:
```bash
cd ~/mcp-shrimp-task-manager
git pull
npm install
npm run build
```

## MCP Update Strategy

See [MCP_UPDATES.md](MCP_UPDATES.md) for details on updating MCP servers and version pinning.

## Troubleshooting

### MCP Duplicates or Not Working

If you see duplicate MCP records or MCPs are disabled:

1. **Run fix script (Windows as Administrator):**
   ```powershell
   # Right-click PowerShell -> Run as Administrator
   cd C:\Users\janja\OneDrive\Dokumenty\GitHub\ai
   .\scripts\fix-mcp-duplicates.ps1
   ```

2. **Run fix script (WSL):**
   ```bash
   cd /mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai
   ./scripts/fix-mcp-duplicates.sh
   source ~/.profile
   ```

3. **Restart Cursor completely**

See [FIX_MCP_DUPLICATES.md](FIX_MCP_DUPLICATES.md) for detailed instructions.

### Cursor not loading repo config

1. Verify `CURSOR_CONFIG_DIR` is set correctly
2. Restart Cursor completely
3. Check that `.cursor/` directory exists in repo root

### MCP servers not starting

1. Verify environment variables are set (check with `echo $VAR_NAME` in WSL)
2. Check that WSL is accessible from Windows
3. Verify MCP server dependencies are installed in WSL (Node.js, npm, etc.)

### Sync script fails

- Ensure Git is configured
- Check network connectivity
- Review error messages for specific issues

### Scripts Requiring Administrator/Sudo

Some scripts require elevated privileges:

- **Windows**: `setup-env-vars.ps1`, `fix-mcp-duplicates.ps1` - Run PowerShell as Administrator
- **WSL**: `setup-env-vars.sh` - Use `sudo` for system-wide variables, or run without for user variables
