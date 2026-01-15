# MCP (Model Context Protocol) Configuration

This document describes the MCP server setup, usage, Docker management, and troubleshooting for this project.

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
- **Docker image:** `mcp/memory`

#### Playwright
- **Purpose:** Browser automation
- **Usage:** End-to-end testing flows, web scraping (where allowed), UI validation
- **Environment variables:** None required
- **Docker image:** `mcp/playwright`

#### DuckDuckGo
- **Purpose:** External web search
- **Usage:** Search for information not in repo, docs, or memory. Verify current facts and technology updates.
- **Environment variables:** None required
- **Docker image:** `mcp/duckduckgo`

#### GitHub
- **Purpose:** GitHub repository operations
- **Usage:** Inspect and modify remote repositories (only when explicitly asked). Never perform destructive operations without explicit confirmation.
- **Environment variables:** `GITHUB_PERSONAL_ACCESS_TOKEN`
- **Docker image:** `mcp/github`

#### Grafana
- **Purpose:** Metrics and dashboards
- **Usage:** Query metrics and logs for debugging, performance investigations. All operations are read-only unless explicitly approved.
- **Environment variables:** `GRAFANA_URL`, `GRAFANA_API_KEY`
- **Docker image:** `mcp/grafana`

#### Shrimp Task Manager
- **Purpose:** Task planning and execution
- **Usage:** Create task plans for complex work, track execution and reflect on results, store project rules and conventions
- **Environment variables:** `DATA_DIR`, `TEMPLATES_USE`, `ENABLE_GUI`, plus `MCP_PROMPT_*` variables for customization
- **Docker image:** `mcp/shrimp` (built from `docker/mcp-shrimp/Dockerfile`)

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

## Docker Images

### Official Images (Docker Hub MCP Catalog)

- **mcp/grafana** - Grafana MCP server
- **mcp/playwright** - Playwright browser automation
- **mcp/duckduckgo** - DuckDuckGo web search
- **mcp/memory** - Neo4j Memory MCP server
- **mcp/github** - GitHub MCP server

### Custom Images

Custom Dockerfiles are available in `docker/mcp-*/`:
- `docker/mcp-memory/` - Neo4j Memory MCP Server (if not available on Docker Hub)
- `docker/mcp-duckduckgo/` - DuckDuckGo MCP Server (if not available on Docker Hub)
- `docker/mcp-github/` - GitHub MCP Server
- `docker/mcp-shrimp/` - Shrimp Task Manager (clones and builds from GitHub)

## Managing Docker Images

### Check Available Images

```bash
# Windows
.\scripts\check-docker-images.ps1

# WSL
./scripts/check-docker-images.sh
```

This script checks if images exist locally, verifies availability on Docker Hub, and reports which images need to be built.

### Pull Latest Images

```bash
docker pull mcp/grafana
docker pull mcp/playwright
docker pull mcp/duckduckgo
docker pull mcp/memory
docker pull mcp/github
```

### Build Custom Images

For servers without official images, build from Dockerfiles:

```bash
# Windows
.\scripts\build-mcp-images.ps1 --all

# WSL
./scripts/build-mcp-images.sh --all
```

Or build individual images:
```bash
.\scripts\build-mcp-images.ps1 --memory
.\scripts\build-mcp-images.ps1 --duckduckgo
.\scripts\build-mcp-images.ps1 --github
.\scripts\build-mcp-images.ps1 --shrimp
```

## Docker Volumes

### Shrimp Task Manager Data

Shrimp uses a Docker named volume for data persistence:

```bash
# Create volume (one-time setup)
docker volume create shrimp_data

# Backup data
docker run --rm -v shrimp_data:/data -v $(pwd):/backup alpine tar czf /backup/shrimp_backup.tar.gz -C /data .

# Restore data
docker run --rm -v shrimp_data:/data -v $(pwd):/backup alpine tar xzf /backup/shrimp_backup.tar.gz -C /data
```

**Advantages:**
- Works identically in Windows and WSL
- Data persists independently of host filesystem
- No path synchronization issues

## Testing

Test all MCP servers with:
- **Windows**: `.\scripts\test-mcp-servers.ps1`
- **WSL**: `./scripts/test-mcp-servers.sh`

Tests verify:
- Docker availability
- Image presence (local or Docker Hub)
- Security (no hardcoded secrets)
- Environment variable configuration
- Server health

Results are saved to `test-results/mcp-test-YYYYMMDD-HHMMSS.json` and HTML reports.

## Troubleshooting

### Image Not Found

If an image is not found:
1. Check if it exists on Docker Hub: `docker manifest inspect mcp/image-name`
2. Pull the image: `docker pull mcp/image-name`
3. If not available, build from Dockerfile: `.\scripts\build-mcp-images.ps1 --image-name`

### Environment Variables Not Working

1. Verify variables are set in WSL: `echo $VAR_NAME`
2. Check `mcp.json` uses `-e VAR_NAME` (not hardcoded values)
3. Restart Cursor after setting variables

### Docker Not Available

1. Ensure Docker Desktop is running (Windows)
2. Verify Docker is accessible: `docker --version`
3. Check WSL integration in Docker Desktop settings

### MCP Servers Not Starting

1. Verify Docker is running: `docker --version`
2. Verify environment variables are set (check with `echo $VAR_NAME` in WSL)
3. Check Docker images exist: `docker images | grep mcp`
4. Run test script: `.\scripts\test-mcp-servers.ps1`

### Volume Mount Issues

If using volume mounts (not recommended for cross-platform):
- **Windows:** Use `\\wsl.localhost\Ubuntu\...` paths
- **WSL:** Use `/home/...` paths
- **Better:** Use Docker named volumes (see Shrimp example above)

## Security

- **No secrets in `mcp.json`** - all sensitive data via environment variables
- **Secrets in `env.local`** - committed to Git (rotate regularly)
- **KeePass integration** - recommended for production secret management
- **Never hardcode secrets** in `mcp.json`
- **Use environment variables** for all sensitive data (`-e VAR_NAME`)
- **Set variables in WSL** where Docker runs
- **Rotate secrets regularly**

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

## Rollback Plan

If you need to revert to the previous configuration (WSL-based execution):

### Quick Rollback

1. **Restore from backup:**
   ```bash
   # Windows
   Copy-Item "$env:USERPROFILE\.cursor\mcp.json.backup.*" "$env:USERPROFILE\.cursor\mcp.json" -Force
   
   # WSL
   cp ~/.cursor/mcp.json.backup.* ~/.cursor/mcp.json
   ```

2. **Restore wrapper scripts (if needed):**
   ```bash
   # Windows
   Copy-Item "$env:USERPROFILE\.cursor\scripts\archive\mcp-run-*.ps1" "$env:USERPROFILE\.cursor\scripts\" -Force
   
   # WSL
   cp ~/.cursor/scripts/archive/mcp-run-*.sh ~/.cursor/scripts/
   ```

3. **Restart Cursor** to apply changes

### Full Rollback

1. Restore `mcp.json` from Git history:
   ```bash
   git checkout HEAD~1 -- mcp.json
   ```

2. Verify configuration:
   ```bash
   .\scripts\verify-config.ps1
   ```

3. Test MCP servers in Cursor

### Troubleshooting Rollback

- **Docker images still present:** Safe to keep, won't interfere
- **Volume mounts:** Docker volumes (`shrimp_data`) persist independently
- **Environment variables:** No changes needed, same variables work for both approaches

## References

- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
