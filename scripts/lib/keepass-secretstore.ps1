function Ensure-KeepassSecretStore {
    foreach ($m in @("Microsoft.PowerShell.SecretManagement", "Microsoft.PowerShell.SecretStore")) {
        if (-not (Get-Module -ListAvailable -Name $m)) {
            Write-Host "Instalacja $m..." -ForegroundColor Yellow
            Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber
        }
        Import-Module $m -ErrorAction Stop
    }
    $cfg = Get-SecretStoreConfiguration -ErrorAction SilentlyContinue
    if ($null -eq $cfg -or $cfg.Authentication -ne [Microsoft.PowerShell.SecretStore.SecretStoreAuthentication]::None) {
        Reset-SecretStore -Authentication None -Interaction None -Force -Scope CurrentUser
    }
    if (-not (Get-SecretVault -Name LocalStore -ErrorAction SilentlyContinue)) {
        Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
    }
}

function Get-KeepassDbPasswordFromSecretStore {
    Ensure-KeepassSecretStore
    $pw = Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($pw)) {
        throw @"
Brak KeePassXC-Cursor-DB w SecretStore (Windows).

Agent: uruchom setup-keepass-keyring.ps1 z KEEPASS_DB_PASSWORD lub save-keepass-password-to-keyring.ps1
"@
    }
    return $pw
}
