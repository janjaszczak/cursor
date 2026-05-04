#!/usr/bin/env python3
"""
Cursor beforeShellExecution hook: quality gate for risky operations.

Reads JSON from stdin (command, workspace_roots, hook_event_name). If the command
is gated (git commit/push, gh pr create/merge, npm/pnpm/yarn publish), runs
quality checks and returns allow/deny. Non-gated commands get allow.

Output: {"permission": "allow"|"deny", "user_message": "...", "agent_message": "..."}
Exit: 0 for allow; 2 for deny.
"""

from __future__ import annotations

import hashlib
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path


# Commands that trigger the quality gate (token appears anywhere in the command string)
GATED_PATTERNS = [
    r"\bgit\s+commit\b",
    r"\bgit\s+push\b",
    r"\bgh\s+pr\s+create\b",
    r"\bgh\s+pr\s+merge\b",
    r"\bnpm\s+publish\b",
    r"\bpnpm\s+publish\b",
    r"\byarn\s+publish\b",
]
GATED_RE = re.compile("|".join(f"({p})" for p in GATED_PATTERNS), re.IGNORECASE)

STATE_FILE = Path(__file__).resolve().parent / ".quality_gate_state.json"
QUALITY_GATE_SCRIPT = "scripts/quality-gate.py"


def _find_repo_with_quality_gate() -> Path | None:
    """Walk up from cwd to find a directory that contains scripts/quality-gate.py."""
    try:
        p = Path.cwd().resolve()
        for _ in range(20):
            if (p / QUALITY_GATE_SCRIPT).is_file():
                return p
            parent = p.parent
            if parent == p:
                break
            p = parent
    except (OSError, RuntimeError):
        pass
    return None


def _load_payload() -> dict:
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError:
        return {}


def _is_gated(command: str) -> bool:
    if not command or not isinstance(command, str):
        return False
    return bool(GATED_RE.search(command))


def _windows_to_wsl_path(win_path: str) -> Path:
    """Convert Windows path to WSL path so Path.is_dir()/is_file() work when hook runs in WSL."""
    s = (win_path or "").strip().replace("\\", "/")
    # C:\Users\... or C:/Users/... -> /mnt/c/Users/...
    m = re.match(r"^([a-zA-Z]):(.*)$", s)
    if m:
        drive = m.group(1).lower()
        rest = m.group(2).lstrip("/")
        return Path(f"/mnt/{drive}/{rest}")
    # \\wsl.localhost\Ubuntu\mnt\c\... or similar
    if s.lower().startswith("//wsl"):
        parts = s.split("/")
        try:
            idx = parts.index("mnt")
            if idx + 2 <= len(parts):
                return Path("/" + "/".join(parts[idx:]))
        except ValueError:
            pass
    return Path(s)


def _repo_root(workspace_roots: list) -> Path | None:
    if not workspace_roots or not workspace_roots[0]:
        return None
    raw = workspace_roots[0]
    root = Path(raw).resolve()
    if root.is_dir():
        return root
    # Cursor may pass Windows path; hook runs in WSL
    wsl = _windows_to_wsl_path(raw)
    if wsl.is_dir():
        return wsl
    return None


def _cache_key(root: Path) -> str | None:
    try:
        r = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=5,
        )
        head = (r.stdout or "").strip() if r.returncode == 0 else ""
        r2 = subprocess.run(
            ["git", "diff", "--name-only", "HEAD"],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=5,
        )
        names = (r2.stdout or "").strip() if r2.returncode == 0 else ""
        combined = f"{head}\n{names}"
        return hashlib.sha256(combined.encode()).hexdigest()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def _load_state() -> dict:
    if not STATE_FILE.is_file():
        return {}
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def _save_state(root: Path, passed: bool, summary: str, cache_key: str | None) -> None:
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "passed": passed,
                    "summary": summary,
                    "cache_key": cache_key,
                    "repo_root": str(root),
                },
                f,
                indent=2,
            )
    except OSError:
        pass


def _detect_quality_commands(root: Path) -> list[str]:
    """Return list of commands to run for quality (prefer project script, then ruff/pytest)."""
    commands: list[str] = []

    # Prefer project quality-gate script (works without ruff in PATH)
    # Try root, cwd, then walk up from cwd – hook cwd may not be repo
    bases: list[Path | None] = [root, Path.cwd()]
    walk = _find_repo_with_quality_gate()
    if walk:
        bases.append(walk)
    for base in bases:
        if not base or not base.is_dir():
            continue
        custom = base / QUALITY_GATE_SCRIPT
        if custom.is_file():
            commands.append(f"{sys.executable} {shlex.quote(str(custom.resolve()))}")
            return commands[:3]

    # package.json
    pkg = root / "package.json"
    if pkg.is_file():
        try:
            with open(pkg, encoding="utf-8") as f:
                data = json.load(f)
            scripts = data.get("scripts") or {}
            for name in ("lint", "format", "test", "test:unit", "check"):
                if name in scripts:
                    cmd = scripts[name]
                    if cmd and isinstance(cmd, str):
                        commands.append(f"npm run {name}")
                    break
            if not commands and "test" in scripts:
                commands.append("npm run test")
        except (json.JSONDecodeError, OSError):
            pass

    # pyproject.toml (ruff, pytest) – only if no quality-gate.py (ruff may not be in PATH)
    pyproject = root / "pyproject.toml"
    if pyproject.is_file():
        try:
            content = pyproject.read_text(encoding="utf-8")
            # Do NOT add "ruff check ." – ruff often not in PATH; use scripts/quality-gate.py
            if "pytest" in content or "[tool.pytest" in content:
                commands.append("pytest -q --tb=no -x")
        except OSError:
            pass

    # Makefile
    makefile = root / "Makefile"
    if makefile.is_file():
        try:
            text = makefile.read_text(encoding="utf-8")
            for target in ("lint", "test", "check", "format"):
                if re.search(rf"^\s*{re.escape(target)}\s*:", text, re.MULTILINE):
                    commands.append(f"make {target}")
                    break
        except OSError:
            pass

    return commands[:3]  # cap to avoid long runs


def _run_quality_gate(root: Path) -> tuple[bool, str]:
    """Run quality checks; return (passed, summary). Uses scripts/quality-gate.py (cross-platform)."""
    # Try root, cwd, then walk up from cwd – hook cwd may not be repo
    bases: list[Path | None] = [root, Path.cwd()]
    walk = _find_repo_with_quality_gate()
    if walk:
        bases.append(walk)
    for base in bases:
        if not base or not base.is_dir():
            continue
        custom = base / QUALITY_GATE_SCRIPT
        if custom.is_file():
            try:
                r = subprocess.run(
                    [sys.executable, str(custom)],
                    cwd=base,
                    capture_output=True,
                    text=True,
                    timeout=120,
                )
                if r.returncode != 0:
                    stderr = (r.stderr or "").strip() or (r.stdout or "").strip()
                    return False, stderr[:500] if stderr else "scripts/quality-gate.py failed"
                return True, "scripts/quality-gate.py OK"
            except subprocess.TimeoutExpired:
                return False, "Quality gate timed out (120s)"
            except FileNotFoundError:
                continue

    # Fallback: run detected stack commands
    commands = _detect_quality_commands(root)
    if not commands:
        # No checks in repo; allow (or run minimal script if present in path)
        return True, "No repo checks configured; pass"

    errors: list[str] = []
    for cmd in commands:
        try:
            r = subprocess.run(
                cmd,
                shell=True,
                cwd=root,
                capture_output=True,
                text=True,
                timeout=90,
            )
            if r.returncode != 0:
                err = (r.stderr or r.stdout or "").strip()[:300]
                errors.append(f"{cmd}: {err}")
        except subprocess.TimeoutExpired:
            errors.append(f"{cmd}: timeout")
        except Exception as e:
            errors.append(f"{cmd}: {e}")

    if errors:
        return False, "; ".join(errors)
    return True, " ".join(commands) + " OK"


def main() -> int:
    payload = _load_payload()
    command = (payload.get("command") or "").strip()
    workspace_roots = payload.get("workspace_roots") or []
    root = _repo_root(workspace_roots)

    if not _is_gated(command):
        print(json.dumps({"permission": "allow"}))
        return 0

    if not root:
        # Cannot determine repo; allow but warn
        print(
            json.dumps(
                {
                    "permission": "allow",
                    "agent_message": "Quality gate: workspace root unknown; allowed.",
                }
            )
        )
        return 0

    cache_key = _cache_key(root)
    state = _load_state()
    if (
        cache_key
        and state.get("cache_key") == cache_key
        and "passed" in state
        and state.get("repo_root") == str(root)
    ):
        if state.get("passed"):
            print(
                json.dumps(
                    {
                        "permission": "allow",
                        "agent_message": f"Quality gate: PASS (cached). {state.get('summary', '')[:80]}",
                    }
                )
            )
            return 0
        # Cached FAIL: deny
        summary = state.get("summary", "Previous run failed.")
        print(
            json.dumps(
                {
                    "permission": "deny",
                    "user_message": f"Quality gate FAIL: {summary[:200]}",
                    "agent_message": (
                        "Zatrzymałem komendę. Napraw błędy jakości (lint/test), "
                        f"uruchom: scripts/quality-gate.py lub checki z repo. Log: {summary[:150]}"
                    ),
                }
            )
        )
        return 2

    passed, summary = _run_quality_gate(root)
    _save_state(root, passed, summary, cache_key)

    if passed:
        print(
            json.dumps(
                {
                    "permission": "allow",
                    "agent_message": f"Quality gate: PASS. {summary[:80]}",
                }
            )
        )
        return 0

    print(
        json.dumps(
            {
                "permission": "deny",
                "user_message": f"Quality gate FAIL: {summary[:200]}",
                "agent_message": (
                    "Zatrzymałem komendę. Napraw błędy (lint/test), uruchom: "
                    "scripts/quality-gate.py lub komendy z repo; potem spróbuj ponownie. Log: "
                )
                + summary[:150],
            }
        )
    )
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(
            json.dumps(
                {
                    "permission": "deny",
                    "user_message": f"Quality gate hook error: {e!s}",
                    "agent_message": f"Hook failed: {e!s}. Check hooks/before_shell_quality_gate.py.",
                }
            )
        )
        sys.exit(2)
