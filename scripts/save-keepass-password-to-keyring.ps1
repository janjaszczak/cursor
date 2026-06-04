# Windows (natywny): zapis hasła master do SecretStore.
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\keepass-db-path.ps1")
. (Join-Path $PSScriptRoot "lib\keepass-secretstore.ps1")

$null = Test-KeepassDbPath

if ([string]::IsNullOrWhiteSpace($env:KEEPASS_DB_PASSWORD)) {
    Write-Error "Ustaw KEEPASS_DB_PASSWORD (hasło master cursor.kdbx)."
}

Ensure-KeepassSecretStore
$secure = ConvertTo-SecureString $env:KEEPASS_DB_PASSWORD.Trim() -AsPlainText -Force
Set-Secret -Name KeePassXC-Cursor-DB -Secret $secure -Vault LocalStore
Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText | Out-Null
Write-Host "OK: hasło bazy w SecretStore (Windows)"
