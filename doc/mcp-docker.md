# MCP Docker Configuration Guide

This document describes how to use Docker-based MCP servers and manage Docker images.

## Overview

Most MCP servers run in Docker containers for consistency, isolation, and ease of management. Images are available from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp).

## Available Docker Images

### Official Images (Docker Hub MCP Catalog)

- **mcp/grafana** - Grafana MCP server
- **mcp/playwright** - Playwright browser automation
- **mcp/duckduckgo** - DuckDuckGo web search
- **mcp/memory** - Neo4j Memory MCP server

### Custom Images

Custom Dockerfiles are available for servers without official images:
- `docker/mcp-memory/` - Neo4j Memory MCP Server
- `docker/mcp-duckduckgo/` - DuckDuckGo MCP Server

## Configuration

### Basic Docker Configuration

All Docker-based MCP servers use this pattern in `mcp.json`:

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

### Environment Variables

**CRITICAL:** All secrets must be passed via environment variables (`-e VAR_NAME`), never hardcoded in `mcp.json`.

Set environment variables in WSL (where Docker runs):
```bash
export NEO4J_URI="neo4j://localhost:7687"
export NEO4J_USERNAME="neo4j"
export NEO4J_PASSWORD="your_password"
export GRAFANA_URL="http://localhost:3001"
export GRAFANA_API_KEY="your_key"
```

## Managing Docker Images

### Check Available Images

```bash
# Windows
.\scripts\check-docker-images.ps1

# WSL
./scripts/check-docker-images.sh
```

This script:
- Checks if images exist locally
- Verifies availability on Docker Hub
- Reports which images need to be built

### Pull Latest Images

```bash
docker pull mcp/grafana
docker pull mcp/playwright
docker pull mcp/duckduckgo
docker pull mcp/memory
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
```

## Testing

### Run Tests

```bash
# Windows
.\scripts\test-mcp-servers.ps1

# WSL
./scripts/test-mcp-servers.sh
```

Tests verify:
- Docker availability
- Image presence (local or Docker Hub)
- Security (no hardcoded secrets)
- Environment variable configuration
- Server health

Results are saved to `test-results/mcp-test-YYYYMMDD-HHMMSS.json`.

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

## Security Best Practices

1. **Never hardcode secrets** in `mcp.json`
2. **Use environment variables** for all sensitive data
3. **Set variables in WSL** where Docker runs
4. **Rotate secrets regularly**
5. **Use `.env.local`** for local development (not committed to Git)

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

## Migration Status

- ✅ **migrated to Docker:** memory, playwright, duckduckgo, grafana, github, shrimp-task-manager
- ✅ **All servers:** Now using Docker for cross-platform consistency

## References

- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
