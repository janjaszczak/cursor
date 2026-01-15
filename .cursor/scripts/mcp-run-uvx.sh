#!/bin/bash
# Wrapper script for uvx-based MCP servers
# Usage: mcp-run-uvx.sh <package> [args...]

PACKAGE="$1"
shift
EXTRA_ARGS="$@"

uvx "$PACKAGE" $EXTRA_ARGS
