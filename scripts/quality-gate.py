#!/usr/bin/env python3
"""
Quality gate for ~/.cursor config repo — cross-platform (Windows + WSL).

Validates config JSON, hook scripts, and optional shellcheck on .sh files.
Used by hooks/before_shell_quality_gate.py before commit/push/PR.

Exit: 0 = pass, non-zero = fail (message on stderr).
"""

from __future__ import annotations

import json
import os
import py_compile
import shutil
import subprocess
import sys
from pathlib import Path


CONFIG_JSON_FILES = (
    "hooks.json",
    "cli-config.json",
    "mcp.json",
)

HOOKS_DIR = Path("hooks")


def _check_config_json(repo_root: Path) -> tuple[bool, str]:
    errors: list[str] = []
    for name in CONFIG_JSON_FILES:
        path = repo_root / name
        if not path.is_file():
            errors.append(f"missing {name}")
            continue
        try:
            with open(path, encoding="utf-8") as f:
                json.load(f)
        except json.JSONDecodeError as e:
            errors.append(f"{name}: invalid JSON ({e})")
    if errors:
        return False, "; ".join(errors)
    return True, "config JSON OK"


def _check_hooks_json_entries(repo_root: Path) -> tuple[bool, str]:
    path = repo_root / "hooks.json"
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        return False, f"hooks.json: {e}"

    hooks = data.get("hooks") or {}
    for hook_name, entries in hooks.items():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            cmd = (entry or {}).get("command") or ""
            if not cmd:
                continue
            # Resolve script path from command (e.g. "python3 hooks/foo.py")
            parts = cmd.replace("\\", "/").split()
            for part in parts:
                if part.endswith(".py") and "hooks/" in part.replace("\\", "/"):
                    rel = part.split("hooks/", 1)[-1]
                    script = repo_root / "hooks" / rel
                    if not script.is_file():
                        return False, f"hooks.json references missing script: {script}"
    return True, "hooks.json scripts OK"


def _check_hook_scripts(repo_root: Path) -> tuple[bool, str]:
    hooks_path = repo_root / HOOKS_DIR
    if not hooks_path.is_dir():
        return False, "hooks/ directory missing"
    py_files = sorted(hooks_path.glob("*.py"))
    if not py_files:
        return False, "no hook scripts in hooks/"
    for script in py_files:
        try:
            py_compile.compile(str(script), doraise=True)
        except py_compile.PyCompileError as e:
            return False, f"{script.name}: {e}"
    return True, f"py_compile OK ({len(py_files)} hooks)"


def _check_user_rules(repo_root: Path) -> tuple[bool, str]:
    """Global rules live in USER_RULES.txt (sync to Settings → User Rules)."""
    path = repo_root / "USER_RULES.txt"
    if not path.is_file():
        return False, "missing USER_RULES.txt"
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        return False, f"USER_RULES.txt: {e}"

    required_markers = (
        "AGENTIC LOOP",
        "COVE",
        "SKILL CATALOG",
        "Global Router",
        "AGENTS.default.md",
    )
    missing = [m for m in required_markers if m not in text]
    if missing:
        return False, f"USER_RULES.txt missing sections: {', '.join(missing)}"

    if len(text.splitlines()) < 40:
        return False, "USER_RULES.txt too short (incomplete global rules?)"

    default_agents = repo_root / "AGENTS.default.md"
    if not default_agents.is_file():
        return False, "missing AGENTS.default.md (global AGENTS fallback)"

    return True, "USER_RULES.txt + AGENTS.default.md OK"


def _check_shellcheck(repo_root: Path) -> tuple[bool, str]:
    shellcheck = shutil.which("shellcheck")
    if not shellcheck:
        return True, "shellcheck skipped (not in PATH)"
    sh_files = [
        p
        for p in repo_root.rglob("*.sh")
        if ".git" not in p.parts and "node_modules" not in p.parts and p.is_file()
    ][:25]
    for path in sh_files:
        try:
            r = subprocess.run(
                [shellcheck, "-s", "sh", str(path)],
                cwd=repo_root,
                capture_output=True,
                text=True,
                timeout=15,
            )
            if r.returncode != 0:
                err = (r.stderr or r.stdout or "shellcheck failed").strip()[:400]
                return False, f"{path.name}: {err}"
        except (subprocess.TimeoutExpired, OSError) as e:
            return False, f"shellcheck {path.name}: {e}"
    return True, "shellcheck OK"


def run_checks(repo_root: Path) -> tuple[bool, str]:
    steps = (
        _check_config_json,
        _check_hooks_json_entries,
        _check_hook_scripts,
        _check_user_rules,
        _check_shellcheck,
    )
    summaries: list[str] = []
    for step in steps:
        ok, msg = step(repo_root)
        summaries.append(msg)
        if not ok:
            return False, msg
    return True, "; ".join(summaries)


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    if not repo_root.is_dir():
        print("quality-gate: repo root is not a directory", file=sys.stderr)
        return 1
    os.chdir(repo_root)

    passed, msg = run_checks(repo_root)
    if not passed:
        print(msg, file=sys.stderr)
        return 1
    print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
