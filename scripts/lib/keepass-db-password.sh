#!/bin/bash
# DB master password — natywny keyring per OS (bash = Linux/WSL → secret-tool only).

_SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=keepass-db-path.sh
. "$_SCRIPT_LIB_DIR/keepass-db-path.sh"
# shellcheck source=keepass-platform.sh
. "$_SCRIPT_LIB_DIR/keepass-platform.sh"

keepass_db_password_from_secret_tool() {
    secret-tool lookup service keepassxc attribute cursor-db 2>/dev/null
}

keepass_get_db_password() {
    local db_path="${1:-}"
    if [ -z "$db_path" ]; then
        db_path=$(keepass_resolve_db_path) || true
    fi

    if [ -n "${KEEPASS_DB_PASSWORD:-}" ]; then
        printf '%s' "$KEEPASS_DB_PASSWORD"
        return 0
    fi

    keepass_ensure_secret_tool || return 1

    local pw
    pw=$(keepass_db_password_from_secret_tool) || true
    if [ -n "$pw" ]; then
        printf '%s' "$pw"
        return 0
    fi

    cat >&2 <<EOF
Nie można odczytać hasła bazy z secret-tool (Linux/WSL).

Agent: uruchom jednorazowo:
  KEEPASS_DB_PASSWORD='…' ~/.cursor/scripts/setup-keepass-keyring-linux.sh
lub (jeśli baza otwarta w KeePassXC na tej maszynie):
  ~/.cursor/scripts/save-keepass-password-to-keyring.sh

Platforma: $(keepass_platform)
EOF
    return 1
}
