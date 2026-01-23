# Automatycznie zapisuje hasło bazy do PowerShell SecretManagement i Windows Credential Manager
# Wersja PowerShell dla Windows

$ErrorActionPreference = "Stop"

$DB_PATH = if ($env:KEEPASS_DB_PATH) { 
    $env:KEEPASS_DB_PATH 
} else { 
    "C:\Users\janja\OneDrive\Dokumenty\Inne\cursor.kdbx" 
}

Write-Host "Pobieranie hasła z bazy KeePassXC..." -ForegroundColor Cyan

# Pobierz hasło z wpisu w bazie (wymaga otwartej bazy w GUI)
try {
    $DB_PASSWORD = keepassxc-cli show -a "Password" $DB_PATH "Cursor Database Password" 2>$null
    if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) {
        Write-Host "Błąd: Nie można odczytać hasła z bazy. Upewnij się, że baza jest otwarta w KeePassXC GUI." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Błąd: Nie można odczytać hasła z bazy. Upewnij się, że baza jest otwarta w KeePassXC GUI." -ForegroundColor Red
    Write-Host "Szczegóły: $_" -ForegroundColor Yellow
    exit 1
}

Write-Host "Zapisywanie hasła do PowerShell SecretManagement..." -ForegroundColor Cyan

# Sprawdź czy NuGet provider jest zainstalowany
$nugetProvider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
if (-not $nugetProvider) {
    Write-Host "⚠ NuGet provider nie jest zainstalowany. Próba instalacji..." -ForegroundColor Yellow
    try {
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "✓ NuGet provider zainstalowany" -ForegroundColor Green
    } catch {
        Write-Host "✗ Błąd instalacji NuGet provider. Może wymagać uprawnień Administrator." -ForegroundColor Red
        Write-Host "  Uruchom PowerShell jako Administrator i wykonaj: Install-PackageProvider -Name NuGet -Force" -ForegroundColor Yellow
    }
}

# Zainstaluj moduły jeśli nie są dostępne
$secretMgmtInstalled = $false
if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
    Write-Host "Instalowanie Microsoft.PowerShell.SecretManagement..." -ForegroundColor Yellow
    try {
        Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser -Force -ErrorAction Stop
        $secretMgmtInstalled = $true
        Write-Host "✓ Microsoft.PowerShell.SecretManagement zainstalowany" -ForegroundColor Green
    } catch {
        Write-Host "✗ Błąd instalacji Microsoft.PowerShell.SecretManagement: $_" -ForegroundColor Red
    }
} else {
    $secretMgmtInstalled = $true
}

if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretStore)) {
    Write-Host "Instalowanie Microsoft.PowerShell.SecretStore..." -ForegroundColor Yellow
    try {
        Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "✓ Microsoft.PowerShell.SecretStore zainstalowany" -ForegroundColor Green
    } catch {
        Write-Host "✗ Błąd instalacji Microsoft.PowerShell.SecretStore: $_" -ForegroundColor Red
    }
}

# Zarejestruj vault jeśli nie istnieje
if (-not (Get-SecretVault -Name LocalStore -ErrorAction SilentlyContinue)) {
    Write-Host "Rejestrowanie vault LocalStore..." -ForegroundColor Yellow
    try {
        Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction Stop
        Write-Host "✓ Vault LocalStore zarejestrowany" -ForegroundColor Green
    } catch {
        Write-Host "✗ Błąd rejestracji vault: $_" -ForegroundColor Red
    }
}

# Zapisz hasło do SecretManagement
$secretSaved = $false
if ($secretMgmtInstalled) {
    try {
        $securePassword = ConvertTo-SecureString $DB_PASSWORD -AsPlainText -Force
        Set-Secret -Name KeePassXC-Cursor-DB -Secret $securePassword -Vault LocalStore -ErrorAction Stop
        
        # Weryfikacja zapisu
        $verifySecret = Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop
        if ($verifySecret -eq $DB_PASSWORD) {
            Write-Host "✓ Hasło zapisane do PowerShell SecretManagement (zweryfikowane)" -ForegroundColor Green
            $secretSaved = $true
        } else {
            Write-Host "⚠ Hasło zapisane, ale weryfikacja nie powiodła się" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Błąd zapisu do SecretManagement: $_" -ForegroundColor Red
    }
}

# Zapisz również do Windows Credential Manager (backup)
Write-Host "Zapisywanie hasła do Windows Credential Manager..." -ForegroundColor Cyan
cmdkey /generic:KeePassXC-Cursor-DB /user:cursor-db /pass:$DB_PASSWORD 2>$null
Write-Host "✓ Hasło zapisane do Windows Credential Manager" -ForegroundColor Green

Write-Host ""
Write-Host "Hasło zapisane pomyślnie!" -ForegroundColor Green
