# Neo4j Memory MCP Server Docker Image

This Docker image provides the Neo4j Memory MCP server for persistent knowledge storage.

Prefer the official **`mcp/neo4j-memory`** image from the Docker Hub MCP Catalog.
Cursor starts it via `scripts/mcp-run-memory.py` (ensures Neo4j first).

## Environment Variables

- `NEO4J_URL` - Neo4j connection URL (e.g. `bolt://neo4j:7687` on `mcp-network`). **Required by the official image** (not `NEO4J_URI`).
- `NEO4J_USERNAME` - Neo4j username
- `NEO4J_PASSWORD` - Neo4j password
- `NEO4J_DATABASE` - Database name (default: `neo4j`)

## Usage

```bash
# Prefer the launcher (starts Neo4j if needed):
python ~/.cursor/scripts/mcp-run-memory.py

# Or direct docker run once Neo4j is up on mcp-network:
docker run -i --rm --network mcp-network \
  -e NEO4J_URL=bolt://neo4j:7687 \
  -e NEO4J_USERNAME \
  -e NEO4J_PASSWORD \
  -e NEO4J_DATABASE \
  mcp/neo4j-memory
```

## Note

Local Dockerfile under this directory is a fallback only. Production config uses `mcp/neo4j-memory`.
