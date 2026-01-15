# Wrapper script for Shrimp Task Manager to run via WSL
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)

# Shrimp is installed in WSL at ~/mcp-shrimp-task-manager/dist/index.js
$shrimpPath = "/home/janja/mcp-shrimp-task-manager/dist/index.js"

# Detect if running in WSL or Windows
if ($env:WSL_DISTRO_NAME) {
    # Already in WSL, run directly
    node "$shrimpPath" @ExtraArgs
} else {
    # Running in Windows, route through WSL
    $wslArgs = @($shrimpPath) + $ExtraArgs
    wsl.exe -- bash -lc "node $($wslArgs -join ' ')"
}
