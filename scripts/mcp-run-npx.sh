#!/bin/bash
# Wrapper script for npx-based MCP servers
# Usage: mcp-run-npx.sh <package> [args...]

PACKAGE="$1"
shift
EXTRA_ARGS="$@"

npx "$PACKAGE" $EXTRA_ARGS
