#!/usr/bin/env python3
"""
Cursor stop hook: continue agent loop until verification passes (grind pattern).

Reads hooks/.grind_verify_state.json. When grind mode is active and the last
verify run failed, returns followup_message so the agent iterates until PASS
or max iterations is reached.

State is written by this hook when it detects a failed verify command in the
session transcript payload, or when quality_gate_state.json shows FAIL.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


HOOKS_DIR = Path(__file__).resolve().parent
GRIND_STATE_FILE = HOOKS_DIR / ".grind_verify_state.json"
QUALITY_GATE_STATE = HOOKS_DIR / ".quality_gate_state.json"

MAX_ITERATIONS = 5

VERIFY_FAIL_PATTERNS = re.compile(
    r"(pytest.*failed|npm run test.*fail|quality gate fail|exit code [1-9]|"
    r"tests? failed|lint.*error|FAIL:|AssertionError|TypeError:)",
    re.IGNORECASE,
)

VERIFY_PASS_PATTERNS = re.compile(
    r"(pytest.*passed|All tests passed|npm run test.*ok|quality-gate\.py OK|"
    r"quality gate: PASS|tests? passed|\d+ passed)",
    re.IGNORECASE,
)

VERIFY_CMD_PATTERNS = re.compile(
    r"\b(pytest|npm run (test|lint|check|build)|python3? scripts/quality-gate\.py|"
    r"make (test|lint|check))\b",
    re.IGNORECASE,
)


def _detect_verify_success(transcript: str, qg_state: dict) -> bool:
    if VERIFY_PASS_PATTERNS.search(transcript):
        return True
    summary = (qg_state.get("summary") or "").lower()
    if qg_state.get("passed") is True and "quality-gate" in summary:
        return True
    return False


def _load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def _save_grind_state(state: dict) -> None:
    try:
        with open(GRIND_STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
    except OSError:
        pass


def _load_payload() -> dict:
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError:
        return {}


def _extract_transcript_text(payload: dict) -> str:
    parts: list[str] = []
    for key in ("transcript", "conversation", "messages", "last_output", "output"):
        val = payload.get(key)
        if isinstance(val, str):
            parts.append(val)
        elif isinstance(val, list):
            for item in val[-8:]:
                if isinstance(item, dict):
                    parts.append(str(item.get("content") or item.get("text") or ""))
                else:
                    parts.append(str(item))
    return "\n".join(parts)[-8000:]


def _detect_verify_failure(transcript: str, qg_state: dict) -> tuple[bool, str]:
    if qg_state.get("passed") is False:
        summary = (qg_state.get("summary") or "quality gate failed")[:200]
        return True, f"scripts/quality-gate.py — {summary}"

    if not transcript:
        return False, ""

    if VERIFY_CMD_PATTERNS.search(transcript) and VERIFY_FAIL_PATTERNS.search(transcript):
        m = VERIFY_FAIL_PATTERNS.search(transcript)
        snippet = (m.group(0) if m else "verify failed")[:120]
        cmd = "scripts/quality-gate.py"
        if re.search(r"pytest", transcript, re.I):
            cmd = "pytest -q --tb=short"
        elif re.search(r"npm run test", transcript, re.I):
            cmd = "npm run test"
        elif re.search(r"npm run lint", transcript, re.I):
            cmd = "npm run lint"
        return True, f"{cmd} — {snippet}"

    return False, ""


def main() -> None:
    payload = _load_payload()
    transcript = _extract_transcript_text(payload)
    qg_state = _load_json(QUALITY_GATE_STATE)
    grind = _load_json(GRIND_STATE_FILE)

    failed, detail = _detect_verify_failure(transcript, qg_state)

    if failed:
        iteration = int(grind.get("iteration") or 0) + 1
        grind = {
            "active": True,
            "iteration": iteration,
            "last_detail": detail,
        }
        _save_grind_state(grind)
    elif grind.get("active") and _detect_verify_success(transcript, qg_state) and not grind.get("last_detail"):
        _save_grind_state({"active": False, "iteration": 0})
        print("{}")
        return
    elif not grind.get("active"):
        print("{}")
        return

    iteration = int(grind.get("iteration") or 0)
    if iteration >= MAX_ITERATIONS:
        _save_grind_state({"active": False, "iteration": 0})
        msg = (
            f"STOP: {MAX_ITERATIONS} iteracji verify bez sukcesu. "
            f"Ostatni błąd: {grind.get('last_detail', detail)[:150]}. "
            "Zatrzymaj pętlę, zdiagnozuj blocker (debugger/troubleshooting-rca) "
            "i poproś użytkownika o decyzję."
        )
        print(json.dumps({"followup_message": msg}))
        return

    detail = grind.get("last_detail") or detail
    msg = (
        f"Verify FAIL (iteracja {iteration}/{MAX_ITERATIONS}). "
        f"Napraw błąd i uruchom ponownie weryfikację. Szczegóły: {detail[:200]}. "
        "Nie kończ zadania dopóki verify nie przejdzie (exit 0)."
    )
    print(json.dumps({"followup_message": msg}))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("{}")
