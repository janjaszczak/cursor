#!/bin/bash
# Wrapper script for node-based MCP servers
# Usage: mcp-run-node.sh <script-path> [args...]

SCRIPT_PATH="$1"
shift
EXTRA_ARGS="$@"

node "$SCRIPT_PATH" $EXTRA_ARGS
