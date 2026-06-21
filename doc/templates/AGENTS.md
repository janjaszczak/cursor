# AGENTS.md — optional per-repo supplement

**Global behavior is per user:** [`USER_RULES.txt`](../../USER_RULES.txt) + [`AGENTS.default.md`](../../AGENTS.default.md) when this repo has no `AGENTS.md`.

Bootstrap into a repo (Cursor auto-loads root `AGENTS.md`):

```bash
python ~/.cursor/scripts/bootstrap-agents-md.py
```

## Project

- **Name:** `<PROJECT_NAME>`
- **Stack:** `<e.g. FastAPI + Next.js, vanilla-web, Python CLI>`
- **Entrypoints:** `<e.g. backend/main.py, frontend/app/page.tsx>`

## Verification commands

Run these after implementation (in order). All must exit 0 before marking done.

| Check | Command | Notes |
|-------|---------|-------|
| Quality gate | `python scripts/quality-gate.py` | Cross-platform; used by Cursor hooks |
| Lint | `<e.g. npm run lint / ruff check .>` | |
| Typecheck | `<e.g. npm run typecheck / mypy .>` | if applicable |
| Test | `<e.g. pytest -q / npm run test>` | |
| Build | `<e.g. npm run build>` | if applicable |

Prefer a single `scripts/quality-gate.py` that runs the subset above for this repo.

## Definition of Done

A task is complete when **all** are true:

- [ ] Acceptance criteria from plan/issue/Shrimp task are met (cite which)
- [ ] `scripts/quality-gate.py` exits 0 (or equivalent verify commands above)
- [ ] No new linter/type errors in touched files
- [ ] Shrimp `verify_task` ≥80 OR verifier subagent pass OR explicit user sign-off
- [ ] Docs updated if behavior/API changed

## Stop / escalate when

- 3 failed verify iterations with the same root error
- No file diff after 2 fix attempts (no-progress)
- Needs secrets not available in KeePass / env
- CI red on `main` / production deploy required
- Destructive ops (migration, mass delete, force push) — get user confirmation first

## Context hints

- **Canonical docs:** `docs/` or `README.md`
- **Do not edit:** `<paths>`
- **Test focus:** `<e.g. tests/unit, tests/e2e>`

## Agent workflow

1. Read this file + relevant code before editing.
2. State verify command(s) before first implementation edit.
3. Minimal diff; match existing conventions.
4. Run verify; fix until pass or hit stop conditions above.
