#!/usr/bin/env python3
"""
Cursor sessionEnd hook: audit agent clutter and wipe allowlisted scratch dirs.

- Logs remaining clutter patterns to stderr (Hooks channel).
- Deletes ONLY contents under .agent-scratch/ and tmp/agent-*/ (allowlist).
- Never touches other paths. No followup_message (session is ending).
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

CLUTTER_BASENAME_RE = re.compile(
    r"(?i)^("
    r".*_analysis\.md|"
    r".*_notes\.md|"
    r"TEMP.*\.md|"
    r"fix-.*\.md|"
    r"debug.*\.md|"
    r"scratch.*|"
    r"tmp_.*|"
    r".*\.bak|"
    r".*\.tmp"
    r")$"
)


def _load_payload() -> dict:
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError:
        return {}


def _workspace_root(payload: dict) -> Path:
    roots = payload.get("workspace_roots") or payload.get("workspaceRoots") or []
    if isinstance(roots, list) and roots:
        return Path(str(roots[0])).resolve()
    cwd = Path.cwd().resolve()
    p = cwd
    for _ in range(20):
        if (p / ".git").exists():
            return p
        parent = p.parent
        if parent == p:
            break
        p = parent
    return cwd


def _git_untracked(root: Path) -> list[str]:
    try:
        r = subprocess.run(
            ["git", "status", "--porcelain", "-u"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return []
    if r.returncode != 0:
        return []
    paths: list[str] = []
    for line in (r.stdout or "").splitlines():
        if line.startswith("??") and len(line) >= 4:
            path = line[3:].strip().strip('"').replace("\\", "/")
            if path:
                paths.append(path)
    return paths


def _wipe_allowlisted_scratch(root: Path) -> list[str]:
    """Remove allowlisted scratch trees. Returns list of removed paths."""
    removed: list[str] = []
    scratch = root / ".agent-scratch"
    if scratch.is_dir():
        try:
            shutil.rmtree(scratch)
            removed.append(".agent-scratch/")
        except OSError as exc:
            print(f"[session_end_hygiene] failed to wipe .agent-scratch: {exc}", file=sys.stderr)

    tmp = root / "tmp"
    if tmp.is_dir():
        for child in list(tmp.iterdir()):
            if child.is_dir() and child.name.startswith("agent-"):
                rel = f"tmp/{child.name}/"
                try:
                    shutil.rmtree(child)
                    removed.append(rel)
                except OSError as exc:
                    print(f"[session_end_hygiene] failed to wipe {rel}: {exc}", file=sys.stderr)
    return removed


def main() -> None:
    payload = _load_payload()
    root = _workspace_root(payload)

    clutter = [
        p
        for p in _git_untracked(root)
        if CLUTTER_BASENAME_RE.match(Path(p).name)
        or p.startswith(".agent-scratch/")
        or p.startswith("tmp/agent-")
    ]
    if clutter:
        preview = ", ".join(clutter[:20])
        more = f" (+{len(clutter) - 20} more)" if len(clutter) > 20 else ""
        print(
            f"[session_end_hygiene] clutter still present (non-allowlist may remain): "
            f"{preview}{more}",
            file=sys.stderr,
        )

    wiped = _wipe_allowlisted_scratch(root)
    if wiped:
        print(
            f"[session_end_hygiene] wiped allowlisted scratch: {', '.join(wiped)}",
            file=sys.stderr,
        )
    else:
        print("[session_end_hygiene] no allowlisted scratch to wipe", file=sys.stderr)

    print("{}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"[session_end_hygiene] error: {exc}", file=sys.stderr)
        print("{}")
