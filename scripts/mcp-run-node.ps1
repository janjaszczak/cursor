# Wrapper script for node-based MCP servers to run via WSL
param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)

# Convert Windows path to WSL path if needed
if ($ScriptPath -match '^[A-Z]:') {
    $ScriptPath = $ScriptPath -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/'
    $ScriptPath = $ScriptPath.ToLower()
}

# Detect if running in WSL or Windows
if ($env:WSL_DISTRO_NAME) {
    # Already in WSL, run directly
    node "$ScriptPath" @ExtraArgs
} else {
    # Running in Windows, route through WSL
    $wslArgs = @($ScriptPath) + $ExtraArgs
    wsl.exe -- bash -lc "node $($wslArgs -join ' ')"
}
