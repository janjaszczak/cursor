#!/usr/bin/env python3
"""
Bootstrap AGENTS.md in a git repo from the global template.

Cursor loads AGENTS.md only from the open project root (not from ~/.cursor globally).
This script copies doc/templates/AGENTS.md to the repo root when missing.

Usage:
  python scripts/bootstrap-agents-md.py              # current repo, skip if exists
  python scripts/bootstrap-agents-md.py --force    # overwrite existing
  python scripts/bootstrap-agents-md.py /path/to/repo

Exit: 0 = created or already present; 1 = error.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


CURSOR_HOME = Path(__file__).resolve().parent.parent
TEMPLATE = CURSOR_HOME / "doc" / "templates" / "AGENTS.md"


def _repo_root(explicit: str | None) -> Path | None:
    if explicit:
        p = Path(explicit).resolve()
        return p if p.is_dir() else None
    try:
        r = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if r.returncode == 0 and r.stdout.strip():
            return Path(r.stdout.strip()).resolve()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return Path.cwd().resolve()


def main() -> int:
    parser = argparse.ArgumentParser(description="Bootstrap AGENTS.md in a git repo")
    parser.add_argument("repo", nargs="?", help="Repo path (default: git root or cwd)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing AGENTS.md")
    args = parser.parse_args()

    if not TEMPLATE.is_file():
        print(f"Template missing: {TEMPLATE}", file=sys.stderr)
        return 1

    root = _repo_root(args.repo)
    if not root or not root.is_dir():
        print("Could not resolve repo root", file=sys.stderr)
        return 1

    target = root / "AGENTS.md"
    if target.is_file() and not args.force:
        print(f"Already exists: {target} (use --force to overwrite)")
        return 0

    shutil.copy2(TEMPLATE, target)
    print(f"Created: {target}")
    print(f"Global fallback when missing: {CURSOR_HOME / 'AGENTS.default.md'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
