# Universal MCP wrapper script for Windows and WSL/Ubuntu
# Detects environment and runs command appropriately
# This PowerShell version is used when Cursor on Windows needs to execute MCP servers
#
# Usage: .\mcp-run.ps1 <command> [args...]
# Example: .\mcp-run.ps1 "npx -y @sylweriusz/mcp-neo4j-memory-server"
# Example: .\mcp-run.ps1 "docker run -i --rm -e GRAFANA_URL -e GRAFANA_API_KEY mcp/grafana --transport=stdio"

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Command
)

if ($Command.Count -eq 0) {
    Write-Error "Error: No command provided"
    Write-Host "Usage: .\mcp-run.ps1 <command> [args...]" -ForegroundColor Yellow
    exit 1
}

# Join command parts into a single string
$CommandString = $Command -join " "

# Detect if we're running in WSL or Windows
if ($env:WSL_DISTRO_NAME) {
    # We're in WSL - use bash script directly
    $scriptPath = "/home/janja/.cursor/scripts/mcp-run.sh"
    if (Test-Path $scriptPath) {
        bash $scriptPath $CommandString
        exit $LASTEXITCODE
    } else {
        # Fallback: run directly via bash
        bash -lc $CommandString
        exit $LASTEXITCODE
    }
} elseif (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    # We're on Windows - route through WSL using bash script
    # Convert Windows path to WSL path if script path is provided as Windows path
    $wslScriptPath = "/home/janja/.cursor/scripts/mcp-run.sh"
    wsl.exe -- bash -c "$wslScriptPath '$CommandString'"
    exit $LASTEXITCODE
} else {
    # Fallback: try to run directly (shouldn't happen in normal usage)
    Write-Error "Error: Cannot determine environment. WSL not available."
    exit 1
}
