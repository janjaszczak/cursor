#!/usr/bin/env python3
"""
Minimal quality gate script — cross-platform (Windows + WSL).

Used by hooks/before_shell_quality_gate.py when no stack-specific checks exist.
Safe to run locally and in CI. Add repo-specific checks in run_checks().

Exit: 0 = pass, non-zero = fail (stderr for message).
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def run_checks(repo_root: Path) -> tuple[bool, str]:
    """
    Run quality checks. Return (passed, summary_or_error_message).
    Override or extend this for repo-specific rules.
    """
    # Optional: shellcheck on .sh scripts if available (Windows: often via WSL/Git Bash)
    shellcheck = shutil.which("shellcheck")
    if shellcheck:
        try:
            sh_files = [
                str(p)
                for p in Path(repo_root).rglob("*.sh")
                if ".git" not in p.parts and p.is_file()
            ][:20]
            for path in sh_files:
                r = subprocess.run(
                    [shellcheck, "-s", "sh", path],
                    cwd=repo_root,
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                if r.returncode != 0 and r.stderr:
                    return False, (r.stderr.strip() or r.stdout or "shellcheck failed")[:500]
        except (subprocess.TimeoutExpired, OSError):
            pass

    # No mandatory checks in this repo
    return True, "quality-gate.py OK"


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
    return 0


if __name__ == "__main__":
    sys.exit(main())
