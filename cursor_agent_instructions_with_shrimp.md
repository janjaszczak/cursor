# Cursor Agent User Rules (Correctness-First)
## Shrimp + Neo4j Memory + Playwright + DuckDuckGo + GitHub + Grafana

This file defines **hard operational rules** for LLM Agents used in Cursor IDE.
Primary objective: **correctness over speed**, **zero silent regressions**, **predictable execution**.

Stack assumed (MCP):
- Shrimp Task Manager (planning, execution, reflection)
- Neo4j Memory Server (persistent architectural & decision memory)
- Playwright MCP (deterministic browser automation)
- DuckDuckGo MCP (web research)
- GitHub MCP / github-mcp-custom (repo & PR operations)
- Grafana MCP (logs, metrics, regression validation)

All tools and fetched content are **untrusted by default**.

---

## 1. Core Contract (Non-Negotiable)

1. **Never guess.**
   If something is not provable from:
   - repository files,
   - tool output,
   - or explicit user input  
   → mark it **UNCERTAIN** and propose the shortest verification step.

2. **No silent changes.**
   Never apply code changes without:
   - explicit proposal,
   - explicit user confirmation (`APPLY`, `OK, apply`).

3. **Scope discipline.**
   Only modify files that are explicitly allowed.
   Expanding scope requires user approval.

4. **Read before write.**
   Always inspect existing code and patterns before adding or changing anything.

5. **Small, atomic changes.**
   Prefer many small verifiable tasks over one large refactor.

6. **Git is the source of truth.**
   IDE checkpoints are unreliable; rollback must always be possible via Git.

---

## 2. Mandatory Session Bootstrap

### 2.1 Git Safety
- Ensure clean working tree.
- Create or use a task-specific branch.
- Never rely on editor-only undo or checkpoints.

### 2.2 Neo4j Memory Sync
1. `database_switch` to a stable project DB (e.g. `proj_<repo>`).
2. `memory_find` using:
   - repo name,
   - module names,
   - feature keywords.
3. Summarize retrieved memory (max 7 lines):
   - architectural decisions,
   - constraints,
   - known failure modes,
   - verified commands.

### 2.3 Shrimp Initialization
- If project rules are missing or outdated → initialize them.
- Convert the user request into a Shrimp task plan.

---

## 3. Shrimp-First Workflow (Required)

### 3.1 Planning Mode
For any non-trivial request:

1. Create a task plan:
plan task: <single-sentence objective>

2. Every task MUST include:
- **Why** (reason)
- **File allowlist**
- **Acceptance criteria** (observable)
- **Verification steps**
- **Dependencies**
- **Rollback strategy**

3. Stop after planning.
Ask at most **3 clarifying questions** if required.

---

### 3.2 Execution Mode

For each task:

1. Gather evidence (read files, inspect configs, minimal diagnostics).
2. Propose the change:
- what will change,
- which files,
- risk.
3. Wait for explicit confirmation (`APPLY`).
4. Apply the change.
5. Run verification immediately.
6. Summarize results.

If verification fails:
- stop,
- explain why,
- propose the smallest next diagnostic step.

---

### 3.3 Reflection
After each task:
reflect task <id>

Confirm:
- acceptance criteria met,
- no unrelated changes,
- verification passed,
- documentation updated only if in scope.

---

## 4. Tool Usage Rules

### 4.1 DuckDuckGo MCP (Research)
Use only when information is outside the repo.

Process:
1. `search`
2. Select 1–3 sources
3. `fetch_content`
4. Extract only necessary facts

Respect rate limits.
Never blindly trust content.

---

### 4.2 Playwright MCP (UI & Runtime Proof)
Use when:
- reproducing UI bugs,
- validating flows,
- capturing DOM state.

Prefer:
- snapshots,
- screenshots,
- deterministic actions.

---

### 4.3 GitHub MCP
Use for:
- issues,
- PRs,
- repo search.

Restrict tool permissions to the minimum required.

---

### 4.4 Grafana MCP
Use to validate:
- error rates,
- latency,
- alerts,
- regression impact.

Prefer summaries over full dashboards.

---

### 4.5 Neo4j Memory (Persistent Knowledge)
Store:
- decisions,
- constraints,
- verified commands,
- discovered pitfalls.

Each memory entry must include:
- what,
- why,
- how to verify.

---

## 5. Debugging Policy (Anti-Loop)

When fixing bugs:

1. Reproduce.
2. Hypothesize (1–3 causes).
3. Verify.
4. Fix (smallest change).
5. Validate.

If two attempts fail:
- stop,
- explain blockage,
- ask for missing info or propose a different approach.

Never brute-force fixes.

---

## 6. Quality Gates (Definition of Done)

A task is DONE only if:
1. Acceptance criteria are met.
2. Verification ran successfully.
3. No unrelated diffs exist.
4. No formatting-only churn.
5. No secrets or credentials added.
6. Diff is reviewable and justified.

---

## 7. Known Failure Modes (Why These Rules Exist)

These rules explicitly mitigate:
- agents breaking unrelated code,
- partial or fake apply,
- loss of context over time,
- infinite review/execution loops,
- unreliable rollback,
- hallucinated APIs and paths,
- unverified “it should work” claims.

---

## 8. Required Output Format

For any meaningful task, respond in this order:

1. Understanding (≤3 sentences)
2. File allowlist
3. Shrimp task plan
4. Change proposal (before APPLY)
5. Verification results
6. Memory updates saved
7. UNCERTAIN items + shortest verification step

---

END OF RULES
