# MCP Docker Configuration Guide

This document describes Docker-specific operations for MCP servers: building images, managing containers, and troubleshooting.

## Overview

All MCP servers run in Docker containers. Most images are available from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp). Custom Dockerfiles are available for servers without official images.

## Available Docker Images

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

### Volume Mount Issues

If using volume mounts (not recommended for cross-platform):
- **Windows:** Use `\\wsl.localhost\Ubuntu\...` paths
- **WSL:** Use `/home/...` paths
- **Better:** Use Docker named volumes (see Shrimp example above)

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

## Security Best Practices

1. **Never hardcode secrets** in `mcp.json`
2. **Use environment variables** for all sensitive data (`-e VAR_NAME`)
3. **Set variables in WSL** where Docker runs
4. **Rotate secrets regularly**
5. **Use `.env.local`** for local development (not committed to Git)

## References

- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
- [Main MCP Guide](mcp.md) - Server details and usage
