# Windows: SecretStore + sync wpisu Cursor Database Password w .kdbx
# Usage: $env:KEEPASS_DB_PASSWORD = '...'; .\setup-keepass-keyring.ps1

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "lib\keepass-db-path.ps1")

if ([string]::IsNullOrWhiteSpace($env:KEEPASS_DB_PASSWORD)) {
    Write-Error "Set KEEPASS_DB_PASSWORD before running."
}

$DB_PATH = Test-KeepassDbPath
& (Join-Path $PSScriptRoot "save-keepass-password-to-keyring.ps1")

$py = @"
import os
from pykeepass import PyKeePass
db = r'$DB_PATH'
pw = os.environ['KEEPASS_DB_PASSWORD']
kp = PyKeePass(db, password=pw)
e = kp.find_entries(title='Cursor Database Password', first=True)
if e:
    e.password = pw
else:
    kp.add_entry(kp.root_group, 'Cursor Database Password', '', pw)
kp.save()
"@
python -c $py
Write-Host "OK: setup Windows (SecretStore + .kdbx)"
