# Configuration Guide

This document describes how to configure Cursor for this project.

## Configuration Structure

All Cursor configuration files are located in `.cursor/`:

- **`.cursor/rules/`** - Project rules and conventions (workspace-level)
- **`.cursor/mcp.json`** - MCP server configurations (no secrets embedded)
- **`.cursor/cli-config.json`** - CLI permissions and editor settings
- **`.cursor/commands/`** - Custom commands

## Environment Setup

### CURSOR_CONFIG_DIR

Set this environment variable to point to the repo's `.cursor` directory:

**Windows (PowerShell as Administrator):**
```powershell
[Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", "C:\Users\janja\.cursor", "User")
```

Or use the setup script:
```powershell
.\scripts\setup-env-vars.ps1
```

**WSL (add to `~/.profile`):**
```bash
export CURSOR_CONFIG_DIR="$HOME/.cursor"
```

Or use the setup script:
```bash
./scripts/setup-env-vars.sh
```

After setting, restart Cursor for changes to take effect.

### MCP Environment Variables

**IMPORTANT:** All MCP servers run in WSL (via `wsl.exe`), so MCP environment variables should be set **only in WSL**, not in Windows.

**Required variables (WSL only):**
- `NEO4J_URI` - Neo4j connection URI (e.g., `neo4j://localhost:7687`)
- `NEO4J_USERNAME` - Neo4j username
- `NEO4J_PASSWORD` - Neo4j password
- `NEO4J_DATABASE` - Database name (default: `neo4j`)
- `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub PAT
- `GRAFANA_URL` - Grafana instance URL
- `GRAFANA_API_KEY` - Grafana API key

**Setting in WSL:**
1. Edit `env.local` file with your actual secrets (located in `~/.cursor/env.local`)
2. Run the setup script:
   ```bash
   cd ~/.cursor
   ./scripts/setup-env-vars.sh
   # Or with sudo for system-wide:
   sudo ./scripts/setup-env-vars.sh
   ```

The script reads `env.local` and sets environment variables. Variables marked as `CHANGE_ME` or empty are skipped.

**File: `env.local`**
- Contains all environment variables needed for MCP servers
- Format: `KEY=VALUE` (one per line, comments start with `#`)
- This file is committed to Git (not in `.gitignore`)
- Rotate secrets regularly

### KeePass Integration

For secure secret management:

1. Store all secrets in KeePass
2. Use KeePassXC CLI or a startup script to populate environment variables before launching Cursor
3. Never commit secrets to Git

Example KeePassXC CLI usage:
```bash
export GITHUB_PAT=$(keepassxc-cli show -a Password /path/to/db.kdbx "GitHub Token")
```

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

Shrimp Task Manager is installed locally in WSL at `~/mcp-shrimp-task-manager/`. Data is stored in `~/.shrimp_data/` (not synced via Git).

**Configuration:**
- Entry point: `~/mcp-shrimp-task-manager/dist/index.js`
- Configured in `.cursor/mcp.json` to run via WSL
- Environment variables: `DATA_DIR`, `TEMPLATES_USE`, `ENABLE_GUI`

**To update Shrimp:**
```bash
cd ~/mcp-shrimp-task-manager
git pull
npm install
npm run build
# Restart Cursor to apply changes
```

## Scripts

Available utility scripts:

**Windows (run as Administrator):**
- `setup-env-vars.ps1` - Set `CURSOR_CONFIG_DIR` in Windows
- `sync-repo.ps1` - Git repository synchronization
- `verify-config.ps1` - Configuration verification
- `fix-mcp-duplicates.ps1` - Fix MCP duplicate issues

**WSL:**
- `setup-env-vars.sh` - Set MCP environment variables in WSL
- `sync-repo.sh` - Git repository synchronization
- `verify-config.sh` - Configuration verification
- `fix-mcp-duplicates.sh` - Fix MCP duplicate issues

**MCP Management Scripts:**
- `build-mcp-images.{ps1,sh}` - Build custom Docker images
- `test-mcp-servers.{ps1,sh}` - Test MCP server configuration
- `check-docker-images.{ps1,sh}` - Check Docker image availability
- `analyze-mcp-usage.{ps1,sh}` - Analyze MCP server usage
- `generate-mcp-config.{ps1,sh}` - Generate mcp.json dynamically

**Note:** Legacy MCP wrapper scripts have been archived. All MCP servers now use Docker for cross-platform consistency.
