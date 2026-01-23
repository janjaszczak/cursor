#!/bin/bash
# Usage: ./get-keepass-secret.sh "Entry Title" "Attribute Name"
# Pobiera sekret z bazy KeePassXC używając hasła bazy z PowerShell SecretManagement / secret-tool / wpisu w bazie
# Działa zarówno z Windows jak i WSL
# Uwaga: Wszystkie hasła/sekrety są przechowywane w bazie KeePassXC, ten skrypt tylko pobiera hasło bazy!

ENTRY_TITLE="$1"
ATTRIBUTE="$2"
DB_PATH="${KEEPASS_DB_PATH:-/mnt/c/Users/janja/OneDrive/Dokumenty/Inne/cursor.kdbx}"

# Metoda 1: Pobierz hasło bazy z PowerShell SecretManagement (główna metoda - działa z WSL przez PowerShell)
DB_PASSWORD=$(powershell.exe -Command "
    try {
        if (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement) {
            (Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop)
        }
    } catch {
        \$null
    }
" 2>/dev/null)

# Metoda 2: Jeśli SecretManagement nie działa, spróbuj secret-tool (jeśli dostępny i D-Bus działa)
if [ -z "$DB_PASSWORD" ] && command -v secret-tool >/dev/null 2>&1; then
    DB_PASSWORD=$(secret-tool lookup service keepassxc attribute cursor-db 2>/dev/null)
fi

# Metoda 3: Jeśli secret-tool nie działa, spróbuj z wpisu w bazie (jeśli baza jest otwarta w GUI)
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(keepassxc-cli show -a "Password" "$DB_PATH" "Cursor Database Password" 2>/dev/null)
fi

# Metoda 4: Jeśli nadal nie ma hasła, zapytaj interaktywnie
if [ -z "$DB_PASSWORD" ]; then
    echo "Nie można pobrać hasła bazy automatycznie. Wprowadź hasło bazy:" >&2
    read -s DB_PASSWORD
fi

# Użyj hasła bazy do pobrania sekretu z bazy KeePassXC
echo "$DB_PASSWORD" | keepassxc-cli show -a "$ATTRIBUTE" "$DB_PATH" "$ENTRY_TITLE"
