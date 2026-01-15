# Dockerfile for Shrimp Task Manager MCP Server
# Clones and builds from GitHub repository
# Based on: https://github.com/cjo4m06/mcp-shrimp-task-manager

FROM node:lts-alpine

# Install git for cloning
RUN apk add --no-cache git

# Set workdir
WORKDIR /app

# Clone the repository
ARG SHRIMP_VERSION=main
RUN git clone --depth 1 --branch ${SHRIMP_VERSION} https://github.com/cjo4m06/mcp-shrimp-task-manager.git /app

# Install dependencies
RUN npm install --ignore-scripts

# Build the TypeScript code
RUN npm run build

# Set environment variables
ENV DATA_DIR="/app/data"
ENV TEMPLATES_USE="en"
ENV ENABLE_GUI="false"
ENV NODE_ENV="production"

# Create data directory
RUN mkdir -p /app/data

# Entrypoint - run the built MCP server
ENTRYPOINT ["node", "/app/dist/index.js"]
