#!/bin/bash
# Smoke test — Linux/WSL (secret-tool). Windows: get-keepass-secret.ps1
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/keepass-db-path.sh
. "$SCRIPT_DIR/lib/keepass-db-path.sh"

export KEEPASS_DB_PATH
KEEPASS_DB_PATH=$(keepass_require_db_path) || { echo "GET_SECRET_FAIL: keepass-db.path"; exit 1; }

if out=$("$SCRIPT_DIR/get-keepass-secret.sh" "hosts/euk-sl01/sudo" "Password" 2>&1); then
  if [ -n "$out" ]; then
    echo "GET_SECRET_OK"
    exit 0
  fi
fi
echo "GET_SECRET_FAIL"
exit 1
