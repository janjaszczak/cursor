#!/bin/bash
# Kopiuje keepass (skill, skrypty, doc) z Windows .cursor do ~/.cursor w WSL home.
set -euo pipefail
WIN="/mnt/c/Users/janja/.cursor"
WSL_HOME="${WSL_CURSOR_HOME:-$HOME/.cursor}"

mkdir -p "$WSL_HOME/scripts/lib" "$WSL_HOME/skills/keepass" "$WSL_HOME/doc"

for f in get-keepass-secret.sh save-keepass-password-to-keyring.sh setup-keepass-keyring-linux.sh test-keepass-read.sh add-host-entry.sh keepass_ops.py; do
  if [ -f "$WIN/scripts/$f" ]; then
    cp -f "$WIN/scripts/$f" "$WSL_HOME/scripts/$f"
  fi
done
cp -f "$WIN/scripts/lib/"* "$WSL_HOME/scripts/lib/"
chmod +x "$WSL_HOME/scripts/"*.sh 2>/dev/null || true

cp -f "$WIN/skills/keepass/SKILL.md" "$WSL_HOME/skills/keepass/SKILL.md"
[ -f "$WIN/doc/keepass.md" ] && cp -f "$WIN/doc/keepass.md" "$WSL_HOME/doc/keepass.md"
[ -f "$WIN/keepass-db.path.example" ] && cp -f "$WIN/keepass-db.path.example" "$WSL_HOME/keepass-db.path.example"
if [ ! -f "$WSL_HOME/keepass-db.path" ] && [ -f "$WIN/keepass-db.path" ]; then
  cp -f "$WIN/keepass-db.path" "$WSL_HOME/keepass-db.path"
fi

rm -rf "$WSL_HOME/skills/keepass-integration"
rm -f "$WSL_HOME/doc/keepass-integration.md" 2>/dev/null || true

echo "Synced keepass -> $WSL_HOME"
ls -1 "$WSL_HOME/skills" | grep -E '^keepass' || true
ls -1 "$WSL_HOME/scripts/lib" | head -10
bash "$WSL_HOME/scripts/test-keepass-read.sh"
