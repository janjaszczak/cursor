# Cursor Agent Hooks

Hooks observe, control, and extend the agent loop. Scripts receive JSON on stdin and return JSON on stdout.

**Official reference:** [Cursor Hooks](https://cursor.com/docs/agent/hooks)

## Configuration

- **User-level:** `~/.cursor/hooks.json` — scripts run from `~/.cursor/`; paths like `hooks/guard-secret-write.py`.
- **Project-level:** `<repo>/.cursor/hooks.json` — paths relative to project root.

Active config: [`hooks.json`](../hooks.json) at repo root (same as user `~/.cursor` when this is the config source of truth).

## Policy

- **Read** secrets (`.env`, `*.kdbx`) — allowed when user requests.
- **Write** secrets to disk — requires approval (`guard-secret-write.py`).
- **Commit/push/PR/publish** — quality gate must pass (`before_shell_quality_gate.py`).
- **MCP writes** — ask user (`guard-mcp-write.py`).
- **Stop** — follow-up when verify/quality gate failed (grind loop up to 5 iterations); then hygiene nudge if clutter remains (skill `keep-tidy`).
- **sessionEnd** — audit + wipe allowlisted scratch (`.agent-scratch/`, `tmp/agent-*/` only).

## Hooks in use

| Hook | Script | Purpose |
|------|--------|---------|
| **preToolUse** (matcher: `Write`) | `hooks/guard-secret-write.py` | Block or deny writes to sensitive paths with secret-like content |
| **beforeShellExecution** | `hooks/before_shell_quality_gate.py` | Run quality checks before `git commit`, `git push`, `gh pr create/merge`, `npm/pnpm/yarn publish` |
| **beforeMCPExecution** | `hooks/guard-mcp-write.py` | `permission: ask` for MCP tools that write (memory, GitHub, Shrimp, etc.) |
| **stop** | `hooks/stop_quality_gate_followup.py` | Remind agent if last quality gate = FAIL |
| **stop** | `hooks/grind_until_verify.py` | Continue loop with `followup_message` until verify passes or max 5 iterations |
| **stop** (`loop_limit: 2`) | `hooks/stop_hygiene_nudge.py` | Nudge agent to remove orphan/scratch clutter (defers if grind/QG fail active) |
| **sessionEnd** | `hooks/session_end_hygiene_audit.py` | Log clutter; wipe `.agent-scratch/` and `tmp/agent-*/` only |

Other Cursor events exist (`sessionStart`, `postToolUse`, `afterFileEdit`, …) but are not registered here unless needed. Continuous tidy rules: skill [`keep-tidy`](../skills/keep-tidy/SKILL.md). Deep audit: [`/cleanup`](../commands/cleanup.md).

State files (gitignored): `hooks/.quality_gate_state.json`, `hooks/.grind_verify_state.json`.

## Hook I/O

- **preToolUse:** `{"decision": "allow"}` or `{"decision": "deny", "reason": "..."}`
- **beforeShellExecution / beforeMCPExecution:** `{"permission": "allow"|"ask"|"deny", ...}`
- **stop:** `{}` or `{"followup_message": "..."}`
- **sessionEnd:** `{}` (fire-and-forget; log on stderr)
- Exit code `2` = deny (where applicable). MCP hook fail-closed on crash.

## Example hooks.json

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {"command": "hooks/guard-secret-write.py", "matcher": "Write"}
    ],
    "beforeShellExecution": [
      {"command": "python3 hooks/before_shell_quality_gate.py"}
    ],
    "beforeMCPExecution": [
      {"command": "hooks/guard-mcp-write.py"}
    ],
    "stop": [
      {"command": "python3 hooks/stop_quality_gate_followup.py"},
      {"command": "python3 hooks/grind_until_verify.py"},
      {"command": "python3 hooks/stop_hygiene_nudge.py", "loop_limit": 2}
    ],
    "sessionEnd": [
      {"command": "python3 hooks/session_end_hygiene_audit.py"}
    ]
  }
}
```

On Windows without `python3` in PATH, use `python` in `hooks.json`.

## Quality gate

See [quality-gate.md](quality-gate.md). Per-repo checks live in `scripts/quality-gate.py` in each project (including this config repo).

## Verification

```bash
python scripts/test-quality-gate-hook.py
python scripts/test-hygiene-hooks.py
```

Manual checks:

1. Edit `.env` with agent → secret write hook triggers.
2. `git commit` with failing lint → beforeShellExecution deny.
3. After failed verify in agent session → stop hook returns grind followup (max 5).
4. Leave untracked `scratch_x.md` → stop hygiene nudge returns followup (when grind/QG idle).
5. Close chat with `.agent-scratch/` present → sessionEnd wipes allowlisted scratch.
