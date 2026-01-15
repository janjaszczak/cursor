#!/bin/bash
# Universal MCP wrapper script for Windows and WSL/Ubuntu
# Detects environment and runs command appropriately
#
# Usage: mcp-run.sh <command> [args...]
# Example: mcp-run.sh "npx -y @sylweriusz/mcp-neo4j-memory-server"
# Example: mcp-run.sh "docker run -i --rm -e GRAFANA_URL -e GRAFANA_API_KEY mcp/grafana --transport=stdio"

set -e

# Get the command to run (all remaining arguments)
COMMAND="$*"

if [ -z "$COMMAND" ]; then
    echo "Error: No command provided" >&2
    echo "Usage: $0 <command> [args...]" >&2
    exit 1
fi

# Detect if we're running in WSL/Ubuntu or Windows
# Method 1: Check for WSL_DISTRO_NAME (set in WSL)
# Method 2: Check /proc/version for Microsoft (WSL)
# Method 3: Check if wsl.exe exists (Windows calling WSL)
if [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
    # We're in WSL/Ubuntu - run command directly
    exec bash -lc "$COMMAND"
elif command -v wsl.exe >/dev/null 2>&1; then
    # We're on Windows - route through WSL
    exec wsl.exe -- bash -lc "$COMMAND"
else
    # Fallback: assume we're in a Unix-like environment (Ubuntu/Linux)
    exec bash -lc "$COMMAND"
fi
