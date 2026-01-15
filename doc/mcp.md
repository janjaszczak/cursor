# MCP (Model Context Protocol) Configuration

This document describes the MCP server setup, usage, and management for this project.

## Overview

All MCP servers run in **Docker containers** for cross-platform consistency (Windows and WSL). Images are available from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp) or built from custom Dockerfiles.

## Configuration File

MCP servers are configured in `.cursor/mcp.json`. This file contains **no secrets** - all sensitive data is provided via environment variables.

## MCP Servers

All 6 MCP servers are configured and running:

1. **memory** (Neo4j) - Persistent knowledge storage in Neo4j graph database
2. **playwright** - Browser automation and web page interaction
3. **duckduckgo** - External web search for up-to-date information
4. **github** - GitHub repository operations and management
5. **grafana** - Metrics, logs, and dashboards for debugging and performance
6. **shrimp-task-manager** - Task planning, execution, and reflection

### Server Details

#### Memory (Neo4j)
- **Purpose:** Long-term project memory storage
- **Usage:** Store architectural decisions, constraints, and lessons learned. Do NOT store passwords, API keys, or other secrets.
- **Environment variables:** `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE`

#### Playwright
- **Purpose:** Browser automation
- **Usage:** End-to-end testing flows, web scraping (where allowed), UI validation
- **Environment variables:** None required

#### DuckDuckGo
- **Purpose:** External web search
- **Usage:** Search for information not in repo, docs, or memory. Verify current facts and technology updates.
- **Environment variables:** None required

#### GitHub
- **Purpose:** GitHub repository operations
- **Usage:** Inspect and modify remote repositories (only when explicitly asked). Never perform destructive operations without explicit confirmation.
- **Environment variables:** `GITHUB_PERSONAL_ACCESS_TOKEN`

#### Grafana
- **Purpose:** Metrics and dashboards
- **Usage:** Query metrics and logs for debugging, performance investigations. All operations are read-only unless explicitly approved.
- **Environment variables:** `GRAFANA_URL`, `GRAFANA_API_KEY`

#### Shrimp Task Manager
- **Purpose:** Task planning and execution
- **Usage:** Create task plans for complex work, track execution and reflect on results, store project rules and conventions
- **Environment variables:** `DATA_DIR`, `TEMPLATES_USE`, `ENABLE_GUI`, plus `MCP_PROMPT_*` variables for customization

## Execution Model

All MCP servers use Docker containers with this pattern:

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

**Benefits:**
- Consistent execution across Windows and WSL
- Isolation - each server runs in its own container
- Easy updates - pull latest images with `docker pull`
- Security - all secrets via environment variables

## Environment Variables

**IMPORTANT:** All MCP environment variables must be set in **WSL** (where Docker runs), not in Windows.

**Required variables:**
- `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE` - For memory server
- `GITHUB_PERSONAL_ACCESS_TOKEN` - For GitHub server
- `GRAFANA_URL`, `GRAFANA_API_KEY` - For Grafana server

See [configuration.md](configuration.md) for detailed setup instructions.

## Testing

Test all MCP servers with:
- **Windows**: `.\scripts\test-mcp-servers.ps1`
- **WSL**: `./scripts/test-mcp-servers.sh`

This verifies Docker availability, image presence, security (no hardcoded secrets), and environment variable configuration.

## Docker Management

For Docker-specific operations (building images, pulling updates, troubleshooting), see [mcp-docker.md](mcp-docker.md).

## Security

- **No secrets in `mcp.json`** - all sensitive data via environment variables
- **Secrets in `env.local`** - committed to Git (rotate regularly)
- **KeePass integration** - recommended for production secret management

## Version Management

| MCP Server | Current Version | Update Strategy |
|------------|----------------|----------------|
| memory | `mcp/memory` (Docker) | `docker pull mcp/memory` |
| playwright | `mcp/playwright` (Docker) | `docker pull mcp/playwright` |
| duckduckgo | `mcp/duckduckgo` (Docker) | `docker pull mcp/duckduckgo` |
| github | `mcp/github` (Docker) | `docker pull mcp/github` |
| grafana | `mcp/grafana` (Docker) | `docker pull mcp/grafana` |
| shrimp-task-manager | `mcp/shrimp` (Docker, built from GitHub) | Rebuild from source |

**Update Process:**
1. Pull latest images: `docker pull mcp/server-name`
2. For custom images: `.\scripts\build-mcp-images.ps1 --all`
3. Restart Cursor to apply changes

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## References

- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Docker Configuration Guide](mcp-docker.md) - Docker-specific operations
