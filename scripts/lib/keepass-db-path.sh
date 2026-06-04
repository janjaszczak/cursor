#!/bin/bash
# Resolve path to cursor.kdbx — bez domyślnych fallbacków.

keepass_config_candidates() {
    printf '%s\n' "${KEEPASS_DB_PATH_FILE:-$HOME/.cursor/keepass-db.path}"
    if [ -d "/mnt/c/Users" ]; then
        local u
        for u in "$(whoami 2>/dev/null)" "${USER:-}"; do
            [ -n "$u" ] && [ -f "/mnt/c/Users/$u/.cursor/keepass-db.path" ] && \
                printf '%s\n' "/mnt/c/Users/$u/.cursor/keepass-db.path"
        done
    fi
}

keepass_resolve_db_path() {
    if [ -n "${KEEPASS_DB_PATH:-}" ]; then
        printf '%s' "$KEEPASS_DB_PATH"
        return 0
    fi

    local cfg line
    while IFS= read -r cfg; do
        [ -z "$cfg" ] || [ ! -f "$cfg" ] && continue
        line=$(grep -v '^#' "$cfg" | grep -v '^[[:space:]]*$' | head -1 | tr -d '\r')
        if [ -n "$line" ]; then
            printf '%s' "$line"
            return 0
        fi
    done < <(keepass_config_candidates | awk '!seen[$0]++')
    return 1
}

keepass_require_db_path() {
    local p
    p=$(keepass_resolve_db_path) || true
    if [ -z "$p" ]; then
        cat >&2 <<'EOF'
Błąd: brak ścieżki do cursor.kdbx.

Agent: poproś użytkownika o utworzenie pliku:
  ~/.cursor/keepass-db.path

Jedna linia — absolutna ścieżka do zsynchronizowanego pliku (OneDrive / Google Drive).
Wzór: ~/.cursor/keepass-db.path.example

Opcjonalnie na sesję: export KEEPASS_DB_PATH="/pełna/ścieżka/cursor.kdbx"
EOF
        return 1
    fi
    if [ ! -f "$p" ]; then
        echo "Błąd: plik bazy nie istnieje: $p" >&2
        echo "Agent: poproś o poprawną ścieżkę w ~/.cursor/keepass-db.path lub synchronizację chmury." >&2
        return 1
    fi
    printf '%s' "$p"
}
