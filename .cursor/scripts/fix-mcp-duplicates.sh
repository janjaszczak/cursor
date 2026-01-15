#!/bin/bash
# Script to fix MCP duplicates and ensure single source of truth in WSL
# Run with: ./scripts/fix-mcp-duplicates.sh

set -e

echo "=== Fixing MCP Configuration Duplicates ==="
echo ""

REPO_CONFIG_PATH="/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/cursor/.cursor/mcp.json"
GLOBAL_CONFIG_PATH="$HOME/.cursor/mcp.json"

# Ensure CURSOR_CONFIG_DIR is set in ~/.profile
CURSOR_CONFIG_DIR="/mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/cursor/.cursor"

if ! grep -q "CURSOR_CONFIG_DIR" ~/.profile 2>/dev/null; then
    echo "export CURSOR_CONFIG_DIR=\"$CURSOR_CONFIG_DIR\"" >> ~/.profile
    echo "✓ Added CURSOR_CONFIG_DIR to ~/.profile" 
    echo "  Run: source ~/.profile (or restart terminal)"
else
    echo "✓ CURSOR_CONFIG_DIR already in ~/.profile"
fi

# Minimize global config
if [ -f "$GLOBAL_CONFIG_PATH" ]; then
    BACKUP_PATH="${GLOBAL_CONFIG_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$GLOBAL_CONFIG_PATH" "$BACKUP_PATH"
    echo "✓ Backed up global config to: $BACKUP_PATH"
    
    # Create minimal config
    echo '{"mcpServers": {}}' > "$GLOBAL_CONFIG_PATH"
    echo "✓ Minimized global mcp.json (empty mcpServers)"
else
    echo "⚠ Global mcp.json not found (this is OK)"
fi

# Verify repo config exists
if [ -f "$REPO_CONFIG_PATH" ]; then
    MCP_COUNT=$(python3 << 'PYEOF'
import json
import sys
try:
    with open(sys.argv[1], 'r') as f:
        data = json.load(f)
    mcp_servers = data.get('mcpServers', {})
    print(len(mcp_servers))
    print(','.join(mcp_servers.keys()))
except Exception as e:
    print(f"0\nError: {e}")
PYEOF
    "$REPO_CONFIG_PATH")
    
    MCP_COUNT_ONLY=$(echo "$MCP_COUNT" | head -1)
    MCP_NAMES=$(echo "$MCP_COUNT" | tail -1)
    
    if [ "$MCP_COUNT_ONLY" -gt 0 ]; then
        echo "✓ Repo mcp.json found with $MCP_COUNT_ONLY MCP servers"
        echo "  MCPs: $MCP_NAMES"
    else
        echo "✗ Repo mcp.json has errors: $MCP_NAMES"
        exit 1
    fi
else
    echo "✗ Repo mcp.json not found!"
    exit 1
fi

echo ""
echo "=== Summary ==="
echo "1. CURSOR_CONFIG_DIR added to ~/.profile"
echo "2. Global mcp.json minimized (backed up)"
echo "3. Repo mcp.json is the single source of truth"
echo ""
echo "Next steps:"
echo "1. Run: source ~/.profile (or restart terminal)"
echo "2. Restart Cursor completely"
echo "3. Verify MCP servers are loaded from repo config"
