#!/bin/bash
# Setup script for WSL environment variables
# Run with sudo for system-wide variables, or without for user variables
# Usage: sudo ./scripts/setup-env-vars.sh (system-wide) or ./scripts/setup-env-vars.sh (user)

set -e

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then
    SCOPE="system-wide"
    EXPORT_TARGET="/etc/environment"
else
    SCOPE="user"
    EXPORT_TARGET="$HOME/.profile"
fi

echo "Setting up Cursor environment variables ($SCOPE)..."

# Load environment variables from env.local file
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/env.local"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠ env.local file not found at: $ENV_FILE"
    echo "Creating template file..."
    cat > "$ENV_FILE" << 'ENVEOF'
# Local environment variables for Cursor MCP configuration
NEO4J_URI=neo4j://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=CHANGE_ME
NEO4J_DATABASE=neo4j
GITHUB_PERSONAL_ACCESS_TOKEN=CHANGE_ME
GRAFANA_URL=http://localhost:3001
GRAFANA_API_KEY=CHANGE_ME
ENVEOF
    echo "✓ Template created. Please edit env.local and run script again."
    exit 0
fi

echo "Loading variables from env.local..."
source "$ENV_FILE"

# For system-wide, we'll use /etc/environment format
# For user, we'll use export statements in ~/.profile

# CURSOR_CONFIG_DIR
export CURSOR_CONFIG_DIR="/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai/.cursor"
echo "✓ CURSOR_CONFIG_DIR set to: $CURSOR_CONFIG_DIR"

# MCP Environment Variables are loaded from env.local above
# Check if any are still CHANGE_ME
if [ "$NEO4J_PASSWORD" = "CHANGE_ME" ] || [ -z "$NEO4J_PASSWORD" ]; then
    echo "⚠ NEO4J_PASSWORD is not set (CHANGE_ME or empty)"
fi
if [ "$GITHUB_PERSONAL_ACCESS_TOKEN" = "CHANGE_ME" ] || [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "⚠ GITHUB_PERSONAL_ACCESS_TOKEN is not set (CHANGE_ME or empty)"
fi
if [ "$GRAFANA_API_KEY" = "CHANGE_ME" ] || [ -z "$GRAFANA_API_KEY" ]; then
    echo "⚠ GRAFANA_API_KEY is not set (CHANGE_ME or empty)"
fi

echo ""
echo "Environment variables loaded from env.local."
echo "Variables marked with CHANGE_ME need to be set in env.local file."

# Write to appropriate location
if [ "$EUID" -eq 0 ]; then
    # System-wide: append to /etc/environment (requires sudo)
    {
        echo ""
        echo "# Cursor/MCP environment variables (from env.local)"
        echo "CURSOR_CONFIG_DIR=\"$CURSOR_CONFIG_DIR\""
        echo "NEO4J_URI=\"$NEO4J_URI\""
        echo "NEO4J_USERNAME=\"$NEO4J_USERNAME\""
        [ -n "$NEO4J_PASSWORD" ] && [ "$NEO4J_PASSWORD" != "CHANGE_ME" ] && echo "NEO4J_PASSWORD=\"$NEO4J_PASSWORD\""
        echo "NEO4J_DATABASE=\"$NEO4J_DATABASE\""
        [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "CHANGE_ME" ] && echo "GITHUB_PERSONAL_ACCESS_TOKEN=\"$GITHUB_PERSONAL_ACCESS_TOKEN\""
        echo "GRAFANA_URL=\"$GRAFANA_URL\""
        [ -n "$GRAFANA_API_KEY" ] && [ "$GRAFANA_API_KEY" != "CHANGE_ME" ] && echo "GRAFANA_API_KEY=\"$GRAFANA_API_KEY\""
    } >> /etc/environment
    echo "✓ Appended to /etc/environment (system-wide)"
else
    # User: append to ~/.profile
    read -p "Append to ~/.profile? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        {
            echo ""
            echo "# Cursor/MCP environment variables (from env.local)"
            echo "export CURSOR_CONFIG_DIR=\"$CURSOR_CONFIG_DIR\""
            echo "export NEO4J_URI=\"$NEO4J_URI\""
            echo "export NEO4J_USERNAME=\"$NEO4J_USERNAME\""
            [ -n "$NEO4J_PASSWORD" ] && [ "$NEO4J_PASSWORD" != "CHANGE_ME" ] && echo "export NEO4J_PASSWORD=\"$NEO4J_PASSWORD\""
            echo "export NEO4J_DATABASE=\"$NEO4J_DATABASE\""
            [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "CHANGE_ME" ] && echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GITHUB_PERSONAL_ACCESS_TOKEN\""
            echo "export GRAFANA_URL=\"$GRAFANA_URL\""
            [ -n "$GRAFANA_API_KEY" ] && [ "$GRAFANA_API_KEY" != "CHANGE_ME" ] && echo "export GRAFANA_API_KEY=\"$GRAFANA_API_KEY\""
        } >> ~/.profile
        echo "✓ Appended to ~/.profile"
    fi
fi
