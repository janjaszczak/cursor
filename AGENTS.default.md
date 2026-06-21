# Global agent defaults (all workspaces)

Cursor has **no official global `AGENTS.md`**. This file is the **per-user default** loaded when a project has no root `AGENTS.md`.

**Windows:** `%USERPROFILE%\.cursor\AGENTS.default.md`  
**WSL/Linux:** `~/.cursor/AGENTS.default.md`

User Rules instruct the agent to read this file at implementation start if `AGENTS.md` is missing in the open project.

---

## Default verification order

Run after implementation (first available that exists in the repo):

| Priority | Check | Command |
|----------|-------|---------|
| 1 | Quality gate | `python scripts/quality-gate.py` |
| 2 | Package lint | `npm run lint` / `pnpm lint` / `yarn lint` |
| 3 | Python lint | `ruff check .` |
| 4 | Typecheck | `npm run typecheck` / `mypy .` |
| 5 | Test | `pytest -q` / `npm run test` |
| 6 | Build | `npm run build` |

Prefer one `scripts/quality-gate.py` per repo that wraps the above.

## Definition of Done (default)

- [ ] Acceptance criteria met (cite source: plan, issue, Shrimp task)
- [ ] Verify command exited 0 (name which ran)
- [ ] No new linter/type errors in touched files
- [ ] Shrimp `verify_task` ≥80 OR verifier pass OR user sign-off

## Stop / escalate

- 3 failed verify iterations (same root error)
- No diff after 2 fix attempts
- Secrets missing from KeePass/env
- Destructive ops without explicit user confirmation

## Agent workflow

1. Resolve instructions: `<project>/AGENTS.md` if present, else this file.
2. State verify command(s) before first implementation edit.
3. Minimal diff; match repo conventions.
4. Run verify; fix until pass or stop condition.

## Per-repo override

When a project needs custom verify commands, run:

```bash
python ~/.cursor/scripts/bootstrap-agents-md.py
```

Creates `<repo>/AGENTS.md` from template; local file overrides this default.
