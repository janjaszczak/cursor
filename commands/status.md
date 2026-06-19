# /status — Project status snapshot (read-only)

You are in **STATUS** mode. Goal: report where the project stands and what should happen next — **without** editing files, switching modes, or starting work.

## 0) Capability check
Identify available toolsets (use only what exists; no error loops):
- Shrimp: `list_tasks`, `query_task`, `get_task_detail`
- Neo4j memory: `search_memories`, `find_memories_by_name`
- GitHub MCP: PR/checks/issues (optional)
- Shell: `git`, `gh` (optional)

## 1) Resolve context
- `PROJECT_ROOT` = `git rev-parse --show-toplevel` (if not a git repo, use workspace root)
- `PROJECT_NAME` = basename of `PROJECT_ROOT`
- `BRANCH` = current git branch (if available)

## 2) Collect evidence (parallel where possible)

### 2.1 Shrimp tasks (primary backlog)
If Shrimp is available:
1. `list_tasks` with `status: "in_progress"`
2. `list_tasks` with `status: "pending"`
3. If any task looks relevant, `get_task_detail` for the top candidate(s)

### 2.2 Git working tree
- `git status --short --branch`
- `git log -3 --oneline` (recent momentum)
- Note: uncommitted WIP, untracked files, branch ahead/behind

### 2.3 Memory (continuity)
If memory MCP is available:
- `search_memories` with query: `"${PROJECT_NAME}" next task blocked in_progress`
- Return only actionable observations (paths, decisions, blockers)

### 2.4 Repo signals (lightweight)
- Scan for explicit TODOs only if Shrimp is empty: `README*`, `docs/`, open `gh issue list` (if gh available)
- Do **not** deep-scan the whole repo

### 2.5 CI / PR (optional)
If GitHub MCP or `gh` is available and cheap:
- Open PR for current branch? Failing checks?
- Mention only if it blocks the next task

## 3) Synthesize next-task recommendation
Priority order:
1. **Resume** `in_progress` Shrimp task (if deps satisfied)
2. **Next** `pending` Shrimp task with all dependencies completed
3. **WIP** implied by git (uncommitted work on a feature branch) — finish or stash?
4. **Memory** suggested next step
5. **Repo** TODO / issue
6. If still unclear: state **AMBIGUOUS** and list 2–3 options (no guessing)

## 4) Output format (concise)

```text
## Project status — <PROJECT_NAME> (<BRANCH>)

### Snapshot
- Shrimp: <N in_progress> / <N pending> / <N completed> (or "unavailable")
- Git: <one-line summary>
- Memory: <hit | none>
- CI/PR: <ok | failing | n/a>

### Recommended next task
- **Task:** <name or description>
- **Source:** Shrimp | Git WIP | Memory | Issue | Inferred
- **Why now:** <1 sentence>
- **Suggested mode:** PLAN | DEBUG | ASK | MULTITASK | AGENT
- **Skills to activate:** <0–3 skill names or "none">

### Blockers / risks
- <bullet or "none">

### If you want to start
Run `/next` (or type **START** in chat after `/next`).
```

## 5) Hard constraints
- **No** file edits, commits, mode switches, or subagent launches
- **No** Shrimp `execute_task` / `update_task`
- Internal CoVe for non-trivial synthesis (3 questions max); do not expose CoVe steps
- Max 25 lines in the body unless user asked for detail
