#!/bin/bash
# Script to analyze MCP server usage and identify unused servers
# Checks which MCP servers are actually being used
#
# Usage: ./scripts/analyze-mcp-usage.sh

set -e

echo ""
echo "=== Analyzing MCP Server Usage ==="
echo ""

mcp_config_path="$HOME/.cursor/mcp.json"

if [ ! -f "$mcp_config_path" ]; then
    echo "Error: mcp.json not found at: $mcp_config_path" >&2
    exit 1
fi

# Extract server names from mcp.json
servers=$(python3 << 'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        config = json.load(f)
    
    servers = list(config.get('mcpServers', {}).keys())
    for server in servers:
        print(server)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
    "$mcp_config_path")

if [ $? -ne 0 ]; then
    echo "Error: Failed to parse mcp.json" >&2
    exit 1
fi

echo "Configured MCP servers:"
echo "$servers" | while read -r server; do
    if [ -n "$server" ]; then
        echo "  - $server"
    fi
done

echo ""
echo "Analysis:"
echo "  This script identifies configured servers."
echo "  To determine actual usage, check:"
echo "    1. Cursor logs (if available)"
echo "    2. Manual testing of each server"
echo "    3. Project documentation for server purposes"

# Check for servers using wsl.exe (candidates for migration)
echo ""
echo "Servers using wsl.exe (candidates for Docker migration):"
python3 << 'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        config = json.load(f)
    
    for name, server in config.get('mcpServers', {}).items():
        command = server.get('command', '')
        if command == 'wsl.exe':
            print(f"  - {name}")
        elif command == 'docker':
            print(f"  [OK] {name} uses Docker")
except Exception as e:
    pass
PYEOF
    "$mcp_config_path"

# Generate report
output_dir="$HOME/.cursor/test-results"
mkdir -p "$output_dir"
output_path="$output_dir/mcp-usage-analysis-$(date +%Y%m%d-%H%M%S).json"

python3 << 'PYEOF'
import json
import sys
from datetime import datetime

try:
    with open(sys.argv[1], 'r') as f:
        config = json.load(f)
    
    servers = list(config.get('mcpServers', {}).keys())
    
    report = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "configuredServers": servers,
        "serverCount": len(servers),
        "recommendations": [
            "Review each server's purpose and usage",
            "Test each server to verify it's needed",
            "Consider removing unused servers to simplify configuration"
        ]
    }
    
    with open(sys.argv[2], 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\nReport saved to: {sys.argv[2]}")
except Exception as e:
    print(f"Error generating report: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
    "$mcp_config_path" "$output_path"

exit 0
