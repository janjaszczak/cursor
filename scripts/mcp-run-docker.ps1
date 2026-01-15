# Wrapper script for docker-based MCP servers to run via WSL
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$DockerArgs
)

# Detect if running in WSL or Windows
if ($env:WSL_DISTRO_NAME) {
    # Already in WSL, run directly
    docker @DockerArgs
} else {
    # Running in Windows, route through WSL
    # Docker on Windows typically uses Docker Desktop, so we can call docker.exe directly
    # But if Docker is only in WSL, route through WSL
    if (Get-Command docker.exe -ErrorAction SilentlyContinue) {
        docker.exe @DockerArgs
    } else {
        $wslArgs = $DockerArgs -join ' '
        wsl.exe -- bash -lc "docker $wslArgs"
    }
}
