#!/bin/bash
# Add or update a host login entry in cursor.kdbx (check-before-add).
# Usage: add-host-entry.sh <host-short> <username> <fqdn> [entry-password on stdin]
# Example: echo 'secret' | add-host-entry.sh euk-sl01 janja euk-sl01.tail82894f.ts.net

set -euo pipefail

HOST_SHORT="${1:?host short name, e.g. euk-sl01}"
USERNAME="${2:?username, e.g. janja}"
FQDN="${3:?FQDN, e.g. euk-sl01.tail82894f.ts.net}"
DB_PATH="${KEEPASS_DB_PATH:-/mnt/c/Users/janja/OneDrive/Dokumenty/Inne/cursor.kdbx}"
ENTRY_PATH="hosts/${HOST_SHORT}/${USERNAME}"
URL="ssh://${USERNAME}@${FQDN}"
NOTES="Host: ${HOST_SHORT}
FQDN: ${FQDN}
Tailscale
Account: ${USERNAME}"

get_db_password() {
  local pw=""
  pw=$(powershell.exe -NoProfile -Command "try { (Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop) } catch { \$null }" 2>/dev/null | tr -d '\r')
  if [ -n "$pw" ]; then echo "$pw"; return; fi
  if command -v secret-tool >/dev/null 2>&1; then
    pw=$(secret-tool lookup service keepassxc attribute cursor-db 2>/dev/null || true)
    if [ -n "$pw" ]; then echo "$pw"; return; fi
  fi
  pw=$(keepassxc-cli show -a Password "$DB_PATH" "Cursor Database Password" 2>/dev/null || true)
  if [ -n "$pw" ]; then echo "$pw"; return; fi
  return 1
}

DB_PASSWORD=""
if ! DB_PASSWORD=$(get_db_password); then
  echo "Podaj hasło bazy cursor.kdbx:" >&2
  read -rs DB_PASSWORD
  echo >&2
fi

ENTRY_PASSWORD=""
if [ ! -t 0 ]; then
  ENTRY_PASSWORD=$(cat)
fi

cli() {
  printf '%s\n' "$DB_PASSWORD" | keepassxc-cli "$@" "$DB_PATH"
}

group_exists() {
  local group="$1"
  cli ls "$group" >/dev/null 2>&1
}

ensure_group() {
  local group="$1"
  if ! group_exists "$group"; then
    printf '%s\n' "$DB_PASSWORD" | keepassxc-cli mkdir "$DB_PATH" "$group" >/dev/null
  fi
}

if cli show "$ENTRY_PATH" >/dev/null 2>&1; then
  echo "Wpis już istnieje: ${ENTRY_PATH}" >&2
  if [ -n "$ENTRY_PASSWORD" ]; then
    printf '%s\n%s\n' "$DB_PASSWORD" "$ENTRY_PASSWORD" | keepassxc-cli edit -p "$DB_PATH" "$ENTRY_PATH" >/dev/null
    echo "Zaktualizowano hasło: ${ENTRY_PATH}"
  else
    echo "Bez zmian hasła (brak stdin)."
  fi
  exit 0
fi

ensure_group "hosts"
ensure_group "hosts/${HOST_SHORT}"

if [ -n "$ENTRY_PASSWORD" ]; then
  printf '%s\n%s\n' "$DB_PASSWORD" "$ENTRY_PASSWORD" | keepassxc-cli add -u "$USERNAME" --url "$URL" --notes "$NOTES" -p "$DB_PATH" "$ENTRY_PATH" >/dev/null
else
  printf '%s\n' "$DB_PASSWORD" | keepassxc-cli add -u "$USERNAME" --url "$URL" --notes "$NOTES" -g "$DB_PATH" "$ENTRY_PATH" >/dev/null
  echo "UWAGA: Wygenerowano tymczasowe hasło — ustaw prawdziwe hasło konta w KeePassXC (Edit wpisu ${ENTRY_PATH})."
fi

echo "Dodano: ${ENTRY_PATH}"
printf '%s\n' "$DB_PASSWORD" | keepassxc-cli search "$DB_PATH" "$HOST_SHORT" 2>/dev/null || true
