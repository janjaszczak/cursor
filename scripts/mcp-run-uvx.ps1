# Wrapper script for uvx-based MCP servers to run via WSL
param(
    [Parameter(Mandatory=$true)]
    [string]$Package,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$ExtraArgs
)

# Detect if running in WSL or Windows
if ($env:WSL_DISTRO_NAME) {
    # Already in WSL, run directly
    uvx @args
} else {
    # Running in Windows, route through WSL
    $wslArgs = @($Package) + $ExtraArgs
    wsl.exe -- bash -lc "uvx $($wslArgs -join ' ')"
}
