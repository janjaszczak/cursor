#!/usr/bin/env python3
"""Smoke tests for keep-tidy hygiene hooks. Usage: python scripts/test-hygiene-hooks.py"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
STOP_HOOK = REPO_ROOT / "hooks" / "stop_hygiene_nudge.py"
SESSION_HOOK = REPO_ROOT / "hooks" / "session_end_hygiene_audit.py"
GRIND_STATE = REPO_ROOT / "hooks" / ".grind_verify_state.json"
QG_STATE = REPO_ROOT / "hooks" / ".quality_gate_state.json"


def run_hook(script: Path, payload: dict, cwd: Path | None = None) -> dict:
    r = subprocess.run(
        [sys.executable, str(script)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=cwd or REPO_ROOT,
        timeout=30,
    )
    out = (r.stdout or "").strip()
    try:
        return {
            "json": json.loads(out) if out else {},
            "stderr": (r.stderr or "").strip(),
            "returncode": r.returncode,
        }
    except json.JSONDecodeError:
        return {"json": {}, "raw": out, "stderr": (r.stderr or "").strip(), "returncode": r.returncode}


def main() -> int:
    failed = 0

    print("Test 1: py_compile hygiene hooks")
    r = subprocess.run(
        [
            sys.executable,
            "-m",
            "py_compile",
            str(STOP_HOOK),
            str(SESSION_HOOK),
        ],
        cwd=REPO_ROOT,
    )
    if r.returncode == 0:
        print("  OK")
    else:
        print("  FAIL")
        failed += 1

    print("\nTest 2: stop_hygiene_nudge defers when grind active")
    backup_grind = GRIND_STATE.read_text(encoding="utf-8") if GRIND_STATE.is_file() else None
    GRIND_STATE.write_text(
        json.dumps({"active": True, "iteration": 1, "last_detail": "test"}),
        encoding="utf-8",
    )
    try:
        result = run_hook(STOP_HOOK, {"status": "completed", "workspace_roots": [str(REPO_ROOT)]})
        if result["json"] == {}:
            print("  OK: {}")
        else:
            print("  FAIL:", result)
            failed += 1
    finally:
        if backup_grind is None:
            if GRIND_STATE.is_file():
                GRIND_STATE.unlink()
        else:
            GRIND_STATE.write_text(backup_grind, encoding="utf-8")

    print("\nTest 3: stop_hygiene_nudge defers on aborted")
    result = run_hook(STOP_HOOK, {"status": "aborted", "workspace_roots": [str(REPO_ROOT)]})
    if result["json"] == {}:
        print("  OK: {}")
    else:
        print("  FAIL:", result)
        failed += 1

    print("\nTest 4: stop_hygiene_nudge followup on scratch clutter (temp repo)")
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        subprocess.run(["git", "init"], cwd=root, capture_output=True, check=True)
        scratch = root / "scratch_agent_test.md"
        scratch.write_text("temp", encoding="utf-8")
        # Ensure grind/qg do not defer: use empty states in hooks dir of REPO (already cleared)
        if QG_STATE.is_file() and QG_STATE.read_text(encoding="utf-8").find('"passed": false') >= 0:
            # Do not mutate real FAIL state permanently — only skip assert if QG fail would defer
            print("  SKIP: quality gate state is FAIL (would defer); clear hooks/.quality_gate_state.json to re-run")
        else:
            result = run_hook(
                STOP_HOOK,
                {"status": "completed", "workspace_roots": [str(root)]},
                cwd=root,
            )
            msg = (result["json"] or {}).get("followup_message", "")
            if "scratch_agent_test.md" in msg or "keep-tidy" in msg:
                print("  OK: followup_message mentions clutter")
            else:
                print("  FAIL:", result)
                failed += 1

    print("\nTest 5: session_end_hygiene_audit wipes allowlisted scratch")
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        agent_dir = root / ".agent-scratch"
        agent_dir.mkdir()
        (agent_dir / "x.txt").write_text("x", encoding="utf-8")
        tmp_agent = root / "tmp" / "agent-test"
        tmp_agent.mkdir(parents=True)
        (tmp_agent / "y.txt").write_text("y", encoding="utf-8")
        result = run_hook(
            SESSION_HOOK,
            {"workspace_roots": [str(root)]},
            cwd=root,
        )
        if result["json"] != {}:
            print("  FAIL stdout:", result)
            failed += 1
        elif agent_dir.exists() or tmp_agent.exists():
            print("  FAIL: scratch dirs still exist")
            failed += 1
        else:
            print("  OK: wiped + {}")

    print("\n" + ("Some tests failed." if failed else "All tests passed."))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
