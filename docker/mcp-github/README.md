# GitHub MCP Server Docker Image

This Docker image provides the GitHub MCP server for repository operations.

## Environment Variables

- `GITHUB_PERSONAL_ACCESS_TOKEN` - GitHub Personal Access Token

## Usage

```bash
docker build -t mcp/github ./docker/mcp-github
docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN \
  mcp/github \
  --transport=stdio
```

## Note

This image is used when the official `mcp/github` image is not available on Docker Hub or as a local alternative.
