# DuckDuckGo MCP Server Docker Image

This Docker image provides the DuckDuckGo MCP server for web search capabilities.

## Environment Variables

No environment variables required.

## Usage

```bash
docker build -t mcp/duckduckgo ./docker/mcp-duckduckgo
docker run -i --rm mcp/duckduckgo
```

The image uses `CMD` (not `ENTRYPOINT`). Do **not** append `--transport=stdio` or other
args to `docker run` — Docker would replace `CMD` and the container would fail to start.

## Note

Prefer the official `mcp/duckduckgo` image from the Docker Hub MCP Catalog when available.
This Dockerfile is a local fallback with the same run contract.
