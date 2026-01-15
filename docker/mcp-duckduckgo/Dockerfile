# Dockerfile for DuckDuckGo MCP Server
# This image wraps duckduckgo-mcp-server for Docker execution

FROM python:3.11-alpine

# Install uvx and duckduckgo-mcp-server
RUN pip install --no-cache-dir uvx duckduckgo-mcp-server

# Run the MCP server
ENTRYPOINT ["uvx", "duckduckgo-mcp-server"]
