# Current Setup

This document describes the current state of the Cursor configuration setup.

## Configuration Location

**Single source of truth:** `C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor\`

This directory contains:
- `rules/` - Project rules (8 files)
- `mcp.json` - MCP server configurations
- `cli-config.json` - CLI permissions
- `commands/` - Custom commands (2 files)

## Environment Variables

### Windows
- `CURSOR_CONFIG_DIR` = `C:\Users\janja\OneDrive\Dokumenty\GitHub\cursor\.cursor`
  - Set via: `scripts/setup-env-vars.ps1` (as Administrator)

### WSL
- `CURSOR_CONFIG_DIR` = `/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/cursor/.cursor`
  - Set in: `~/.profile`
- MCP environment variables (all in WSL):
  - `NEO4J_URI` = `neo4j://localhost:7687`
  - `NEO4J_USERNAME` = `neo4j`
  - `NEO4J_PASSWORD` = (set in `env.local`)
  - `NEO4J_DATABASE` = `neo4j`
  - `GITHUB_PERSONAL_ACCESS_TOKEN` = (set in `env.local`)
  - `GRAFANA_URL` = `http://localhost:3001`
  - `GRAFANA_API_KEY` = (set in `env.local`)

## MCP Servers

All 6 MCP servers are configured and running:

1. **memory** - Neo4j memory server (`@sylweriusz/mcp-neo4j-memory-server`)
2. **playwright** - Browser automation (`@playwright/mcp@latest`)
3. **duckduckgo** - Web search (`duckduckgo-mcp-server` via uvx)
4. **github** - GitHub operations (`github-mcp-custom@1.0.20` - pinned)
5. **grafana** - Metrics/dashboards (`mcp/grafana` Docker image)
6. **shrimp-task-manager** - Task planning (local build at `~/mcp-shrimp-task-manager/`)

All MCPs execute via WSL (`wsl.exe` wrapper) for consistency.

## Rules

8 project rules are defined:

1. `quality.mdc` - Global engineering policies (always applied)
2. `mcp-tools.mdc` - MCP usage guidelines (always applied)
3. `next-stack.mdc` - Next.js stack conventions (`frontend/**`)
4. `python-backend.mdc` - FastAPI conventions (`backend/**`)
5. `python-style.mdc` - Python style guide (`**/*.py`)
6. `vanilla-web.mdc` - Vanilla web conventions (`**/*.{html,css,js}`)
7. `parsers.mdc` - Data parsing rules (`data/**`)
8. `solid.mdc` - SOLID principles (`**/*.{ts,tsx,js,jsx,py,env,yml,md}`)

## Commands

2 custom commands are defined:

1. `/save_memory` - Force write to Neo4j memory
2. `/recall_memory` - Search Neo4j memory first

## Scripts

Available utility scripts:

**Windows:**
- `setup-env-vars.ps1` - Set `CURSOR_CONFIG_DIR` in Windows
- `sync-repo.ps1` - Git repository synchronization
- `verify-config.ps1` - Configuration verification
- `fix-mcp-duplicates.ps1` - Fix MCP duplicate issues

**WSL:**
- `setup-env-vars.sh` - Set MCP environment variables in WSL
- `sync-repo.sh` - Git repository synchronization
- `verify-config.sh` - Configuration verification
- `fix-mcp-duplicates.sh` - Fix MCP duplicate issues

**MCP Wrappers:**
- `mcp-run-npx.{ps1,sh}` - For npx-based MCPs
- `mcp-run-node.{ps1,sh}` - For node-based MCPs
- `mcp-run-uvx.{ps1,sh}` - For uvx-based MCPs
- `mcp-run-docker.{ps1,sh}` - For Docker-based MCPs
- `mcp-run-shrimp.{ps1,sh}` - For Shrimp Task Manager

## Global Configuration

**Windows:** `C:\Users\janja\.cursor\mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

**WSL:** `~/.cursor/mcp.json`
- Status: Minimized (empty `mcpServers: {}`)
- Purpose: Prevents duplicates when `CURSOR_CONFIG_DIR` is set

## Secrets Management

**File:** `env.local` (committed to Git)
- Contains all MCP environment variable values
- Format: `KEY=VALUE` (one per line)
- Rotate secrets regularly

**Template:** `env.local.example`
- Shows required variables without actual values

## Git Repository

**Remote:** `https://github.com/janjaszczak/cursor`
**Branch:** `main`
**Sync:** Use `scripts/sync-repo.{ps1,sh}` to synchronize across machines

## Verification

Run verification scripts to check setup:

**Windows:**
```powershell
.\scripts\verify-config.ps1
```

**WSL:**
```bash
./scripts/verify-config.sh
```

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for detailed troubleshooting guide.

## Last Updated

Configuration last verified: 2025-01-15
