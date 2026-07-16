# Dockerfile for DuckDuckGo MCP Server
# Aligns with the Docker Hub MCP Catalog image (mcp/duckduckgo):
# Entrypoint is null; CMD starts the stdio server. Do not pass extra
# docker-run args (e.g. --transport=stdio) — they replace CMD and break startup.

FROM python:3.11-alpine

WORKDIR /app

RUN pip install --no-cache-dir duckduckgo-mcp-server

CMD ["python", "-m", "duckduckgo_mcp_server.server"]
