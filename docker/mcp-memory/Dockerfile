# Dockerfile for Neo4j Memory MCP Server
# This image wraps @sylweriusz/mcp-neo4j-memory-server for Docker execution

FROM node:20-alpine

# Install the MCP server globally
RUN npm install -g @sylweriusz/mcp-neo4j-memory-server

# Set environment variables (will be overridden by -e flags)
ENV NEO4J_URI=""
ENV NEO4J_USERNAME=""
ENV NEO4J_PASSWORD=""
ENV NEO4J_DATABASE="neo4j"

# Run the MCP server
ENTRYPOINT ["npx", "-y", "@sylweriusz/mcp-neo4j-memory-server"]
