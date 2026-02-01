#!/usr/bin/env python3
"""
Migrate Cursor chat history from workspace 'moltbot' to 'openclow'.

When Cursor runs on Windows and opens a WSL folder, chat state is stored in
Windows: %APPDATA%\\Cursor\\User\\workspaceStorage\\<workspaceId>\\state.vscdb
(WSL .cursor-server has no state.vscdb — only indexing.)

Openclow can be opened two ways, giving two workspace IDs:
- 9d323027: file://wsl.../.cursor/projects/home-janja-github-openclow (WSL / agent link)
- 5699c7de: vscode-remote://wsl+ubuntu/.../github/openclow (direct repo path)

This script merges composer + aiService data from moltbot into BOTH openclow
workspaces so history is visible regardless of how you open the project.

Requirements: Run from WSL with Cursor closed. Backup per target. Windows
AppData must be mounted at /mnt/c/Users/<user>/AppData/...
"""

from __future__ import annotations

import json
import shutil
import sqlite3
import sys
from pathlib import Path

# Windows workspace storage (mount from WSL)
APPDATA = Path("/mnt/c/Users/janja/AppData/Roaming/Cursor/User/workspaceStorage")
MOLTBOT_WS = "3798b10ab43013b53deaa9b775732bc8"  # vscode-remote://wsl+ubuntu/.../github/moltbot
# Both openclow workspaces (merge into each so either open path shows history)
OPENCLOW_WS_IDS = [
    "9d323027d441b2072009cb4b9898ec3d",   # file://wsl.../.cursor/projects/home-janja-github-openclow
    "5699c7de94fc48dc6ce726081d39be34",   # vscode-remote://wsl+ubuntu/.../github/openclow
]


def get_item(cursor: sqlite3.Cursor, key: str) -> str | None:
    row = cursor.execute("SELECT value FROM ItemTable WHERE key = ?", (key,)).fetchone()
    return row[0] if row else None


def set_item(cursor: sqlite3.Cursor, key: str, value: str) -> None:
    cursor.execute(
        "INSERT OR REPLACE INTO ItemTable (key, value) VALUES (?, ?)",
        (key, value),
    )


def merge_composer_data(molt: dict, openclow: dict) -> dict:
    """Merge allComposers from moltbot into openclow; merge selected/focused so old chats appear in UI."""
    out = dict(openclow)
    molt_all = molt.get("allComposers") or []
    open_all = out.get("allComposers") or []
    # Prepend moltbot composers so they appear in history (older first, then openclow)
    out["allComposers"] = molt_all + open_all
    # Merge selectedComposerIds and lastFocusedComposerIds so migrated chats appear in the chat history list
    def merge_ids(m_key: str, o_key: str) -> list:
        m_ids = molt.get(m_key) or []
        o_ids = openclow.get(o_key) or []
        return list(dict.fromkeys(m_ids + o_ids))  # prepend moltbot, dedupe
    out["selectedComposerIds"] = merge_ids("selectedComposerIds", "selectedComposerIds")
    out["lastFocusedComposerIds"] = merge_ids("lastFocusedComposerIds", "lastFocusedComposerIds")
    return out


def merge_list(molt_list: list, openclow_list: list) -> list:
    """Merge lists: moltbot entries first (older), then openclow."""
    return (molt_list or []) + (openclow_list or [])


def migrate_into(conn_molt: sqlite3.Connection, openclow_db: Path) -> bool:
    """Merge moltbot chat data into one openclow state.vscdb. Returns True on success."""
    if not openclow_db.exists():
        print(f"  Skip (no DB): {openclow_db.parent.name}")
        return False
    backup = openclow_db.with_name("state.vscdb.backup_before_migrate")
    if backup.exists():
        print(f"  Skip (backup exists): {openclow_db.parent.name}")
        return False
    shutil.copy2(openclow_db, backup)
    print(f"  Backup: {backup.name}")

    cur_m = conn_molt.cursor()
    conn_open = sqlite3.connect(openclow_db)
    try:
        cur_o = conn_open.cursor()
        composer_m = get_item(cur_m, "composer.composerData")
        composer_o = get_item(cur_o, "composer.composerData")
        if composer_m and composer_o:
            j_m = json.loads(composer_m)
            j_o = json.loads(composer_o)
            merged = merge_composer_data(j_m, j_o)
            set_item(cur_o, "composer.composerData", json.dumps(merged))
            print(f"  composerData: {len(j_m.get('allComposers', []))} + {len(j_o.get('allComposers', []))} -> {len(merged['allComposers'])}")
        gen_m = get_item(cur_m, "aiService.generations")
        gen_o = get_item(cur_o, "aiService.generations")
        if gen_m and gen_o:
            list_m, list_o = json.loads(gen_m), json.loads(gen_o)
            set_item(cur_o, "aiService.generations", json.dumps(merge_list(list_m, list_o)))
            print(f"  aiService.generations: {len(list_m)} + {len(list_o)} -> {len(list_m) + len(list_o)}")
        pr_m = get_item(cur_m, "aiService.prompts")
        pr_o = get_item(cur_o, "aiService.prompts")
        if pr_m and pr_o:
            list_m, list_o = json.loads(pr_m), json.loads(pr_o)
            set_item(cur_o, "aiService.prompts", json.dumps(merge_list(list_m, list_o)))
            print(f"  aiService.prompts: {len(list_m)} + {len(list_o)} -> {len(list_m) + len(list_o)}")
        conn_open.commit()
        return True
    finally:
        conn_open.close()


def main() -> int:
    molt_db = APPDATA / MOLTBOT_WS / "state.vscdb"
    if not molt_db.exists():
        print(f"Error: moltbot workspace DB not found: {molt_db}", file=sys.stderr)
        return 1

    conn_molt = sqlite3.connect(molt_db)
    try:
        for ws_id in OPENCLOW_WS_IDS:
            openclow_db = APPDATA / ws_id / "state.vscdb"
            print(f"Target {ws_id}:")
            migrate_into(conn_molt, openclow_db)
        print("Done. Restart Cursor and open openclow (WSL or repo path) to see merged history.")
    finally:
        conn_molt.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
