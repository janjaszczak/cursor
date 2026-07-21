#!/usr/bin/env python3
"""
Cursor stop hook: nudge the agent to clean orphan/scratch clutter before finishing.

Scans git status (untracked) for known agent-clutter patterns and non-empty
allowlisted scratch dirs. Returns followup_message when clutter remains.

Defers when: status is aborted/error, grind verify is active, or quality gate
last failed (those stop hooks own the follow-up loop).
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

HOOKS_DIR = Path(__file__).resolve().parent
GRIND_STATE_FILE = HOOKS_DIR / ".grind_verify_state.json"
QUALITY_GATE_STATE = HOOKS_DIR / ".quality_gate_state.json"
MAX_LIST = 15

# Paths relative to repo root (posix-style matching)
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

ROOT_ADHOC_RE = re.compile(
    r"(?i)^(tmp_|debug_|scratch_|fix_).*\.(py|ps1|sh|js|ts|md)$"
)


def _load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


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
        if len(line) < 4:
            continue
        # Untracked only (??); ignore staged/modified tracked files
        if not line.startswith("??"):
            continue
        path = line[3:].strip().strip('"')
        if path:
            paths.append(path.replace("\\", "/"))
    return paths


def _is_clutter_path(rel: str) -> bool:
    name = Path(rel).name
    if CLUTTER_BASENAME_RE.match(name):
        return True
    # Root-level ad-hoc only (no slash in path)
    if "/" not in rel.rstrip("/") and ROOT_ADHOC_RE.match(name):
        return True
    if rel.startswith(".agent-scratch/") or rel == ".agent-scratch":
        return True
    if rel.startswith("tmp/agent-") or re.match(r"^tmp/agent-[^/]+/?$", rel):
        return True
    return False


def _scratch_dir_hits(root: Path) -> list[str]:
    hits: list[str] = []
    scratch = root / ".agent-scratch"
    if scratch.is_dir() and any(scratch.iterdir()):
        hits.append(".agent-scratch/ (non-empty)")
    tmp = root / "tmp"
    if tmp.is_dir():
        for child in tmp.iterdir():
            if child.is_dir() and child.name.startswith("agent-") and any(child.iterdir()):
                hits.append(f"tmp/{child.name}/ (non-empty)")
    return hits


def _should_defer(payload: dict) -> bool:
    status = str(payload.get("status") or "completed").lower()
    if status in ("aborted", "error"):
        return True
    grind = _load_json(GRIND_STATE_FILE)
    if grind.get("active"):
        return True
    qg = _load_json(QUALITY_GATE_STATE)
    if qg and qg.get("passed") is False:
        return True
    return False


def main() -> None:
    payload = _load_payload()
    if _should_defer(payload):
        print("{}")
        return

    root = _workspace_root(payload)
    clutter = [p for p in _git_untracked(root) if _is_clutter_path(p)]
    clutter.extend(_scratch_dir_hits(root))
    # Dedupe preserving order
    seen: set[str] = set()
    unique: list[str] = []
    for item in clutter:
        if item not in seen:
            seen.add(item)
            unique.append(item)

    if not unique:
        print("{}")
        return

    listed = unique[:MAX_LIST]
    more = len(unique) - len(listed)
    lines = "\n".join(f"- {p}" for p in listed)
    extra = f"\n- …and {more} more" if more > 0 else ""
    msg = (
        "keep-tidy: leftover agent clutter detected after this turn. "
        "Delete or merge into canonical docs/scripts (skill keep-tidy), "
        "then continue. Prefer `.agent-scratch/` wipe for session scratch; "
        "use /cleanup only if MERGE target is unclear.\n\n"
        f"{lines}{extra}"
    )
    print(json.dumps({"followup_message": msg}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
