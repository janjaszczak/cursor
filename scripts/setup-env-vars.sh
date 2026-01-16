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

# Load environment variables from .env file
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠ .env file not found at: $ENV_FILE"
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
POSTMAN_API_KEY=CHANGE_ME
ENVEOF
    echo "✓ Template created. Please edit .env and run script again."
    exit 0
fi

echo "Loading variables from .env..."
source "$ENV_FILE"

# For system-wide, we'll use /etc/environment format
# For user, we'll use export statements in ~/.profile

# CURSOR_CONFIG_DIR
export CURSOR_CONFIG_DIR="$HOME/.cursor"
echo "✓ CURSOR_CONFIG_DIR set to: $CURSOR_CONFIG_DIR"

# MCP Environment Variables are loaded from .env above
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
if [ "$POSTMAN_API_KEY" = "CHANGE_ME" ] || [ -z "$POSTMAN_API_KEY" ]; then
    echo "⚠ POSTMAN_API_KEY is not set (CHANGE_ME or empty)"
fi

echo ""
echo "Environment variables loaded from .env."
echo "Variables marked with CHANGE_ME need to be set in .env file."

# Write to appropriate location
if [ "$EUID" -eq 0 ]; then
    # System-wide: append to /etc/environment (requires sudo)
    {
        echo ""
        echo "# Cursor/MCP environment variables (from .env)"
        echo "CURSOR_CONFIG_DIR=\"$CURSOR_CONFIG_DIR\""
        echo "NEO4J_URI=\"$NEO4J_URI\""
        echo "NEO4J_USERNAME=\"$NEO4J_USERNAME\""
        [ -n "$NEO4J_PASSWORD" ] && [ "$NEO4J_PASSWORD" != "CHANGE_ME" ] && echo "NEO4J_PASSWORD=\"$NEO4J_PASSWORD\""
        echo "NEO4J_DATABASE=\"$NEO4J_DATABASE\""
        [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "CHANGE_ME" ] && echo "GITHUB_PERSONAL_ACCESS_TOKEN=\"$GITHUB_PERSONAL_ACCESS_TOKEN\""
        echo "GRAFANA_URL=\"$GRAFANA_URL\""
        [ -n "$GRAFANA_API_KEY" ] && [ "$GRAFANA_API_KEY" != "CHANGE_ME" ] && echo "GRAFANA_API_KEY=\"$GRAFANA_API_KEY\""
        [ -n "$POSTMAN_API_KEY" ] && [ "$POSTMAN_API_KEY" != "CHANGE_ME" ] && echo "POSTMAN_API_KEY=\"$POSTMAN_API_KEY\""
    } >> /etc/environment
    echo "✓ Appended to /etc/environment (system-wide)"
else
    # User: update both ~/.profile and ~/.bashrc
    # In WSL, interactive shells load ~/.bashrc, not ~/.profile
    # So we need to set variables in both places
    
    # Function to remove old Cursor/MCP section from a file
    remove_old_section() {
        local file_path="$1"
        if [ ! -f "$file_path" ]; then
            return
        fi
        
        python3 << PYEOF || true
import sys
import os
import re

file_path = "$file_path"
try:
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    # Find start of Cursor/MCP section
    start_idx = None
    for i, line in enumerate(lines):
        if re.match(r'^# Cursor/MCP environment variables', line):
            start_idx = i
            break
    
    if start_idx is not None:
        # Find end: next empty line after POSTMAN_API_KEY or end of file
        end_idx = len(lines)
        found_postman = False
        for i in range(start_idx + 1, len(lines)):
            if re.match(r'^export POSTMAN_API_KEY', lines[i]):
                found_postman = True
            if found_postman and (lines[i].strip() == '' or i == len(lines) - 1):
                end_idx = i + 1
                break
        
        # Remove the section
        new_lines = lines[:start_idx] + lines[end_idx:]
        with open(file_path, 'w') as f:
            f.writelines(new_lines)
except Exception as e:
    sys.stderr.write(f"Warning: Could not remove old section from {file_path}: {e}\n")
PYEOF
    }
    
    # Update ~/.profile (for login shells)
    if [ -f ~/.profile ]; then
        BACKUP_FILE="$HOME/.profile.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.profile "$BACKUP_FILE" 2>/dev/null || true
        echo "✓ Created backup: $BACKUP_FILE"
        remove_old_section ~/.profile
    fi
    
    # Update ~/.bashrc (for interactive shells - used in WSL)
    if [ -f ~/.bashrc ]; then
        BACKUP_FILE="$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp ~/.bashrc "$BACKUP_FILE" 2>/dev/null || true
        remove_old_section ~/.bashrc
    fi
    
    # Function to append environment variables to a file
    append_env_vars() {
        local file_path="$1"
        {
            echo ""
            echo "# Cursor/MCP environment variables (from .env) - $(date '+%Y-%m-%d %H:%M:%S')"
            echo "export CURSOR_CONFIG_DIR=\"$CURSOR_CONFIG_DIR\""
            echo "export NEO4J_URI=\"$NEO4J_URI\""
            echo "export NEO4J_USERNAME=\"$NEO4J_USERNAME\""
            [ -n "$NEO4J_PASSWORD" ] && [ "$NEO4J_PASSWORD" != "CHANGE_ME" ] && echo "export NEO4J_PASSWORD=\"$NEO4J_PASSWORD\""
            echo "export NEO4J_DATABASE=\"$NEO4J_DATABASE\""
            [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "CHANGE_ME" ] && echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GITHUB_PERSONAL_ACCESS_TOKEN\""
            echo "export GRAFANA_URL=\"$GRAFANA_URL\""
            [ -n "$GRAFANA_API_KEY" ] && [ "$GRAFANA_API_KEY" != "CHANGE_ME" ] && echo "export GRAFANA_API_KEY=\"$GRAFANA_API_KEY\""
            [ -n "$POSTMAN_API_KEY" ] && [ "$POSTMAN_API_KEY" != "CHANGE_ME" ] && echo "export POSTMAN_API_KEY=\"$POSTMAN_API_KEY\""
        } >> "$file_path"
    }
    
    # Append to ~/.profile (for login shells)
    append_env_vars ~/.profile
    echo "✓ Updated ~/.profile with variables from .env"
    
    # Append to ~/.bashrc (for interactive shells - used in WSL)
    append_env_vars ~/.bashrc
    echo "✓ Updated ~/.bashrc with variables from .env"
fi
