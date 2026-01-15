# Universal MCP wrapper script for Windows
# Routes commands to WSL using bash wrapper
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

# Always route through WSL using bash wrapper
# The bash wrapper will detect if it's in WSL and run directly
$wslScriptPath = "/home/janja/.cursor/scripts/mcp-run.sh"

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
    # We're on Windows - route through WSL using bash script
    # Escape single quotes in command for bash
    $escapedCommand = $CommandString -replace "'", "'\''"
    wsl.exe -- bash -c "$wslScriptPath '$escapedCommand'"
    exit $LASTEXITCODE
} else {
    Write-Error "Error: wsl.exe not available. Cannot route to WSL."
    exit 1
}
