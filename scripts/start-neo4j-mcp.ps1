# Start Neo4j on mcp-network so the MCP memory server can connect (bolt://neo4j:7687).
# Requires NEO4J_PASSWORD in environment (User env or .env loaded into the session).
# Prefer automatic start via scripts/mcp-run-memory.py (Cursor memory MCP entry).
#
# Usage: .\scripts\start-neo4j-mcp.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $env:NEO4J_PASSWORD -or $env:NEO4J_PASSWORD -eq "CHANGE_ME") {
    Write-Error "NEO4J_PASSWORD is not set (or still CHANGE_ME). Set it or run setup-env-vars.ps1."
    exit 1
}

docker network create mcp-network 2>$null | Out-Null

$existing = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq "neo4j" }
if ($existing) {
    docker start neo4j | Out-Null
    docker update --restart unless-stopped neo4j | Out-Null
    Write-Host "Neo4j container 'neo4j' started (restart=unless-stopped)."
} else {
    docker run -d --name neo4j `
        --restart unless-stopped `
        --network mcp-network `
        -p 7687:7687 `
        -e "NEO4J_AUTH=neo4j/$($env:NEO4J_PASSWORD)" `
        neo4j:latest | Out-Null
    Write-Host "Neo4j created on mcp-network (restart=unless-stopped)."
}

Write-Host "Waiting for Neo4j readiness..."
$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    docker exec neo4j bash -c "wget -qO- http://127.0.0.1:7474 >/dev/null 2>&1 || curl -sf http://127.0.0.1:7474 >/dev/null 2>&1" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Neo4j is ready at bolt://neo4j:7687 (mcp-network) / bolt://localhost:7687 (host)."
        Write-Host "Memory MCP uses NEO4J_URL=bolt://neo4j:7687 via $scriptDir\mcp-run-memory.py"
        exit 0
    }
    Start-Sleep -Seconds 2
}

Write-Error "Neo4j did not become ready within 90s"
exit 1
