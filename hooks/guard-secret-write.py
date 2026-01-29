#!/usr/bin/env python3
"""
Cursor preToolUse (Write) hook: require authorization before writing secrets to files.

Reads JSON from stdin. If the write target is a sensitive path (e.g. .env, *.pem)
and the content looks like secrets (password=, api_key=, etc.), returns decision: deny
with a reason. Otherwise returns decision: allow.

Output: {"decision": "allow"} or {"decision": "deny", "reason": "..."}
Exit: 0 for allow, 2 for deny.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


SENSITIVE_PATH_PATTERNS = (
    r"\.env",
    r"\.env\.",
    r"\.env$",
    r"secret",
    r"credential",
    r"\.pem$",
    r"\.key$",
    r"config/local",
)
SECRET_CONTENT_PATTERNS = (
    r"password\s*=",
    r"api_key\s*=",
    r"apikey\s*=",
    r"secret\s*=",
    r"token\s*=",
    r"Authorization\s*:",
    r"Bearer\s+",
)


def is_sensitive_path(file_path: str) -> bool:
    path_lower = file_path.lower().replace("\\", "/")
    return any(re.search(p, path_lower, re.IGNORECASE) for p in SENSITIVE_PATH_PATTERNS)


def has_secret_like_content(text: str) -> bool:
    if not text or not text.strip():
        return False
    return any(re.search(p, text, re.IGNORECASE) for p in SECRET_CONTENT_PATTERNS)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"decision": "allow"}))
        return 0

    tool_input = payload.get("tool_input") or {}
    if isinstance(tool_input, str):
        try:
            tool_input = json.loads(tool_input)
        except json.JSONDecodeError:
            print(json.dumps({"decision": "allow"}))
            return 0

    file_path = tool_input.get("path") or tool_input.get("file_path") or ""
    edits = tool_input.get("edits") or tool_input.get("new_string") or []
    if isinstance(edits, str):
        content_to_check = edits
    elif isinstance(edits, list):
        content_to_check = " ".join(
            (e.get("new_string") or "") for e in edits if isinstance(e, dict)
        )
    else:
        content_to_check = ""

    if not file_path:
        print(json.dumps({"decision": "allow"}))
        return 0

    if not is_sensitive_path(file_path):
        print(json.dumps({"decision": "allow"}))
        return 0

    if not has_secret_like_content(content_to_check):
        print(json.dumps({"decision": "allow"}))
        return 0

    reason = (
        "Writing secrets to a file requires explicit user authorization. "
        "Confirm you want to persist this sensitive data, then retry."
    )
    print(json.dumps({"decision": "deny", "reason": reason}))
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)
