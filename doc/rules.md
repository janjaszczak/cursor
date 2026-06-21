# Cursor Rules — per user vs per repo

Official docs: [cursor.com/docs/context/rules](https://cursor.com/docs/context/rules)

## AGENTS.md in all workspaces (limitation + fix)

Cursor **does not** load `~/.cursor/AGENTS.md` globally. `AGENTS.md` is only auto-injected from the **open project root** ([docs](https://cursor.com/docs/rules#agentsmd)).

| Mechanism | Works in every workspace? |
|-----------|-------------------------|
| `USER_RULES.txt` → User Rules | **Yes** (per user) |
| `~/.cursor/AGENTS.default.md` + User Rules pointer | **Yes** (agent reads file when repo has no AGENTS.md) |
| `<repo>/AGENTS.md` | Only in that repo |
| `AGENTS.md` at `~/.cursor` root | Only when ~/.cursor is the open workspace (causes duplicate “AGENTS” in Settings) |

### Global AGENTS fallback (implemented)

1. **[`AGENTS.default.md`](../AGENTS.default.md)** — per-user defaults at `~/.cursor/AGENTS.default.md`
2. **[`USER_RULES.txt`](../USER_RULES.txt)** — instructs agent: repo `AGENTS.md` first, else read `AGENTS.default.md`
3. **[`scripts/bootstrap-agents-md.py`](../scripts/bootstrap-agents-md.py)** — creates `<repo>/AGENTS.md` when you want Cursor auto-injection in that project

```bash
python ~/.cursor/scripts/bootstrap-agents-md.py          # current repo
python ~/.cursor/scripts/bootstrap-agents-md.py --force  # overwrite template
```

## Per user (global)

| Asset | Path |
|-------|------|
| User Rules | `USER_RULES.txt` → Settings → **Global Router** |
| AGENTS fallback | `AGENTS.default.md` |
| Subagents | `agents/` |
| Skills, commands, hooks, MCP | `skills/`, `commands/`, `hooks.json`, `mcp.json` |

## Per repo (optional)

| Asset | When |
|-------|------|
| `AGENTS.md` | Custom verify commands — bootstrap script or copy [`doc/templates/AGENTS.md`](templates/AGENTS.md) |
| `.cursor/rules/*.mdc` | Stack-specific globs only |

Config repo maintenance: [`doc/CONFIG_REPO.md`](CONFIG_REPO.md)

## Settings UI

| Entry | Source |
|-------|--------|
| `# 3.6.0 — GLOBAL USER RULES…` | User Rules (correct) |
| `AGENTS` | Project `AGENTS.md` only — delete duplicates; do **not** use `AGENTS.md` in ~/.cursor root |
| Plugin rules | `workers`, `citation-standards` |

After edits: sync User Rules from `USER_RULES.txt`, restart Cursor.

## Precedence

Team Rules → Project Rules → User Rules → repo `AGENTS.md` (overrides AGENTS.default for verify only)
