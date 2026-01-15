# Dockerfile for GitHub MCP Server
# This image wraps github-mcp-custom for Docker execution

FROM node:20-alpine

# Install the MCP server globally
RUN npm install -g github-mcp-custom@1.0.20

# Set environment variable (will be overridden by -e flag)
ENV GITHUB_PERSONAL_ACCESS_TOKEN=""

# Run the MCP server
ENTRYPOINT ["npx", "-y", "github-mcp-custom@1.0.20", "stdio"]
