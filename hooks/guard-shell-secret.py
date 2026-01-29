#!/usr/bin/env python3
"""
Cursor beforeShellExecution hook: require authorization for commands that write to .env.

Reads JSON from stdin (command). If the command appears to write to .env or similar
sensitive files, returns permission: ask. Otherwise returns permission: allow.

Output: {"permission": "allow"} or {"permission": "ask", "user_message": "...", "agent_message": "..."}
Exit: 0.
"""

from __future__ import annotations

import json
import sys


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"permission": "allow"}))
        return 0

    command = payload.get("command") or ""
    if not command:
        print(json.dumps({"permission": "allow"}))
        return 0

    # Already matched by hooks.json matcher; if we're called, treat as ask
    user_message = "This command may write secrets to a file. Confirm you want to run it."
    agent_message = (
        "The command was flagged because it may persist secrets (e.g. to .env). "
        "User authorization is required. Ask the user to confirm, then re-run if approved."
    )
    print(
        json.dumps(
            {
                "permission": "ask",
                "user_message": user_message,
                "agent_message": agent_message,
            }
        )
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print(json.dumps({"permission": "allow"}))
        sys.exit(0)
