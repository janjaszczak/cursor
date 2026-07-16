#!/usr/bin/env bash
# Start SearXNG on mcp-network so the "searxng" MCP server (isokoliuk/mcp-searxng)
# can reach it at http://searxng:8080 without host.docker.internal.
# Mirrors scripts/start-neo4j-mcp.sh for the memory MCP server.
#
# Usage: ./scripts/start-searxng.sh
#
# SEARXNG_SECRET is auto-generated if not already set (low-sensitivity CSRF
# token, safe to regenerate — this instance is never exposed to the internet).
# To keep sessions stable across restarts, persist the generated value to
# .env as SEARXNG_SECRET=... after the first run.

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
settings_dir="$(cd "$script_dir/../docker/mcp-searxng" && pwd)"

if [ -z "${SEARXNG_SECRET}" ]; then
  if command -v openssl >/dev/null 2>&1; then
    SEARXNG_SECRET="$(openssl rand -hex 32)"
  else
    SEARXNG_SECRET="$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  fi
  echo "SEARXNG_SECRET not set — generated a random one for this run."
  echo "To keep search sessions stable across restarts, add this to .env:"
  echo "  SEARXNG_SECRET=${SEARXNG_SECRET}"
fi

docker network create mcp-network 2>/dev/null || true

if docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
  docker start searxng
  echo "SearXNG container 'searxng' started. Reachable at http://searxng:8080 (mcp-network) / http://localhost:8080 (host)."
else
  docker run -d --name searxng --network mcp-network \
    -p 127.0.0.1:8080:8080 \
    -v "${settings_dir}/settings.yml:/etc/searxng/settings.yml:ro" \
    -e "SEARXNG_SECRET=${SEARXNG_SECRET}" \
    -e "SEARXNG_BASE_URL=http://localhost:8080/" \
    searxng/searxng:latest
  echo "SearXNG started on mcp-network. Reachable at http://searxng:8080 (mcp-network) / http://localhost:8080 (host)."
fi

echo "Verify with: curl -s \"http://localhost:8080/search?q=test&format=json\" | head -c 200"
echo "Restart Cursor so it picks up the 'searxng' MCP entry from mcp.json."
