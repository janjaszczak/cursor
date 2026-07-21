#!/usr/bin/env python3
"""Context7 MCP launcher: load CONTEXT7_API_KEY from ~/.cursor/.env, exec stdio server."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def cursor_config_dirs() -> list[Path]:
    dirs: list[Path] = []
    env_dir = os.environ.get("CURSOR_CONFIG_DIR", "").strip()
    if env_dir:
        dirs.append(Path(env_dir))
    dirs.append(Path.home() / ".cursor")
    user = os.environ.get("USER") or os.environ.get("USERNAME")
    if user:
        dirs.append(Path(f"/mnt/c/Users/{user}/.cursor"))
    seen: set[str] = set()
    out: list[Path] = []
    for d in dirs:
        key = str(d)
        if key in seen:
            continue
        seen.add(key)
        out.append(d)
    return out


def load_dotenv_if_needed() -> None:
    key = os.environ.get("CONTEXT7_API_KEY", "").strip()
    if key and key not in ("CHANGE_ME", "<SET_FROM_KEEPASS>"):
        return

    env_path = next(
        (d / ".env" for d in cursor_config_dirs() if (d / ".env").is_file()),
        None,
    )
    if env_path is None:
        return

    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, value = line.split("=", 1)
        k = k.strip()
        value = value.strip().strip('"').strip("'")
        if not k:
            continue
        if k in os.environ and os.environ[k].strip():
            continue
        os.environ[k] = value


def main() -> None:
    load_dotenv_if_needed()
    api_key = os.environ.get("CONTEXT7_API_KEY", "").strip()
    if not api_key or api_key in ("CHANGE_ME", "<SET_FROM_KEEPASS>"):
        log(
            "ERROR: CONTEXT7_API_KEY is not set. "
            "Add it to ~/.cursor/.env (from KeePass: API Keys/Context7)."
        )
        sys.exit(1)

    npx = shutil.which("npx") or shutil.which("npx.cmd")
    if not npx:
        log("ERROR: npx not found on PATH (install Node.js 18+)")
        sys.exit(1)

    args = [npx, "-y", "@upstash/context7-mcp", "--api-key", api_key]
    log("Exec @upstash/context7-mcp (stdio)")
    rc = subprocess.call(args, stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr)
    sys.exit(rc)


if __name__ == "__main__":
    main()
