# Pobiera sekret z bazy KeePassXC używając hasła z PowerShell SecretManagement / wpisu w bazie
# Wersja PowerShell dla Windows
# Usage: .\get-keepass-secret.ps1 "Entry Title" "Attribute Name"

param(
    [Parameter(Mandatory=$true)]
    [string]$EntryTitle,
    
    [Parameter(Mandatory=$true)]
    [string]$Attribute
)

$ErrorActionPreference = "Stop"

$DB_PATH = if ($env:KEEPASS_DB_PATH) { 
    $env:KEEPASS_DB_PATH 
} else { 
    "C:\Users\janja\OneDrive\Dokumenty\Inne\cursor.kdbx" 
}

# Metoda 1: Pobierz hasło z PowerShell SecretManagement (główna metoda)
$DB_PASSWORD = $null
$methodUsed = $null

try {
    if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
        $DB_PASSWORD = Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($DB_PASSWORD)) {
            $methodUsed = "PowerShell SecretManagement"
        }
    }
} catch {
    # SecretManagement nie działa lub hasło nie istnieje - spróbuj następnej metody
}

# Metoda 2: Jeśli SecretManagement nie działa, spróbuj z wpisu w bazie (jeśli baza jest otwarta w GUI)
if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) {
    try {
        $tempPassword = keepassxc-cli show -a "Password" $DB_PATH "Cursor Database Password" 2>$null
        if (-not [string]::IsNullOrWhiteSpace($tempPassword)) {
            $DB_PASSWORD = $tempPassword
            $methodUsed = "wpis w bazie"
        }
    } catch {
        # Nie można odczytać z bazy - spróbuj następnej metody
    }
}

# Metoda 3: Jeśli nadal nie ma hasła, zapytaj interaktywnie
if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) {
    Write-Host "Nie można pobrać hasła automatycznie. Wprowadź hasło bazy:" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $DB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $methodUsed = "interaktywnie"
}

# Weryfikacja czy hasło zostało pobrane
if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) {
    Write-Host "Błąd: Nie udało się pobrać hasła bazy." -ForegroundColor Red
    exit 1
}

# Użyj hasła do pobrania sekretu
$DB_PASSWORD | keepassxc-cli show -a $Attribute $DB_PATH $EntryTitle
