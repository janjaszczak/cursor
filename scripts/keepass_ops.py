#!/usr/bin/env python3
"""
KeePassXC CLI helper: get, add, update entries with check-before-add.

Uses native keyring per OS. Requires ~/.cursor/keepass-db.path (no path fallbacks).
"""

from __future__ import annotations

import argparse
import os
import platform
import subprocess
import sys
from pathlib import Path
from typing import Optional


def _keepass_config_candidates() -> list[Path]:
    candidates = [Path.home() / ".cursor" / "keepass-db.path"]
    mnt = Path("/mnt/c/Users")
    if mnt.is_dir():
        for name in (os.environ.get("USER"), os.environ.get("LOGNAME")):
            if name:
                win_cfg = mnt / name / ".cursor" / "keepass-db.path"
                if win_cfg.is_file():
                    candidates.append(win_cfg)
    seen: set[Path] = set()
    out: list[Path] = []
    for p in candidates:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def get_db_path() -> str:
    if os.environ.get("KEEPASS_DB_PATH"):
        p = os.environ["KEEPASS_DB_PATH"].strip()
        if not os.path.isfile(p):
            raise FileNotFoundError(f"KEEPASS_DB_PATH nie istnieje: {p}")
        return p
    for cfg in _keepass_config_candidates():
        if not cfg.is_file():
            continue
        for line in cfg.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                if not os.path.isfile(line):
                    raise FileNotFoundError(f"Plik bazy nie istnieje: {line}")
                return line
    raise FileNotFoundError(
        "Brak ~/.cursor/keepass-db.path — agent ma poprosić użytkownika o ścieżkę do cursor.kdbx."
    )


def get_db_password() -> Optional[str]:
    if os.environ.get("KEEPASS_DB_PASSWORD"):
        return os.environ["KEEPASS_DB_PASSWORD"].strip()

    system = platform.system()
    if system == "Windows":
        ps = r"""
        try {
          Import-Module Microsoft.PowerShell.SecretStore -ErrorAction Stop
          (Get-Secret -Name KeePassXC-Cursor-DB -Vault LocalStore -AsPlainText -ErrorAction Stop)
        } catch { $null }
        """
        try:
            r = subprocess.run(
                ["powershell.exe", "-NoProfile", "-Command", ps],
                capture_output=True,
                text=True,
                timeout=15,
            )
            if r.returncode == 0 and r.stdout.strip():
                return r.stdout.strip()
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        return None

    # Linux / WSL / Darwin: secret-tool
    try:
        r = subprocess.run(
            ["secret-tool", "lookup", "service", "keepassxc", "attribute", "cursor-db"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if r.returncode == 0 and r.stdout:
            return r.stdout.strip()
    except FileNotFoundError:
        pass
    return None


def run_cli(
    db_password: str,
    *cli_args: str,
    stdin: Optional[str] = None,
) -> tuple[int, str, str]:
    cmd = ["keepassxc-cli", *cli_args]
    proc = subprocess.run(
        cmd,
        input=stdin or db_password,
        capture_output=True,
        text=True,
        timeout=30,
    )
    return proc.returncode, proc.stdout or "", proc.stderr or ""


def cmd_get(db_path: str, path_or_title: str, attr: str) -> int:
    password = get_db_password()
    if not password:
        print(
            "Error: Brak hasła bazy w natywnym keyringu. "
            "Windows: setup-keepass-keyring.ps1. Linux/WSL: setup-keepass-keyring-linux.sh",
            file=sys.stderr,
        )
        return 1
    code, out, err = run_cli(password, "show", "-a", attr, db_path, path_or_title)
    if code != 0:
        if err:
            print(err, file=sys.stderr)
        return code
    print(out.rstrip())
    return 0


def cmd_list(db_path: str, group_path: Optional[str]) -> int:
    password = get_db_password()
    if not password:
        return 1
    if group_path is None:
        code, out, err = run_cli(password, "ls", "-R", db_path)
    else:
        code, out, err = run_cli(password, "ls", "-R", db_path, group_path)
    if code != 0:
        if err:
            print(err, file=sys.stderr)
        return code
    print(out.rstrip())
    return 0


def ensure_group_exists(db_path: str, db_password: str, group_path: str) -> bool:
    parts = group_path.strip("/").split("/")
    for i in range(1, len(parts) + 1):
        parent = "/".join(parts[:i])
        code, _, _ = run_cli(db_password, "ls", db_path, parent)
        if code != 0:
            code_mk, _, err_mk = run_cli(db_password, "mkdir", db_path, parent)
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
    password = get_db_password()
    if not password:
        return 1
    if "/" not in entry_path:
        print("Error: Entry path must be Group/Env/EntryTitle.", file=sys.stderr)
        return 1
    parts = entry_path.rsplit("/", 1)
    group_path = parts[0]
    entry_title = parts[1]
    code_search, out_search, _ = run_cli(password, "search", db_path, entry_title)
    if code_search == 0 and out_search.strip():
        for line in out_search.strip().splitlines():
            if entry_path in line or entry_title in line:
                print(f"Error: Entry already exists: {entry_path}", file=sys.stderr)
                return 1
    if not ensure_group_exists(db_path, password, group_path):
        return 1
    entry_password: Optional[str] = None
    if password_stdin:
        entry_password = sys.stdin.read().strip()
    if not entry_password:
        print("Error: --password-from-stdin required for add.", file=sys.stderr)
        return 1
    code, out, err = run_cli(
        password,
        "add",
        "-u",
        username or "api",
        "-p",
        db_path,
        entry_path,
        stdin=password + "\n" + entry_password + "\n",
    )
    if code != 0:
        print(err or out, file=sys.stderr)
        return code
    print("Added:", entry_path)
    return 0


def cmd_update(db_path: str, entry_path: str, password_stdin: bool) -> int:
    password = get_db_password()
    if not password:
        return 1
    code_show, _, err_show = run_cli(password, "show", db_path, entry_path)
    if code_show != 0:
        print(f"Error: Entry not found: {entry_path}", file=sys.stderr)
        if err_show:
            print(err_show, file=sys.stderr)
        return 1
    entry_password: Optional[str] = None
    if password_stdin:
        entry_password = sys.stdin.read().strip()
    if not entry_password:
        print("Error: --password-from-stdin required for update.", file=sys.stderr)
        return 1
    code, out, err = run_cli(
        password,
        "edit",
        "-p",
        db_path,
        entry_path,
        stdin=password + "\n" + entry_password + "\n",
    )
    if code != 0:
        print(err or out, file=sys.stderr)
        return code
    print("Updated:", entry_path)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="KeePassXC get/add/update with check-before-add.")
    sub = parser.add_subparsers(dest="command", required=True)
    p_get = sub.add_parser("get", help="Get attribute for an entry.")
    p_get.add_argument("path_or_title", help="Entry path (Group/Env/Title).")
    p_get.add_argument("--attr", default="Password", help="Attribute name.")
    p_list = sub.add_parser("list", help="List entries.")
    p_list.add_argument("group_path", nargs="?", default=None)
    p_add = sub.add_parser("add", help="Add entry.")
    p_add.add_argument("path", help="Full path.")
    p_add.add_argument("--username", default="api")
    p_add.add_argument("--password-from-stdin", action="store_true")
    p_update = sub.add_parser("update", help="Update entry password.")
    p_update.add_argument("path", help="Full path.")
    p_update.add_argument("--password-from-stdin", action="store_true")

    args = parser.parse_args()
    try:
        db_path = get_db_path()
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

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
