# /next — Status → mode → start next task

You are in **NEXT** mode. Goal: (1) check project status, (2) pick the right next task, (3) switch to the appropriate working mode, (4) **begin execution** immediately when the next task is clear.

For status-only (no execution), user should run `/status` instead.

## 0) Capability check
Same as `/status`: Shrimp, memory MCP, GitHub MCP, shell — use only what exists.

## 1) Status phase (reuse `/status` logic)
Run the evidence collection from `commands/status.md` sections 1–3.
Produce a **short** status block (≤15 lines) before acting.

If the user message contains **`status only`** or **`tylko status`**, stop after the status block (same as `/status`).

## 2) Choose next task
Use the priority order from `/status` section 3.

### Ambiguity gate
- **One clear winner** → proceed to section 3 automatically
- **Multiple viable options** → list max 3 with 1-line tradeoff each; ask user to pick **1**, **2**, or **3** (or paste task ID). **Do not** start destructive work until chosen
- **No task found** → propose creating one:
  - offer `plan_task` + `split_tasks` (Shrimp) **or**
  - ask one focused question: "What is the single outcome you want in this session?"

## 3) Mode router (pick exactly one)

| Mode | When | How to activate |
|------|------|-----------------|
| **PLAN** | Multi-file change, migration, architecture, risky/irreversible ops, unclear scope | Call **SwitchMode** → `plan`. Activate **plan-as-contract** (and **high-risk-review** if security/infra/data-loss). Produce plan with checkboxes; wait for approval unless user said "just do it" / "zrób od razu" |
| **DEBUG** | Bug, regression, failing tests, "nie działa", stack traces | Stay in **Agent**. Activate **troubleshooting-rca**. Prefer **debugger** subagent for stubborn failures. No feature scope creep |
| **ASK** | Understanding code, review, comparison, "how does X work", no code changes requested | **Read-only**: no Write/StrReplace/Delete, no commits, no Shrimp status changes. Answer with repo evidence |
| **MULTITASK** | ≥2 independent workstreams (e.g. backend + frontend, parallel investigations) | Stay in **Agent**. Launch **Task** subagents with `run_in_background: true` where appropriate. Track in Shrimp if available |
| **AGENT** | Single focused implementation, small fix, docs tweak | Stay in **Agent**. Activate minimum skills from USER_RULES activation router |

### Mode overrides
User may force mode in the same message:
- `plan` / `debug` / `ask` / `multitask` / `agent` (Polish: `planowanie`, `debug`, `pytanie`, `wielozadaniowy`)
- Forced mode wins over router

### Cursor limitation (be explicit once per session)
- **SwitchMode** supports only `plan` and `agent`
- **ASK** and **DEBUG** are behavioral contracts (read-only / RCA), not UI mode switches
- Tell user to switch Cursor UI to Ask/Debug manually **only** if they explicitly want the IDE mode

## 4) Execution phase (start now)

### 4.1 Shrimp-backed task
If next task has a Shrimp `taskId`:
1. `get_task_detail` if not already loaded
2. `execute_task` with that `taskId` — follow returned guidance step by step
3. Activate **mcp-shrimp-execution-loop** for multi-step work
4. On completion: `verify_task` + `update_task` status

### 4.2 Non-Shrimp task
1. Resolve AGENTS: read `<repo-root>/AGENTS.md` if present; else read `~/.cursor/AGENTS.default.md`.
2. If neither exists, warn and offer `python ~/.cursor/scripts/bootstrap-agents-md.py`.
3. Activate the primary domain skill (repo-grounding first if touching this repo)
4. State acceptance criteria in 1–3 bullets **and name verify command(s)** before the first file edit
5. When scope is known: use `@Branch` and tag at most 3 key files; otherwise let agent search
6. Execute minimal first step immediately (read files, run failing test, reproduce bug — **do not** stop at "you should…")
7. Run verification when a fix/change is in scope

### 4.3 Skills activation (minimum set)
Follow USER_RULES skill selection policy:
- ONE primary domain skill
- Add process skill only if gate matches (troubleshooting-rca, plan-as-contract, task-planning-shrimp, etc.)

### 4.4 Subagent hints
| Situation | Subagent |
|-----------|----------|
| Test failures | test-runner |
| Security-sensitive change | security-auditor |
| Python API work | backend-specialist |
| Infra/deploy | devops |
| Done with implementation | verifier |

## 5) Output contract (first reply)

```text
## /next — <PROJECT_NAME>

**Status:** <1 line>
**Next task:** <name> (source: Shrimp|…)
**Mode:** <PLAN|DEBUG|ASK|MULTITASK|AGENT> — <why 1 line>
**Skills:** <list>

---
<immediate action taken or plan presented>
```

Then continue working in the chosen mode without asking "shall I proceed?" unless blocked by ambiguity or approval gate (PLAN / destructive ops).

## 6) Hard constraints
- Do not run destructive git ops without explicit user request
- PLAN mode: no implementation until approval (unless "just do it")
- ASK mode: strictly read-only
- DEBUG mode: state root cause hypothesis + verification step before large refactors
- Prefer evidence over invention; mark UNCERTAIN with shortest verification path

## 7) Optional memory
After completing a session milestone, propose `/save_memory` with task outcome (do not auto-save)
