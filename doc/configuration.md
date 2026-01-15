# Configuration Guide

This document describes how to configure Cursor for this project, including current setup state.

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

**IMPORTANT:** All MCP servers run in Docker containers, and Docker runs in WSL. Therefore, MCP environment variables should be set **only in WSL**, not in Windows.

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

Shrimp Task Manager runs in a Docker container (`mcp/shrimp`). The Dockerfile clones and builds from the official GitHub repository. Data is stored in a Docker named volume (`shrimp_data`).

**Configuration:**
- Docker image: `mcp/shrimp` (built from `docker/mcp-shrimp/Dockerfile`)
- Data volume: `shrimp_data` (Docker named volume)
- Environment variables: `DATA_DIR`, `TEMPLATES_USE`, `ENABLE_GUI`, plus `MCP_PROMPT_*` variables

**To update Shrimp:**
```bash
# Rebuild the Docker image
.\scripts\build-mcp-images.ps1 --shrimp
# Restart Cursor to apply changes
```

See [mcp.md](mcp.md) for Docker volume management and backup procedures.

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

## Current Setup

### Configuration Location

**Single source of truth:** `C:\Users\janja\.cursor\` (Windows) / `~/.cursor/` (WSL)

This directory contains:
- `rules/` - Project rules (6 files)
- `mcp.json` - MCP server configurations
- `cli-config.json` - CLI permissions
- `commands/` - Custom commands (3 files)
- `scripts/` - Utility scripts
- `doc/` - Documentation

### Environment Variables

**Windows:**
- `CURSOR_CONFIG_DIR` = `C:\Users\janja\.cursor`
  - Set via: `scripts/setup-env-vars.ps1` (as Administrator)

**WSL:**
- `CURSOR_CONFIG_DIR` = `~/.cursor` or `$HOME/.cursor`
  - Set in: `~/.profile`
- MCP environment variables (all in WSL):
  - `NEO4J_URI` = `neo4j://localhost:7687`
  - `NEO4J_USERNAME` = `neo4j`
  - `NEO4J_PASSWORD` = (set in `env.local`)
  - `NEO4J_DATABASE` = `neo4j`
  - `GITHUB_PERSONAL_ACCESS_TOKEN` = (set in `env.local`)
  - `GRAFANA_URL` = `http://localhost:3001`
  - `GRAFANA_API_KEY` = (set in `env.local`)

### MCP Servers

All 6 MCP servers are configured and running in Docker containers:

1. **memory** - Neo4j memory server (`mcp/memory`)
2. **playwright** - Browser automation (`mcp/playwright`)
3. **duckduckgo** - Web search (`mcp/duckduckgo`)
4. **github** - GitHub operations (`mcp/github`)
5. **grafana** - Metrics/dashboards (`mcp/grafana`)
6. **shrimp-task-manager** - Task planning (`mcp/shrimp`, built from GitHub)

All MCPs execute via Docker for cross-platform consistency (Windows and WSL).

### Rules

6 project rules are defined (context-specific):

1. `next-stack.mdc` - Next.js stack conventions (`frontend/**`)
2. `python-backend.mdc` - FastAPI conventions (`backend/**`)
3. `python-style.mdc` - Python style guide (`**/*.py`)
4. `vanilla-web.mdc` - Vanilla web conventions (`**/*.{html,css,js}`)
5. `parsers.mdc` - Data parsing rules (`data/**`)
6. `solid.mdc` - SOLID principles (`**/*.{ts,tsx,js,jsx,py,env,yml,md}`)

**Note:** Global engineering policies (quality, MCP tools usage) are now integrated into `cursor-user_roles.txt` at the repository root. This provides a single source of truth for workflow, quality requirements, and MCP tool usage guidelines.

### Commands

2 custom commands are defined:

1. `/save_memory` - Force write to Neo4j memory
2. `/recall_memory` - Search Neo4j memory first

### Global Configuration

**Windows:** `C:\Users\janja\.cursor\mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

**WSL:** `~/.cursor/mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

### Secrets Management

**File:** `env.local` (committed to Git)
- Contains all MCP environment variable values
- Format: `KEY=VALUE` (one per line)
- Rotate secrets regularly

**Template:** `env.local.example`
- Shows required variables without actual values

### Git Repository

**Location:** `C:\Users\janja\.cursor\` (Windows) / `~/.cursor/` (WSL)
**Remote:** `https://github.com/janjaszczak/cursor-config.git` (to be configured)
**Branch:** `main`
**Sync:** Use `scripts/sync-repo.{ps1,sh}` to synchronize between Windows and WSL via GitHub

### Verification

Run verification scripts to check setup:

**Windows:**
```powershell
.\scripts\verify-config.ps1
```

**WSL:**
```bash
./scripts/verify-config.sh
```

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
- **WSL accessible**: MCPs run via Docker (which runs in WSL)

## Common Issues

### Still seeing duplicates?

1. Check if `CURSOR_CONFIG_DIR` is set correctly
2. Verify global configs are minimized (should have empty `mcpServers`)
3. Restart Cursor completely (close all processes)

### Cursor not loading user config

1. Verify `CURSOR_CONFIG_DIR` is set correctly
2. Restart Cursor completely
3. Check that `.cursor/` directory exists in user home directory

### Scripts Requiring Administrator/Sudo

Some scripts require elevated privileges:

- **Windows**: `setup-env-vars.ps1`, `fix-mcp-duplicates.ps1` - Run PowerShell as Administrator
- **WSL**: `setup-env-vars.sh` - Use `sudo` for system-wide variables, or run without for user variables
