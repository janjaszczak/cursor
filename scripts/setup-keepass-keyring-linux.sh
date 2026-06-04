#!/bin/bash
# Linux / WSL: jednorazowy setup secret-tool + opcjonalnie wpis w .kdbx.
# Usage: KEEPASS_DB_PASSWORD='…' ~/.cursor/scripts/setup-keepass-keyring-linux.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/keepass-platform.sh
. "$SCRIPT_DIR/lib/keepass-platform.sh"

keepass_ensure_secret_tool || exit 1

if [ -z "${KEEPASS_DB_PASSWORD:-}" ]; then
    echo "Błąd: KEEPASS_DB_PASSWORD wymagane." >&2
    exit 1
fi

"$SCRIPT_DIR/save-keepass-password-to-keyring.sh"
echo "Setup Linux/WSL ($(keepass_platform)) zakończony."
