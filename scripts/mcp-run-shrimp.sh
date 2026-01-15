#!/bin/bash
# Wrapper script for Shrimp Task Manager
# Usage: mcp-run-shrimp.sh [args...]

SCRIPT_PATH="$HOME/mcp-shrimp-task-manager/dist/index.js"
EXTRA_ARGS="$@"

node "$SCRIPT_PATH" $EXTRA_ARGS
