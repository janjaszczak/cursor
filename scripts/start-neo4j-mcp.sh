#!/usr/bin/env bash
# Start Neo4j on mcp-network so the MCP memory server can connect without host.docker.internal.
# Requires NEO4J_PASSWORD in environment (e.g. from .env or after sourcing setup-env-vars.sh).
# After running: set NEO4J_URI=neo4j://neo4j:7687 in .env and restart Cursor.

set -e

if [ -z "${NEO4J_PASSWORD}" ]; then
  echo "NEO4J_PASSWORD is not set. Source env or run: export NEO4J_PASSWORD=your_password" >&2
  exit 1
fi

docker network create mcp-network 2>/dev/null || true

if docker ps -a --format '{{.Names}}' | grep -q '^neo4j$'; then
  docker start neo4j
  echo "Neo4j container 'neo4j' started. Ensure NEO4J_URI=neo4j://neo4j:7687 in .env and restart Cursor."
else
  docker run -d --name neo4j --network mcp-network -p 7687:7687 \
    -e "NEO4J_AUTH=neo4j/${NEO4J_PASSWORD}" \
    neo4j:latest
  echo "Neo4j started on mcp-network. Set NEO4J_URI=neo4j://neo4j:7687 in .env and restart Cursor."
fi
