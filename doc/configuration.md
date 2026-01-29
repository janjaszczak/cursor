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

**IMPORTANT:** Cursor passes MCP env vars from **the environment of the process that runs Cursor**. So they must be set in **Windows** when you start Cursor on Windows, and in **WSL** when you start Cursor from WSL.

**Required variables:**
- `NEO4J_URI` - Fixed in `mcp.json` as `neo4j://neo4j:7687` (no need to set in env).
- `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE` - Neo4j auth (must be in Cursor’s environment).
- `GITHUB_PERSONAL_ACCESS_TOKEN`, `GRAFANA_URL`, `GRAFANA_API_KEY`, `POSTMAN_API_KEY` - As needed.

**When Cursor runs on Windows:**
1. Edit `.env` in your `.cursor` folder (e.g. `C:\Users\<you>\.cursor\.env`).
2. Run PowerShell **as Administrator**, then:
   ```powershell
   cd $env:USERPROFILE\.cursor
   .\scripts\setup-env-vars.ps1
   ```
   The script reads `.env` and sets **Windows User** environment variables (NEO4J_*, GITHUB_*, etc.). Variables marked `CHANGE_ME` or empty are skipped.
3. **Restart Cursor** so it picks up the new User env. You can start Cursor from the Start menu or any shortcut.

**When Cursor runs on WSL:**
1. Edit `.env` (e.g. `~/.cursor/.env`).
2. Either run the setup script so vars are in your shell profile, or source `.env` before starting Cursor:
   ```bash
   cd ~/.cursor
   ./scripts/setup-env-vars.sh   # optional: --profile / --bashrc
   # Then start Cursor from a shell that has those vars, e.g.:
   set -a && source .env && set +a && cursor .
   ```

**File: `.env`**
- Contains all environment variables needed for MCP servers
- Format: `KEY=VALUE` (one per line, comments start with `#`)
- Not committed (in `.gitignore`); use `.env.example` as template
- Rotate secrets regularly

**Neo4j memory server — connection from Docker:**  
`mcp.json` uses a fixed URI `neo4j://neo4j:7687` (container name on `mcp-network`). Cursor passes only `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE` from your environment to the container.

- **Neo4j must be running in Docker on `mcp-network`.** One-time setup:
  ```bash
  cd ~/.cursor
  export NEO4J_PASSWORD=your_password   # or: set -a; source .env; set +a
  ./scripts/start-neo4j-mcp.sh
  ```
  Or manually: `docker network create mcp-network 2>/dev/null || true` then  
  `docker run -d --name neo4j --network mcp-network -p 7687:7687 -e NEO4J_AUTH=neo4j/YOUR_PASSWORD neo4j:latest`

- **Cursor must see `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE`** when it starts MCP:  
  **Windows:** run `setup-env-vars.ps1` as Administrator (sets User env from `.env`), then restart Cursor.  
  **WSL:** run Cursor from a shell that has sourced `.env` or has vars from `setup-env-vars.sh` (e.g. in `~/.profile`).

- **Neo4j container** can be started from WSL (`./scripts/start-neo4j-mcp.sh`) or from Windows (same Docker daemon with Docker Desktop WSL2 backend).

If MCP still logs "Failed to connect to Neo4j": (1) confirm container is up: `docker ps | grep neo4j`; (2) **Windows:** check User env in PowerShell: `[Environment]::GetEnvironmentVariable('NEO4J_PASSWORD','User')`.

### KeePassXC Integration

Secure secret management using KeePassXC with separate database for Cursor.

#### Configuration

**Database Location:**
- WSL: `/mnt/c/Users/janja/OneDrive/Dokumenty/Inne/cursor.kdbx`
- Windows: `C:\Users\janja\OneDrive\Dokumenty\Inne\cursor.kdbx`

**Environment Variable:**
- `KEEPASS_DB_PATH` - Set in `~/.profile` and `~/.bashrc` (WSL)

**Password Storage for Database:**
- **PowerShell SecretManagement** (primary method, stores database password only, accessible from both Windows and WSL)
- **secret-tool** (optional fallback for WSL, if D-Bus available)
- **Windows Credential Manager** (backup, write-only, cannot be read programmatically)

**Important:** 
- SecretManagement/secret-tool store **ONLY** the KeePassXC database password (stored securely in keyring, never in files or documentation), not passwords from the database
- All actual secrets/passwords (API tokens, service passwords, etc.) are stored **exclusively** in the KeePassXC database itself
- No file-based fallback exists - all password storage uses secure keyring mechanisms

Password is automatically saved by `save-keepass-password-to-keyring.sh` when database is open in GUI.

#### Usage

**Helper Script (Recommended):**

```bash
# Get password from entry
~/.cursor/scripts/get-keepass-secret.sh "Entry Title" "Password"

# Get API token
~/.cursor/scripts/get-keepass-secret.sh "GitHub Token" "Token"

# Get any attribute
~/.cursor/scripts/get-keepass-secret.sh "Entry Title" "Attribute Name"
```

**Direct keepassxc-cli:**

```bash
# List all entries
keepassxc-cli ls "$KEEPASS_DB_PATH"

# Show entry details
keepassxc-cli show "$KEEPASS_DB_PATH" "Entry Title"

# Get specific attribute
keepassxc-cli show -a "Password" "$KEEPASS_DB_PATH" "Entry Title"
```

**Save password to keyring:**

```bash
# Run script (requires database open in GUI)
~/.cursor/scripts/save-keepass-password-to-keyring.sh
```

#### SSH Agent

KeePassXC SSH Agent automatically loads SSH keys from database to system SSH agent when database is open in GUI.

**Verification:**
```powershell
# In PowerShell (Windows)
ssh-add -l
```

SSH keys are automatically available for all SSH connections (no need to specify `-i`).

#### Examples

**Get GitHub token:**
```bash
GITHUB_TOKEN=$(~/.cursor/scripts/get-keepass-secret.sh "GitHub Token" "Token")
export GITHUB_TOKEN
```

**Get database password:**
```bash
DB_PASSWORD=$(~/.cursor/scripts/get-keepass-secret.sh "Database Credentials" "Password")
```

#### Database Synchronization

The `cursor.kdbx` database can be synchronized with the main `jjaszczak.kdbx` database using:
- **KeeShare** (recommended) - GUI-based synchronization
- **Merge** - One-time database merge

See integration plan for detailed instructions.

#### Security Best Practices

1. **Never commit passwords to Git or documentation** - All secrets are in KeePassXC database. The database password must never appear in plain text in any file, including documentation.
2. **Use SSH Agent** - SSH keys are automatically loaded, not stored on disk
3. **Password in SecretManagement** - Safer than environment variables or files
4. **Separate Cursor database** - Isolation of Cursor secrets from main database
5. **Regular synchronization** - Use KeeShare or Merge to sync with main database
6. **Only database password in keyring** - All other secrets are exclusively in KeePassXC database

#### Documentation

- **Runbook (reproduce on another machine):** [doc/keepass-integration.md](keepass-integration.md)
- **Skill:** `~/.cursor/skills/keepass-integration/SKILL.md`
- **Integration Plan:** `~/.cursor/plans/keepassxc_integration_setup_6191af80.plan.md`
- **Scripts:** `~/.cursor/scripts/get-keepass-secret.sh`, `~/.cursor/scripts/save-keepass-password-to-keyring.sh`

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
- `verify-config.ps1` - Configuration verification

**WSL:**
- `setup-env-vars.sh` - Set MCP environment variables in WSL
- `verify-config.sh` - Configuration verification

**MCP Management Scripts:**
- `build-mcp-images.{ps1,sh}` - Build custom Docker images
- `test-mcp-servers.{ps1,sh}` - Test MCP server configuration
- `check-docker-images.{ps1,sh}` - Check Docker image availability
- `analyze-mcp-usage.{ps1,sh}` - Analyze MCP server usage

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
  - `NEO4J_PASSWORD` = (set in `.env`)
  - `NEO4J_DATABASE` = `neo4j`
  - `GITHUB_PERSONAL_ACCESS_TOKEN` = (set in `.env`)
  - `GRAFANA_URL` = `http://localhost:3001`
  - `GRAFANA_API_KEY` = (set in `.env`)

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

4 custom commands are defined:

1. `/save_memory` - Force write to Neo4j memory (no extra confirmation)
2. `/recall_memory` - Search Neo4j memory first before starting work
3. `/cleanup` - Post-work repo hygiene: audit → proposal → apply only after "APPLY CLEANUP"
4. `/retro` - Chat retrospective: issues, compliance audit, proposed improvements (USER RULES / PROJECT RULES / SKILLS / MEMORY); interactive APPLY

See [commands.md](commands.md) for full descriptions.

### Hooks

Cursor Agent Hooks allow observing and gating agent actions (e.g. require user authorization before writing secrets to files).

- **Configuration:** `~/.cursor/hooks.json` (user-level) or `<project>/.cursor/hooks.json` (project-level)
- **Scripts:** `~/.cursor/hooks/` or `.cursor/hooks/` (paths relative to config location)
- **Policy in this setup:** Do not block reading secret files; require authorization for **writing** secrets (e.g. to `.env`). Use preToolUse (Write), beforeShellExecution (matcher for .env), beforeMCPExecution.

See [hooks.md](hooks.md) for details and [Cursor Hooks](https://cursor.com/docs/agent/hooks) for the official reference.

### Global Configuration

**Windows:** `C:\Users\janja\.cursor\mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

**WSL:** `~/.cursor/mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

### Secrets Management

**File:** `.env` (not committed, in `.gitignore`)
- Contains all MCP environment variable values
- Format: `KEY=VALUE` (one per line)
- Rotate secrets regularly

**Template:** `.env.example`
- Shows required variables without actual values

### Git Repository

**Location:** `C:\Users\janja\.cursor\` (Windows) / `~/.cursor/` (WSL)
**Remote:** `https://github.com/janjaszczak/cursor-config.git` (to be configured)
**Branch:** `main`
**Sync:** Use Git manually (e.g. `git pull` / `git push`) or your preferred sync method to keep config in sync across machines.

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

1. Set `CURSOR_CONFIG_DIR` to point to your user `.cursor` directory (e.g. `C:\Users\janja\.cursor`). Run as Administrator:
   ```powershell
   [Environment]::SetEnvironmentVariable("CURSOR_CONFIG_DIR", "C:\Users\janja\.cursor", "User")
   ```
2. Backup and minimize global `%USERPROFILE%\.cursor\mcp.json` (e.g. replace contents with `{"mcpServers":{}}` or move the file aside).
3. Ensure your actual MCP config lives in the user `.cursor\mcp.json` (the one under `CURSOR_CONFIG_DIR`).

**Step 2: Fix WSL Configuration**

In WSL terminal:
```bash
# Add CURSOR_CONFIG_DIR to ~/.profile if not set
echo 'export CURSOR_CONFIG_DIR="$HOME/.cursor"' >> ~/.profile
source ~/.profile
# Backup and minimize global ~/.cursor/mcp.json if it exists outside CURSOR_CONFIG_DIR
# Ensure MCP config is in the directory pointed to by CURSOR_CONFIG_DIR
```

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

- **Windows**: `setup-env-vars.ps1` - Run PowerShell as Administrator to set `CURSOR_CONFIG_DIR`
- **WSL**: `setup-env-vars.sh` - Use `sudo` for system-wide variables, or run without for user variables