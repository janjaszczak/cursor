#!/bin/bash
# Script to synchronize mcp.json between Windows and WSL
# Ensures both configurations are identical
#
# Usage: ./scripts/sync-mcp-config.sh [--direction=windows-to-wsl|wsl-to-windows|both]

set -e

direction="both"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --direction=*)
            direction="${arg#*=}"
            ;;
    esac
done

windows_config="$HOME/.cursor/mcp.json"
wsl_config="$HOME/.cursor/mcp.json"

# For WSL, we need to check if we're accessing Windows path
if [ -n "$WSL_DISTRO_NAME" ]; then
    # We're in WSL, use WSL path
    wsl_config="$HOME/.cursor/mcp.json"
    # Windows path would be /mnt/c/Users/janja/.cursor/mcp.json
    windows_config="/mnt/c/Users/janja/.cursor/mcp.json"
else
    # We're on Windows accessing WSL
    windows_config="$HOME/.cursor/mcp.json"
    wsl_config="//wsl.localhost/Ubuntu/home/janja/.cursor/mcp.json"
fi

echo ""
echo "=== Synchronizing MCP Configuration ==="
echo ""

# Check if files exist
if [ ! -f "$windows_config" ]; then
    echo "Error: Windows config not found: $windows_config" >&2
    exit 1
fi

if [ ! -f "$wsl_config" ]; then
    echo "Error: WSL config not found: $wsl_config" >&2
    exit 1
fi

# Normalize JSON using Python
normalize_json() {
    python3 << 'PYEOF'
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    print(json.dumps(data, indent=2, sort_keys=True))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
    "$1"
}

windows_json=$(normalize_json "$windows_config")
wsl_json=$(normalize_json "$wsl_config")

if [ "$windows_json" = "$wsl_json" ]; then
    echo "✓ Configurations are already synchronized"
    exit 0
fi

echo "Configurations differ. Synchronizing..."

# Create backup
timestamp=$(date +%Y%m%d-%H%M%S)
windows_backup="${windows_config}.backup.${timestamp}"
wsl_backup="${wsl_config}.backup.${timestamp}"

cp "$windows_config" "$windows_backup"
cp "$wsl_config" "$wsl_backup"

echo "  Backups created:"
echo "    Windows: $windows_backup"
echo "    WSL: $wsl_backup"

# Synchronize based on direction
if [ "$direction" = "windows-to-wsl" ] || [ "$direction" = "both" ]; then
    echo ""
    echo "Copying Windows -> WSL..."
    echo "$windows_json" > "$wsl_config"
    echo "  ✓ WSL config updated"
fi

if [ "$direction" = "wsl-to-windows" ] || [ "$direction" = "both" ]; then
    echo ""
    echo "Copying WSL -> Windows..."
    echo "$wsl_json" > "$windows_config"
    echo "  ✓ Windows config updated"
fi

# Verify synchronization
windows_json_new=$(normalize_json "$windows_config")
wsl_json_new=$(normalize_json "$wsl_config")

if [ "$windows_json_new" = "$wsl_json_new" ]; then
    echo ""
    echo "✓ Configurations are now synchronized"
    exit 0
else
    echo "Error: Synchronization failed - configurations still differ" >&2
    exit 1
fi
