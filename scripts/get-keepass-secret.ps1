# Windows (natywny): SecretStore + keepassxc-cli
# Usage: .\get-keepass-secret.ps1 "Entry/Path" "Password"

param(
    [Parameter(Mandatory = $true)]
    [string]$EntryTitle,
    [Parameter(Mandatory = $true)]
    [string]$Attribute
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\keepass-db-path.ps1")
. (Join-Path $PSScriptRoot "lib\keepass-secretstore.ps1")

$DB_PATH = Test-KeepassDbPath
$env:KEEPASS_DB_PASSWORD = Get-KeepassDbPasswordFromSecretStore
$env:KEEPASS_DB_PASSWORD | & keepassxc-cli show -a $Attribute $DB_PATH $EntryTitle
