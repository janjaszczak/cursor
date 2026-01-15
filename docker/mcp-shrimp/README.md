# Shrimp Task Manager MCP Server Docker Image

This Docker image provides the Shrimp Task Manager MCP server by cloning and building from the official GitHub repository: https://github.com/cjo4m06/mcp-shrimp-task-manager

## Build

```bash
docker build -t mcp/shrimp ./docker/mcp-shrimp
```

The Dockerfile automatically:
1. Clones the repository from GitHub
2. Installs dependencies
3. Builds the TypeScript code
4. Sets up the MCP server

## Environment Variables

- `DATA_DIR` - Data storage directory (default: `/app/data`)
- `TEMPLATES_USE` - Template language (e.g., `en`)
- `ENABLE_GUI` - GUI enabled (set to `false` for MCP)
- All `MCP_PROMPT_*` variables for prompt customization

## Usage

### Option 1: Docker Named Volume (Recommended)

This approach works seamlessly in both Windows and WSL:

```bash
# Create the volume (one-time setup)
docker volume create shrimp_data

# Run the container
docker run -i --rm \
  -v shrimp_data:/app/data \
  -e DATA_DIR=/app/data \
  -e TEMPLATES_USE=en \
  -e ENABLE_GUI=false \
  mcp/shrimp \
  --transport=stdio
```

**Advantages:**
- Works identically in Windows and WSL
- Data persists independently of host filesystem
- No path synchronization issues
- Easy to backup: `docker run --rm -v shrimp_data:/data -v $(pwd):/backup alpine tar czf /backup/shrimp_data_backup.tar.gz -C /data .`

### Option 2: Local Directory (Alternative)

If you prefer data in your `.cursor` directory:

**Windows:**
```bash
docker run -i --rm \
  -v C:\Users\janja\.cursor\shrimp_data:/app/data \
  -e DATA_DIR=/app/data \
  mcp/shrimp
```

**WSL:**
```bash
docker run -i --rm \
  -v ~/.cursor/shrimp_data:/app/data \
  -e DATA_DIR=/app/data \
  mcp/shrimp
```

**Note:** This requires different paths in `mcp.json` for Windows vs WSL, or using a script to generate the config dynamically.

## Version Control

To use a specific version/branch, rebuild with:

```bash
docker build --build-arg SHRIMP_VERSION=v1.0.21 -t mcp/shrimp:1.0.21 ./docker/mcp-shrimp
```

Default is `main` branch (latest).
