#!/usr/bin/env python3
"""Run quality-gate hook tests. Usage: python3 scripts/test-quality-gate-hook.py [--gated]."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HOOK = REPO_ROOT / "hooks" / "before_shell_quality_gate.py"


def run_hook(command: str, workspace_roots: list[str] | None = None) -> dict:
    payload = {"command": command, "workspace_roots": workspace_roots or [str(REPO_ROOT)]}
    r = subprocess.run(
        [sys.executable, str(HOOK)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
        timeout=130,
    )
    out = (r.stdout or "").strip()
    try:
        return json.loads(out) if out else {}
    except json.JSONDecodeError:
        return {"_raw": out, "_stderr": (r.stderr or "").strip(), "_returncode": r.returncode}


def main() -> int:
    gated_only = "--gated" in sys.argv
    failed = 0

    if not gated_only:
        # 1) Non-gated → allow
        print("Test 1: non-gated command (git status) → expect permission: allow")
        result = run_hook("git status")
        perm = result.get("permission", result.get("_raw", "?"))
        if perm == "allow":
            print("  OK:", perm)
        else:
            print("  FAIL:", result)
            failed += 1

    # 2) Gated → run gate, then allow or deny
    print("\nTest 2: gated command (git commit -m test) → run gate")
    result = run_hook("git commit -m test")
    perm = result.get("permission", result.get("_raw", "?"))
    if perm in ("allow", "deny"):
        print("  OK: permission =", perm)
        if "agent_message" in result:
            print("  agent_message:", result["agent_message"][:100])
    else:
        print("  FAIL:", result)
        failed += 1

    # 3) Stop followup (optional: only makes sense if last gate was FAIL)
    print("\nTest 3: stop_quality_gate_followup.py")
    stop_script = REPO_ROOT / "hooks" / "stop_quality_gate_followup.py"
    r = subprocess.run(
        [sys.executable, str(stop_script)],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
        timeout=5,
    )
    out = (r.stdout or "").strip()
    try:
        stop_result = json.loads(out) if out else {}
        print("  OK: output =", stop_result)
    except json.JSONDecodeError:
        print("  output (raw):", out)

    print("\n" + ("Some tests failed." if failed else "All tests passed."))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
