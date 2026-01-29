# Cursor Agent Hooks

This document describes how Cursor Agent Hooks are used in this setup to enforce authorization for secret writes.

## Overview

Hooks let you observe, control, and extend the agent loop using scripts. They run before or after defined stages (tool use, shell execution, MCP execution, file edit, etc.) and receive JSON via stdin and return JSON via stdout.

**Official reference:** [Cursor Hooks](https://cursor.com/docs/agent/hooks)

## Configuration Location

- **User-level (global):** `~/.cursor/hooks.json` — scripts run from `~/.cursor/`, use paths like `./hooks/guard-secret-write.py`. Copy or symlink from this repo: `hooks.json` → `~/.cursor/hooks.json`, `hooks/` → `~/.cursor/hooks/`, and set paths in the JSON to `./hooks/...`.
- **Project-level (this repo):** `.cursor/hooks.json` — scripts run from project root; paths in JSON are `.cursor/hooks/guard-secret-write.py` etc. When this repo is the workspace, Cursor loads these hooks.

## Policy in This Setup

- **Do not** block reading files that contain secrets (e.g. `.env`, `*.kdbx`). The agent may use secrets when the user asks.
- **Require user authorization** when the agent tries to **write** secrets (e.g. creating or editing `.env`, persisting credentials to files). Operations that persist secrets outside the IDE’s ephemeral context must be explicitly approved.

## Hooks in Use

| Hook | Purpose | Script |
|------|---------|--------|
| **preToolUse** (matcher: `Write`) | Before any file write: if the target path is sensitive (e.g. `.env`, `*.pem`) and the content looks like secrets (password=, api_key=, etc.), return `decision: "deny"` or prompt for user approval | `guard-secret-write.py` |
| **beforeShellExecution** (matcher: commands writing to `.env`) | Before shell commands that write to `.env` or similar: return `permission: "ask"` so the user must approve | `guard-shell-secret.py` |
| **beforeMCPExecution** | Before MCP tools that write (e.g. memory_store, GitHub write, Shrimp update): return `permission: "ask"` with a short description | `guard-mcp-write.py` |

## Hook Script Requirements

- **Input:** JSON on stdin (structure depends on the hook; see Cursor docs).
- **Output:** JSON on stdout. Examples:
  - preToolUse: `{"decision": "allow"}` or `{"decision": "deny", "reason": "..."}` (or ask variant if supported).
  - beforeShellExecution / beforeMCPExecution: `{"permission": "allow"}` or `{"permission": "ask", "user_message": "...", "agent_message": "..."}` or `{"permission": "deny", ...}`.
- **Exit code:** `0` for allow/ask; `2` for deny (blocks the action).
- **Fail-closed:** For beforeMCPExecution, if the script crashes or times out, Cursor blocks the MCP call.

## Example hooks.json (user-level)

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "command": "./hooks/guard-secret-write.py",
        "matcher": "Write"
      }
    ],
    "beforeShellExecution": [
      {
        "command": "./hooks/guard-shell-secret.py",
        "matcher": "\\.env|>>\\s*\\.env|>\\s*\\.env|tee.*\\.env"
      }
    ],
    "beforeMCPExecution": [
      {
        "command": "./hooks/guard-mcp-write.py"
      }
    ]
  }
}
```

For project-level hooks, use `.cursor/hooks/guard-secret-write.py` etc. and ensure scripts are executable.

## Verification

After enabling hooks:

1. **Write to .env:** Ask the agent to create or edit a `.env` file with a secret — the hook should trigger and ask for approval (or deny).
2. **Read .env:** Ask the agent to read `.env` — no block; reading is allowed.
3. **MCP write:** Trigger an MCP tool that writes (e.g. memory store) — hook should ask for approval.
