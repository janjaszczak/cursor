#!/usr/bin/env bash
# Start Neo4j on mcp-network so the MCP memory server can connect (bolt://neo4j:7687).
# Requires NEO4J_PASSWORD in environment (e.g. from .env or after sourcing setup-env-vars.sh).
# Prefer automatic start via scripts/mcp-run-memory.py (Cursor memory MCP entry).

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${NEO4J_PASSWORD}" ]; then
  echo "NEO4J_PASSWORD is not set. Source env or run: export NEO4J_PASSWORD=your_password" >&2
  exit 1
fi

docker network create mcp-network 2>/dev/null || true

if docker ps -a --format '{{.Names}}' | grep -qx 'neo4j'; then
  docker start neo4j >/dev/null
  docker update --restart unless-stopped neo4j >/dev/null
  echo "Neo4j container 'neo4j' started (restart=unless-stopped)."
else
  docker run -d --name neo4j \
    --restart unless-stopped \
    --network mcp-network \
    -p 7687:7687 \
    -e "NEO4J_AUTH=neo4j/${NEO4J_PASSWORD}" \
    neo4j:latest
  echo "Neo4j created on mcp-network (restart=unless-stopped)."
fi

echo "Waiting for Neo4j readiness..."
deadline=$((SECONDS + 90))
while [ "$SECONDS" -lt "$deadline" ]; do
  if docker exec neo4j bash -c 'wget -qO- http://127.0.0.1:7474 >/dev/null 2>&1 || curl -sf http://127.0.0.1:7474 >/dev/null 2>&1'; then
    echo "Neo4j is ready at bolt://neo4j:7687 (mcp-network) / bolt://localhost:7687 (host)."
    echo "Memory MCP uses NEO4J_URL=bolt://neo4j:7687 via ${script_dir}/mcp-run-memory.py"
    exit 0
  fi
  sleep 2
done

echo "ERROR: Neo4j did not become ready within 90s" >&2
exit 1
