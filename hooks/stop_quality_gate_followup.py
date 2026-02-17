#!/usr/bin/env python3
"""
Cursor stop hook: follow-up message when quality gate last failed.

Reads state from hooks/.quality_gate_state.json. If last result was FAIL,
returns {"followup_message": "..."} so the user/agent gets a reminder.
Otherwise returns {}.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


STATE_FILE = Path(__file__).resolve().parent / ".quality_gate_state.json"


def main() -> None:
    if not STATE_FILE.is_file():
        print("{}")
        return
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            state = json.load(f)
    except (json.JSONDecodeError, OSError):
        print("{}")
        return

    if state.get("passed") is True:
        print("{}")
        return

    summary = (state.get("summary") or "Błędy jakości.")[:150]
    msg = (
        "Quality gate nie przeszedł. Uruchom: scripts/quality-gate.py "
        "(lub napraw błędy z logu) i spróbuj ponownie. Skrót: " + summary
    )
    print(json.dumps({"followup_message": msg}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
