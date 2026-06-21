# Config repo maintenance (~/.cursor workspace only)

Not loaded by Cursor as a rule. Global behavior → [`USER_RULES.txt`](../USER_RULES.txt) in Settings → User Rules.

## Verification

| Check | Command |
|-------|---------|
| Quality gate | `python scripts/quality-gate.py .` |
| Hook smoke test | `python scripts/test-quality-gate-hook.py` |

## Do not edit manually

- `.env`, auth/privacy cache fields in `cli-config.json`

## Application projects

Optional: copy [`templates/AGENTS.md`](templates/AGENTS.md) or run `python scripts/bootstrap-agents-md.py` in app repo.

Global fallback for all other workspaces: [`AGENTS.default.md`](../AGENTS.default.md) (via User Rules).
