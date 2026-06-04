#!/bin/bash
# Linux / WSL: zapis hasła master do natywnego secret-tool.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/keepass-db-password.sh
. "$SCRIPT_DIR/lib/keepass-db-password.sh"
# shellcheck source=lib/keepass-platform.sh
. "$SCRIPT_DIR/lib/keepass-platform.sh"

DB_PATH=$(keepass_require_db_path) || exit 1
export KEEPASS_DB_PATH="$DB_PATH"

keepass_ensure_secret_tool || exit 1

if [ -z "${KEEPASS_DB_PASSWORD:-}" ]; then
    echo "Błąd: ustaw KEEPASS_DB_PASSWORD (hasło master cursor.kdbx) na tej sesji." >&2
    exit 1
fi

printf '%s' "$KEEPASS_DB_PASSWORD" | secret-tool store --label="KeePassXC Cursor DB" service keepassxc attribute cursor-db
secret-tool lookup service keepassxc attribute cursor-db >/dev/null
echo "OK: hasło bazy w secret-tool ($(keepass_platform))"
