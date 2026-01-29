#!/usr/bin/env python3
"""
KeePassXC CLI helper: get, add, update entries with check-before-add.

Uses keyring for DB password (PowerShell SecretManagement or secret-tool).
Requires keepassxc-cli on PATH. No extra dependencies (stdlib only).

Usage:
  keepass_ops.py get <path_or_title> [--attr ATTRIBUTE]
  keepass_ops.py add <path> [--username USER] [--password-from-stdin]
  keepass_ops.py update <path> [--password-from-stdin]
  keepass_ops.py list [<group_path>]
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from typing import Optional


def get_db_path() -> str:
    return os.environ.get(
        "KEEPASS_DB_PATH",
        "/mnt/c/Users/janja/OneDrive/Dokumenty/Inne/cursor.kdbx",
    )


def get_db_password() -> Optional[str]:
    """Retrieve KeePassXC DB password from keyring (SecretManagement or secret-tool)."""
    # 1. PowerShell SecretManagement
    try:
        result = subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-Command",
                "try { (Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop) } catch { $null }",
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    # 2. secret-tool (Linux/WSL)
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "service", "keepassxc", "attribute", "cursor-db"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0 and result.stdout:
            return result.stdout.strip()
    except FileNotFoundError:
        pass

    return None


def run_cli(
    db_path: str,
    db_password: str,
    *args: str,
    stdin: Optional[str] = None,
) -> tuple[int, str, str]:
    """Run keepassxc-cli with password on stdin. Returns (returncode, stdout, stderr)."""
    cmd = ["keepassxc-cli", "--no-password", *args, db_path]
    proc = subprocess.run(
        cmd,
        input=stdin or db_password,
        capture_output=True,
        text=True,
        timeout=30,
    )
    return proc.returncode, proc.stdout or "", proc.stderr or ""


def cmd_get(db_path: str, path_or_title: str, attr: str) -> int:
    """Get an attribute (e.g. Password) for an entry."""
    password = get_db_password()
    if not password:
        print("Error: Could not retrieve DB password from keyring. Run save-keepass-password-to-keyring.sh first.", file=sys.stderr)
        return 1
    args = ["show", "-a", attr, path_or_title]
    code, out, err = run_cli(db_path, password, *args)
    if code != 0:
        if err:
            print(err, file=sys.stderr)
        return code
    print(out.rstrip())
    return 0


def cmd_list(db_path: str, group_path: Optional[str]) -> int:
    """List entries in root or in a group."""
    password = get_db_password()
    if not password:
        print("Error: Could not retrieve DB password from keyring.", file=sys.stderr)
        return 1
    args = ["ls", "-R"] if group_path is None else ["ls", "-R", group_path]
    code, out, err = run_cli(db_path, password, *args)
    if code != 0:
        if err:
            print(err, file=sys.stderr)
        return code
    print(out.rstrip())
    return 0


def ensure_group_exists(db_path: str, db_password: str, group_path: str) -> bool:
    """Ensure group exists; create with mkdir if not. Returns True on success."""
    parts = group_path.strip("/").split("/")
    for i in range(1, len(parts) + 1):
        parent = "/".join(parts[:i])
        code, out, err = run_cli(db_path, db_password, "ls", parent)
        if code != 0:
            code_mk, _, err_mk = run_cli(db_path, db_password, "mkdir", parent)
            if code_mk != 0:
                print(f"Error creating group {parent}: {err_mk}", file=sys.stderr)
                return False
    return True


def cmd_add(
    db_path: str,
    entry_path: str,
    username: Optional[str],
    password_stdin: bool,
) -> int:
    """Add a new entry. Path = Group/Subgroup/EntryTitle. Check-before-add: if entry exists, error."""
    password = get_db_password()
    if not password:
        print("Error: Could not retrieve DB password from keyring.", file=sys.stderr)
        return 1
    if "/" not in entry_path:
        print("Error: Entry path must be Group/Env/EntryTitle (e.g. MyApp/prod/API Key).", file=sys.stderr)
        return 1
    parts = entry_path.rsplit("/", 1)
    group_path = parts[0]
    entry_title = parts[1]
    # Check if entry already exists
    code_loc, out_loc, _ = run_cli(db_path, password, "locate", entry_title)
    if code_loc == 0 and out_loc.strip():
        for line in out_loc.strip().splitlines():
            if entry_path in line or entry_title in line:
                print(f"Error: Entry already exists. Use 'update' to change: {entry_path}", file=sys.stderr)
                return 1
    if not ensure_group_exists(db_path, password, group_path):
        return 1
    entry_password: Optional[str] = None
    if password_stdin:
        entry_password = sys.stdin.read().strip()
    if not entry_password:
        print("Error: --password-from-stdin required for add (pipe password, e.g. echo 'secret' | keepass_ops.py add ... --password-from-stdin).", file=sys.stderr)
        return 1
    args = ["add", "-u", username or "api", "-p", entry_path]
    code, out, err = run_cli(db_path, password, *args, stdin=password + "\n" + entry_password + "\n")
    if code != 0:
        # keepassxc-cli add prompts: first DB password, then entry password. We pass both.
        print(err or out, file=sys.stderr)
        return code
    print("Added:", entry_path)
    return 0


def cmd_update(db_path: str, entry_path: str, password_stdin: bool) -> int:
    """Update an existing entry's password. Check-before: entry must exist."""
    password = get_db_password()
    if not password:
        print("Error: Could not retrieve DB password from keyring.", file=sys.stderr)
        return 1
    code_show, _, err_show = run_cli(db_path, password, "show", entry_path)
    if code_show != 0:
        print(f"Error: Entry not found. Use 'add' to create: {entry_path}", file=sys.stderr)
        if err_show:
            print(err_show, file=sys.stderr)
        return 1
    entry_password: Optional[str] = None
    if password_stdin:
        entry_password = sys.stdin.read().strip()
    if not entry_password:
        print("Error: --password-from-stdin required for update.", file=sys.stderr)
        return 1
    args = ["edit", "-p", entry_path]
    code, out, err = run_cli(db_path, password, *args, stdin=password + "\n" + entry_password + "\n")
    if code != 0:
        print(err or out, file=sys.stderr)
        return code
    print("Updated:", entry_path)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="KeePassXC get/add/update with check-before-add.")
    sub = parser.add_subparsers(dest="command", required=True)
    # get
    p_get = sub.add_parser("get", help="Get attribute (e.g. Password) for an entry.")
    p_get.add_argument("path_or_title", help="Entry path (Group/Env/Title) or title.")
    p_get.add_argument("--attr", default="Password", help="Attribute name (default: Password).")
    # list
    p_list = sub.add_parser("list", help="List entries (optionally under a group).")
    p_list.add_argument("group_path", nargs="?", default=None, help="Group path (e.g. MyApp/prod).")
    # add
    p_add = sub.add_parser("add", help="Add entry. Path = Group/Env/EntryTitle. Fails if exists.")
    p_add.add_argument("path", help="Full path, e.g. MyApp/prod/API Key.")
    p_add.add_argument("--username", default="api", help="Username for entry (default: api).")
    p_add.add_argument("--password-from-stdin", action="store_true", help="Read entry password from stdin.")
    # update
    p_update = sub.add_parser("update", help="Update entry password. Entry must exist.")
    p_update.add_argument("path", help="Full path to entry.")
    p_update.add_argument("--password-from-stdin", action="store_true", help="Read new password from stdin.")

    args = parser.parse_args()
    db_path = get_db_path()

    if args.command == "get":
        return cmd_get(db_path, args.path_or_title, args.attr)
    if args.command == "list":
        return cmd_list(db_path, args.group_path)
    if args.command == "add":
        return cmd_add(db_path, args.path, args.username, args.password_from_stdin)
    if args.command == "update":
        return cmd_update(db_path, args.path, args.password_from_stdin)
    return 0


if __name__ == "__main__":
    sys.exit(main())
