# Neo4j Memory MCP Server Docker Image

This Docker image provides the Neo4j Memory MCP server for persistent knowledge storage.

## Environment Variables

- `NEO4J_URI` - Neo4j connection URI (e.g., `neo4j://localhost:7687`)
- `NEO4J_USERNAME` - Neo4j username
- `NEO4J_PASSWORD` - Neo4j password
- `NEO4J_DATABASE` - Database name (default: `neo4j`)

## Usage

```bash
docker build -t mcp/memory ./docker/mcp-memory
docker run -i --rm \
  -e NEO4J_URI \
  -e NEO4J_USERNAME \
  -e NEO4J_PASSWORD \
  -e NEO4J_DATABASE \
  mcp/memory \
  --transport=stdio
```

## Note

This image is used when the official `mcp/memory` image is not available on Docker Hub.
