# MCP (Model Context Protocol) Configuration

This document describes the MCP server setup and configuration for this project.

## Overview

All MCP servers are configured to run in **WSL**, even when Cursor is launched from Windows. This ensures consistent behavior across environments.

## Configuration File

MCP servers are configured in `.cursor/mcp.json`. This file contains **no secrets** - all sensitive data is provided via environment variables.

## MCP Servers

### 1. Memory (Neo4j)

**Purpose:** Long-term project memory storage in Neo4j graph database.

**Configuration:**
- Package: `@sylweriusz/mcp-neo4j-memory-server`
- Execution: `npx -y @sylweriusz/mcp-neo4j-memory-server`
- Environment variables (WSL):
  - `NEO4J_URI` - Connection URI (e.g., `neo4j://localhost:7687`)
  - `NEO4J_USERNAME` - Database username
  - `NEO4J_PASSWORD` - Database password
  - `NEO4J_DATABASE` - Database name (default: `neo4j`)

**Usage:**
- Store architectural decisions, constraints, and lessons learned
- Do NOT store passwords, API keys, or other secrets
- Use for cross-session knowledge persistence

### 2. Playwright

**Purpose:** Browser automation and web page interaction.

**Configuration:**
- Package: `@playwright/mcp@latest`
- Execution: `npx @playwright/mcp@latest`
- No environment variables required

**Usage:**
- End-to-end testing flows
- Web scraping (where allowed)
- UI validation instead of guessing page structure

### 3. DuckDuckGo

**Purpose:** External web search for up-to-date information.

**Configuration:**
- Package: `duckduckgo-mcp-server`
- Execution: `uvx duckduckgo-mcp-server`
- No environment variables required

**Usage:**
- Search for information not in repo, docs, or memory
- Verify current facts and technology updates
- Research external APIs and documentation

### 4. GitHub

**Purpose:** GitHub repository operations and management.

**Configuration:**
- Package: `github-mcp-custom@1.0.20` (pinned version)
- Execution: `npx -y github-mcp-custom@1.0.20 stdio`
- Environment variables (WSL):
  - `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub Personal Access Token

**Usage:**
- Inspect and modify remote repositories (only when explicitly asked)
- Never perform destructive operations without explicit confirmation:
  - Force pushes
  - Branch/tag deletions
  - Mass file deletions

### 5. Grafana

**Purpose:** Metrics, logs, and dashboards for debugging and performance.

**Configuration:**
- Package: `mcp/grafana` (Docker image)
- Execution: `docker run -i --rm -e GRAFANA_URL -e GRAFANA_API_KEY mcp/grafana --transport=stdio`
- Environment variables (WSL):
  - `GRAFANA_URL` - Grafana instance URL
  - `GRAFANA_API_KEY` - Grafana API key

**Usage:**
- Query metrics and logs for debugging
- Performance investigations
- All operations are read-only unless explicitly approved

### 6. Shrimp Task Manager

**Purpose:** Task planning, execution, and reflection.

**Configuration:**
- Location: `~/mcp-shrimp-task-manager/` (local build in WSL)
- Entry point: `~/mcp-shrimp-task-manager/dist/index.js`
- Execution: `node ~/mcp-shrimp-task-manager/dist/index.js`
- Environment variables (WSL):
  - `DATA_DIR` - Data storage directory (default: `~/.shrimp_data`)
  - `TEMPLATES_USE` - Template language (e.g., `en`)
  - `ENABLE_GUI` - GUI enabled (set to `false` for MCP)

**Usage:**
- Create task plans for complex work
- Track execution and reflect on results
- Store project rules and conventions

## Environment Variables Setup

All MCP environment variables must be set in **WSL only** (not Windows), since all MCPs run via `wsl.exe`.

**Setup script:**
```bash
cd /mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/cursor
./scripts/setup-env-vars.sh
```

**Manual setup:**
Add to `~/.profile` in WSL:
```bash
export NEO4J_URI="neo4j://localhost:7687"
export NEO4J_USERNAME="neo4j"
export NEO4J_PASSWORD="your_password"
export NEO4J_DATABASE="neo4j"
export GITHUB_PERSONAL_ACCESS_TOKEN="your_token"
export GRAFANA_URL="http://localhost:3001"
export GRAFANA_API_KEY="your_key"
```

## Execution Model

Most MCP servers are executed via Docker containers for consistency and isolation:

```json
{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e", "ENV_VAR_NAME",
    "mcp/server-name",
    "--transport=stdio"
  ]
}
```

**Docker-based servers:**
- **memory** (Neo4j) - `mcp/memory`
- **playwright** - `mcp/playwright`
- **duckduckgo** - `mcp/duckduckgo`
- **grafana** - `mcp/grafana`

**WSL-based servers (not yet migrated):**
- **github** - Uses `wsl.exe` with `npx` (no official Docker image available)
- **shrimp-task-manager** - Uses `wsl.exe` with local build (custom configuration)

### Docker Hub MCP Catalog

Most MCP server images are available from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp). This provides:
- **Official, maintained images** - Regularly updated by the community
- **Consistent execution environment** - Same behavior on Windows and WSL
- **Isolation** - Each server runs in its own container
- **Easy updates** - Pull latest images with `docker pull`

### Security: Environment Variables

**IMPORTANT:** All secrets are passed via environment variables (`-e VAR_NAME`), never hardcoded in `mcp.json`.

Environment variables must be set in WSL (where Docker runs):
- `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE`
- `GRAFANA_URL`, `GRAFANA_API_KEY`
- `GITHUB_PERSONAL_ACCESS_TOKEN` (for github server)

### Custom Docker Images

For servers without official Docker images, custom Dockerfiles are available in `docker/mcp-*/`:
- `docker/mcp-memory/` - Neo4j Memory MCP Server
- `docker/mcp-duckduckgo/` - DuckDuckGo MCP Server

Build custom images with:
```bash
.\scripts\build-mcp-images.ps1 --all
# or
./scripts/build-mcp-images.sh --all
```

## Security

- **No secrets in `mcp.json`** - all sensitive data via environment variables
- **Secrets in `env.local`** - committed to Git (rotate regularly)
- **KeePass integration** - recommended for production secret management

## Version Management

### Current Versions

| MCP Server | Current Version | Update Strategy |
|------------|----------------|----------------|
| memory (Neo4j) | `@sylweriusz/mcp-neo4j-memory-server` | `-y` (latest) |
| playwright | `@playwright/mcp@latest` | `@latest` |
| duckduckgo | `duckduckgo-mcp-server` | Latest via uvx |
| github | `github-mcp-custom@1.0.20` | **Pinned** |
| grafana | `mcp/grafana` | Latest Docker image |
| shrimp-task-manager | Local build | Manual update |

### Update Strategy

**Stable/Production MCPs:**
- Pin to specific versions (e.g., `github-mcp-custom@1.0.20`)
- Review and update monthly or when security updates are available

**Development/Utility MCPs:**
- Use `@latest` or `-y` for automatic updates
- Monitor for breaking changes

**Local Builds:**
- Update manually by pulling latest from source and rebuilding

### Update Process

**Monthly Review Checklist:**
1. Check for updates: `npm outdated -g` or `docker images | grep mcp`
2. Review changelogs on GitHub releases
3. Test updates one MCP at a time
4. Update `.cursor/mcp.json` and commit changes

**Updating npm-based MCPs:**
```bash
# Test new version
npx -y @package/name@new-version
# Update .cursor/mcp.json if pinning
# Restart Cursor
```

**Updating Docker-based MCPs:**
```bash
docker pull mcp/grafana
docker run -i --rm -e GRAFANA_URL -e GRAFANA_API_KEY mcp/grafana --transport=stdio
```

**Updating Shrimp (local build):**
```bash
cd ~/mcp-shrimp-task-manager
git pull origin main
npm install
npm run build
# Restart Cursor
```

### Rollback Procedure

If an MCP update causes issues:
1. Revert `.cursor/mcp.json` to previous version
2. For local builds: `git checkout <previous-commit>` then rebuild
3. Restart Cursor
4. Document the issue for future reference

### Security

- Apply security patches promptly
- Pin production MCPs to avoid unexpected changes
- Run `npm audit` for npm-based MCPs
- Monitor CVEs for known vulnerabilities
