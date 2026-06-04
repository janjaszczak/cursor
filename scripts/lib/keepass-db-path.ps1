function Get-KeepassDbPath {
    if ($env:KEEPASS_DB_PATH) {
        return $env:KEEPASS_DB_PATH.Trim()
    }
    $cfg = Join-Path $HOME ".cursor" "keepass-db.path"
    if (-not (Test-Path $cfg)) {
        throw @"
Brak ~/.cursor/keepass-db.path

Agent: poproś użytkownika o jedną linię z absolutną ścieżką do cursor.kdbx (OneDrive / Google Drive).
Wzór: ~/.cursor/keepass-db.path.example
"@
    }
    $line = Get-Content $cfg | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } | Select-Object -First 1
    if (-not $line) {
        throw "Plik keepass-db.path jest pusty. Agent: poproś o ścieżkę do cursor.kdbx."
    }
    return $line.Trim()
}

function Test-KeepassDbPath {
    $p = Get-KeepassDbPath
    if (-not (Test-Path $p)) {
        throw "Plik bazy nie istnieje: $p. Agent: poproś o poprawną ścieżkę lub sync chmury."
    }
    return $p
}
