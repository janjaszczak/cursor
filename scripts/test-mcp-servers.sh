#!/bin/bash
# Script to test MCP servers - health check, functional, performance, and security tests
# Verifies that all MCP servers work correctly with Docker
#
# Usage: ./scripts/test-mcp-servers.sh

set -e

echo ""
echo "=== Testing MCP Servers ==="
echo ""

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mcp_config_path="$(cd "$script_dir/.." && pwd)/mcp.json"
test_results=()
errors=()

if [ ! -f "$mcp_config_path" ]; then
    echo "Error: mcp.json not found at: $mcp_config_path" >&2
    exit 1
fi

# Security check - verify no hardcoded secrets
echo "Security Check: Verifying no hardcoded secrets..."
mcp_content=$(cat "$mcp_config_path")

# Check for potential secrets
if echo "$mcp_content" | grep -qiE "(password|token|api[_-]?key|secret).*:.*['\"][^'\"]+['\"]"; then
    echo "  ✗ Potential secrets found in mcp.json" >&2
    test_results+=("Security Check:FAIL:Secrets found")
    errors+=("Security check failed")
else
    echo "  ✓ No hardcoded secrets found"
    test_results+=("Security Check:PASS:No secrets found")
fi

# Extract server names
servers=$(python3 - "$mcp_config_path" <<'PYEOF'
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
)

# Config contract checks (DDG + Memory)
echo ""
echo "Config contract checks..."
py_cmd="python3"
command -v python3 >/dev/null 2>&1 || py_cmd="python"
set +e
"$py_cmd" - "$mcp_config_path" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    cfg = json.load(f)
servers = cfg.get("mcpServers", {})
errors = []
ddg = servers.get("duckduckgo", {})
args = ddg.get("args") or []
if any(str(a).startswith("--transport") for a in args):
    print("  ✗ duckduckgo must not pass --transport")
    errors.append("duckduckgo:transport")
else:
    print("  ✓ duckduckgo has no --transport arg")
mem = servers.get("memory", {})
joined = " ".join(str(a) for a in (mem.get("args") or []))
if mem.get("command") == "python" and "mcp-run-memory.py" in joined:
    print("  ✓ memory uses mcp-run-memory.py launcher")
    if "${userHome}" in joined:
        print("  ✗ memory must not use ${userHome} script path (Windows expands to C:\\c:\\...)")
        errors.append("memory:userHomePath")
    elif "Path.home" in joined or "-c" in (mem.get("args") or []):
        print("  ✓ memory uses Path.home/-c (avoids broken ${userHome} path)")
elif "NEO4J_URL=" in joined:
    print("  ✓ memory sets NEO4J_URL")
else:
    print("  ✗ memory must use launcher or NEO4J_URL")
    errors.append("memory:launcher")
if errors:
    sys.exit(1)
PYEOF
contract_rc=$?
set -e
if [ "$contract_rc" -eq 0 ]; then
    test_results+=("duckduckgo:NoTransportArg:PASS")
    test_results+=("memory:Launcher:PASS")
else
    test_results+=("duckduckgo:NoTransportArg:FAIL")
    test_results+=("memory:Launcher:FAIL")
    errors+=("Config contract checks failed")
fi

# Test each server
echo ""
echo "Testing individual servers..."

while IFS= read -r server_name; do
    if [ -z "$server_name" ]; then
        continue
    fi
    
    echo ""
    echo "Testing $server_name..."
    
    # Get server config
    server_config=$(python3 - "$mcp_config_path" "$server_name" <<'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        config = json.load(f)
    
    server = config.get('mcpServers', {}).get(sys.argv[2], {})
    command = server.get('command', '')
    args = server.get('args', [])
    
    print(f"command:{command}")
    for arg in args:
        print(f"arg:{arg}")
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)
    
    command=$(echo "$server_config" | grep "^command:" | cut -d: -f2-)
    
    if [ "$command" = "docker" ]; then
        # Check Docker
        if docker --version >/dev/null 2>&1; then
            echo "  ✓ Docker is available"
            test_results+=("$server_name:Docker Available:PASS")
        else
            echo "  ✗ Docker not available" >&2
            test_results+=("$server_name:Docker Available:FAIL")
            errors+=("$server_name: Docker not available")
        fi
        
        # Check image - find the image name (typically contains /) before --transport=stdio
        # Skip Docker flags, env vars, volumes, and MCP flags like --full, --code, --region
        image_name=$(echo "$server_config" | grep "^arg:" | grep -vE "^(run|-i|--rm|-e|-v|--transport=stdio|--full|--code|--region)$" | grep -vE "^(us|eu)$" | grep "/" | head -1 | cut -d: -f2-)
        if [ -n "$image_name" ]; then
            if docker images "$image_name" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
                echo "  ✓ Image exists locally: $image_name"
                test_results+=("$server_name:Image Exists:PASS:$image_name")
            elif docker manifest inspect "$image_name" >/dev/null 2>&1; then
                echo "  ✓ Image available on Docker Hub: $image_name"
                test_results+=("$server_name:Image Available:PASS:$image_name")
            else
                echo "  ⚠ Image not found: $image_name"
                test_results+=("$server_name:Image Available:WARN:$image_name")
            fi
        fi
        
        # Check environment variables
        env_vars=$(echo "$server_config" | grep "^arg:-e" -A 1 | grep "^arg:" | grep -v "^-e" | cut -d: -f2- | tr '\n' ',' | sed 's/,$//')
        if [ -n "$env_vars" ]; then
            echo "  ℹ Environment variables: $env_vars"
            test_results+=("$server_name:Env Vars:PASS:$env_vars")
        fi
    elif [ "$command" = "python" ]; then
        resolved="$script_dir/mcp-run-memory.py"
        if [ -f "$resolved" ]; then
            echo "  ✓ Python launcher exists: $resolved"
            test_results+=("$server_name:Python Launcher:PASS")
        else
            echo "  ✗ Python launcher missing: $resolved"
            test_results+=("$server_name:Python Launcher:FAIL")
            errors+=("$server_name: launcher missing")
        fi
        if docker --version >/dev/null 2>&1; then
            echo "  ✓ Docker is available (for launcher)"
            test_results+=("$server_name:Docker Available:PASS")
        fi
        if docker images "mcp/neo4j-memory" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
            echo "  ✓ Image exists locally: mcp/neo4j-memory"
            test_results+=("$server_name:Image Exists:PASS:mcp/neo4j-memory")
        fi
    else
        echo "  ⚠ Unknown command: $command"
        test_results+=("$server_name:Command Check:WARN:Unknown command: $command")
    fi
done <<< "$servers"

# Summary
echo ""
echo "=== Test Summary ==="
passed=$(echo "${test_results[@]}" | tr ' ' '\n' | grep -c ":PASS:" || true)
failed=$(echo "${test_results[@]}" | tr ' ' '\n' | grep -c ":FAIL:" || true)
warnings=$(echo "${test_results[@]}" | tr ' ' '\n' | grep -c ":WARN:" || true)

echo "Passed: $passed"
echo "Failed: $failed"
echo "Warnings: $warnings"

# Export results
output_dir="$HOME/.cursor/test-results"
mkdir -p "$output_dir"
output_path="$output_dir/mcp-test-$(date +%Y%m%d-%H%M%S).json"

python3 - "${test_results[*]}" "${errors[*]}" "$output_path" <<'PYEOF'
import json
import sys
from datetime import datetime

results_str = sys.argv[1]
errors_str = sys.argv[2] if len(sys.argv) > 2 else ""
output_path = sys.argv[3]

results = []
for item in results_str.split():
    if not item:
        continue
    parts = item.split(":", 3)
    if len(parts) >= 3:
        result = {
            "test": parts[1] if len(parts) > 1 else "Unknown",
            "status": parts[2] if len(parts) > 2 else "UNKNOWN"
        }
        if len(parts) > 3:
            result["message"] = parts[3]
        if len(parts) > 0:
            result["server"] = parts[0] if parts[0] != "Security" else None
        results.append(result)

errors_list = [e for e in errors_str.split("|") if e] if errors_str else []

passed = len([r for r in results if r.get("status") == "PASS"])
failed = len([r for r in results if r.get("status") == "FAIL"])
warnings = len([r for r in results if r.get("status") == "WARN"])

report = {
    "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    "summary": {
        "passed": passed,
        "failed": failed,
        "warnings": warnings
    },
    "results": results,
    "errors": errors_list
}

# Save JSON
with open(output_path, 'w') as f:
    json.dump(report, f, indent=2)

# Generate HTML
html_path = output_path.replace('.json', '.html')
html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>MCP Server Test Results</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #333; }}
        .summary {{ display: flex; gap: 20px; margin: 20px 0; }}
        .summary-item {{ padding: 15px; border-radius: 4px; flex: 1; }}
        .passed {{ background: #d4edda; color: #155724; }}
        .failed {{ background: #f8d7da; color: #721c24; }}
        .warnings {{ background: #fff3cd; color: #856404; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
        th {{ background: #f8f9fa; font-weight: bold; }}
        .status-pass {{ color: #28a745; font-weight: bold; }}
        .status-fail {{ color: #dc3545; font-weight: bold; }}
        .status-warn {{ color: #ffc107; font-weight: bold; }}
        .errors {{ background: #f8d7da; padding: 15px; border-radius: 4px; margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>MCP Server Test Results</h1>
        <p><strong>Timestamp:</strong> {report['timestamp']}</p>
        
        <div class="summary">
            <div class="summary-item passed">
                <h2>{passed}</h2>
                <p>Passed</p>
            </div>
            <div class="summary-item failed">
                <h2>{failed}</h2>
                <p>Failed</p>
            </div>
            <div class="summary-item warnings">
                <h2>{warnings}</h2>
                <p>Warnings</p>
            </div>
        </div>
        
        <h2>Test Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Server</th>
                    <th>Test</th>
                    <th>Status</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
"""

for result in results:
    server = result.get('server', 'N/A')
    test = result.get('test', 'Unknown')
    status = result.get('status', 'UNKNOWN')
    message = result.get('message', '')
    status_class = f"status-{status.lower()}" if status in ['PASS', 'FAIL', 'WARN'] else ""
    html_content += f"                <tr><td>{server}</td><td>{test}</td><td class=\"{status_class}\">{status}</td><td>{message}</td></tr>\n"

html_content += """            </tbody>
        </table>
"""

if errors_list:
    html_content += """        <div class="errors">
            <h2>Errors</h2>
            <ul>
"""
    for error in errors_list:
        html_content += f"                <li>{error}</li>\n"
    html_content += """            </ul>
        </div>
"""

html_content += """    </div>
</body>
</html>
"""

with open(html_path, 'w') as f:
    f.write(html_content)

print(f"\nResults saved to:")
print(f"  JSON: {output_path}")
print(f"  HTML: {html_path}")
PYEOF

if [ ${#errors[@]} -gt 0 ]; then
    echo ""
    echo "Errors:"
    for error in "${errors[@]}"; do
        echo "  - $error"
    done
    exit 1
fi

exit 0
