# keepass — runbook

Skill: `~/.cursor/skills/keepass/SKILL.md` (`/keepass`).

## Ścieżka bazy (wymagana)

Plik **`~/.cursor/keepass-db.path`** — jedna linia, absolutna ścieżka do `cursor.kdbx`.

- Brak pliku → agent **prosi użytkownika** o wskazanie.
- Brak domyślnych fallbacków ścieżki bazy w skryptach.
- **WSL:** wystarczy plik w Windows home: `/mnt/c/Users/<user>/.cursor/keepass-db.path` (skrypty sprawdzają też `~/.cursor/` w Linux home).
- **Dwie kopie `.cursor`:** edycje w `C:\Users\...\` nie trafiają automatycznie do `/home/.../.cursor`. Sync: `scripts/sync-keepass-to-wsl-home.sh`.
- Wzór: `keepass-db.path.example` (OneDrive / Google Drive).

## Natywny keyring

| OS | Mechanizm | Setup |
|----|-----------|--------|
| Windows | SecretStore | `setup-keepass-keyring.ps1` |
| Linux / WSL | secret-tool | `setup-keepass-keyring-linux.sh` |

Agent **doinstalowuje** brakujące pakiety/moduły; przy sudo bez NOPASSWD — prośba do użytkownika.

## Odczyt

- Linux/WSL: `get-keepass-secret.sh`
- Windows: `get-keepass-secret.ps1`

### EUK-SL01 (kanoniczne ścieżki)

| Wpis | Pole | Użycie |
|------|------|--------|
| `hosts/euk-sl01/sudo` | Password | `sudo` na hoście (user `janja`) |

**Nie używaj** nieistniejących wpisów: `EurekaCloud/poc/SL01/janja-sudo`, `hosts/euk-sl01/janja`, `hosts/euk-sl01/ssh`, `hosts/euk-mc02/eureka`.

| `hosts/euk-mc02/sudo` | Password | SSH + `sudo` na mc02 (user `eureka`) |
