# DuckDuckGo MCP Server Docker Image

This Docker image provides the DuckDuckGo MCP server for web search capabilities.

## Environment Variables

No environment variables required.

## Usage

```bash
docker build -t mcp/duckduckgo ./docker/mcp-duckduckgo
docker run -i --rm mcp/duckduckgo --transport=stdio
```

## Note

This image is used when the official `mcp/duckduckgo` image is not available on Docker Hub or as a local alternative.
