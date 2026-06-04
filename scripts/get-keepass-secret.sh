#!/bin/bash
# Usage: ./get-keepass-secret.sh "Entry path" "Attribute Name"
# DB unlock: secret-tool (Linux) / PowerShell SecretStore (WSL+Windows) — NOT shared across OS.

set -euo pipefail

ENTRY_TITLE="${1:?entry path}"
ATTRIBUTE="${2:-Password}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/keepass-db-password.sh
. "$SCRIPT_DIR/lib/keepass-db-password.sh"

DB_PATH=$(keepass_require_db_path) || exit 1
export KEEPASS_DB_PATH="$DB_PATH"

DB_PASSWORD=$(keepass_get_db_password "$DB_PATH") || exit 1

printf '%s\n' "$DB_PASSWORD" | keepassxc-cli show -a "$ATTRIBUTE" "$DB_PATH" "$ENTRY_TITLE"
