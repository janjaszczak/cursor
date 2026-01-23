#!/bin/bash
# Automatycznie zapisuje hasło bazy KeePassXC do PowerShell SecretManagement i secret-tool (jeśli dostępny)
# Działa zarówno z Windows jak i WSL
# Uwaga: To skrypt zapisuje TYLKO hasło bazy KeePassXC, nie hasła z bazy!

DB_PATH="${KEEPASS_DB_PATH:-/mnt/c/Users/janja/OneDrive/Dokumenty/Inne/cursor.kdbx}"

# Pobierz hasło z wpisu w bazie (wymaga otwartej bazy w GUI)
DB_PASSWORD=$(keepassxc-cli show -a "Password" "$DB_PATH" "Cursor Database Password" 2>/dev/null)

if [ -z "$DB_PASSWORD" ]; then
    echo "Błąd: Nie można odczytać hasła z bazy. Upewnij się, że baza jest otwarta w KeePassXC GUI." >&2
    exit 1
fi

SUCCESS_METHODS=()

# Metoda 1: Zapisz do PowerShell SecretManagement (główna metoda - pozwala na odczyt)
if powershell.exe -Command "
    # Zainstaluj moduły jeśli nie są dostępne
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
        Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretStore)) {
        Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
    
    # Zarejestruj vault jeśli nie istnieje
    if (-not (Get-SecretVault -Name LocalStore -ErrorAction SilentlyContinue)) {
        Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -ErrorAction SilentlyContinue
    }
    
    # Zapisz hasło
    try {
        \$securePassword = ConvertTo-SecureString \"$DB_PASSWORD\" -AsPlainText -Force
        Set-Secret -Name KeePassXC-Cursor-DB -Secret \$securePassword -Vault LocalStore -ErrorAction Stop
        Write-Host 'OK'
    } catch {
        Write-Host 'FAIL'
    }
" 2>/dev/null | grep -q "OK"; then
    SUCCESS_METHODS+=("PowerShell SecretManagement")
fi

# Metoda 2: Zapisz do secret-tool jeśli dostępny (wymaga D-Bus)
if command -v secret-tool >/dev/null 2>&1; then
    if echo "$DB_PASSWORD" | secret-tool store --label="KeePassXC Cursor DB" service keepassxc attribute cursor-db 2>/dev/null; then
        SUCCESS_METHODS+=("secret-tool")
    fi
fi

# Zapisz również do Windows Credential Manager (backup, ale nie można odczytać przez cmdkey)
powershell.exe -Command "cmdkey /generic:KeePassXC-Cursor-DB /user:cursor-db /pass:\"$DB_PASSWORD\"" 2>/dev/null
if [ $? -eq 0 ]; then
    SUCCESS_METHODS+=("Windows Credential Manager")
fi

# Podsumowanie
if [ ${#SUCCESS_METHODS[@]} -gt 0 ]; then
    echo "✓ Hasło bazy zapisane do: ${SUCCESS_METHODS[*]}"
else
    echo "✗ Błąd: Nie udało się zapisać hasła do żadnej metody" >&2
    exit 1
fi
