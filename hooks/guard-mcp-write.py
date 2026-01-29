#!/usr/bin/env python3
"""
Cursor beforeMCPExecution hook: require authorization for MCP tools that write data.

Reads JSON from stdin (tool_name, tool_input). If the tool is a known write tool
(memory_store, create_entities, GitHub write, Shrimp update, etc.), returns permission: ask.
Otherwise returns permission: allow.

Output: {"permission": "allow"} or {"permission": "ask", "user_message": "...", "agent_message": "..."}
Exit: 0 for allow/ask; 2 for deny. Fail-closed: on error, output deny and exit 2.
"""

from __future__ import annotations

import json
import sys


WRITE_TOOLS = frozenset({
    "memory_store",
    "create_entities",
    "add_observations",
    "create_relations",
    "execute_task",
    "verify_task",
    "split_tasks",
    "plan_task",
    "create_entities",
    "add_observations",
    "create_relations",
    "run_workflow",
    "push",
    "merge",
    "create",
    "update",
    "post",
    "put",
    "patch",
    "delete",
})


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"permission": "deny", "user_message": "Hook could not parse input."}))
        return 2

    tool_name = (payload.get("tool_name") or "").strip().lower()
    if not tool_name:
        print(json.dumps({"permission": "allow"}))
        return 0

    # Normalize: tool names may be "memory_store" or "memory/store"
    tool_name_flat = tool_name.replace("/", "_").replace("-", "_")
    if tool_name_flat in WRITE_TOOLS:
        pass
    elif any(w in tool_name_flat for w in ("store", "create", "add", "write", "push", "merge", "update", "post", "put", "patch", "delete", "execute_task", "verify_task", "split_tasks")):
        # Likely a write tool
        pass
    else:
        print(json.dumps({"permission": "allow"}))
        return 0

    user_message = f"MCP tool '{tool_name}' can write or change data. Confirm you want to run it."
    agent_message = (
        f"The tool '{tool_name}' was flagged as a write operation. "
        "User authorization is required. Summarize the intended action and ask the user to confirm."
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
        print(json.dumps({"permission": "deny", "user_message": "Hook failed."}))
        sys.exit(2)
