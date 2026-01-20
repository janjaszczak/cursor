# /retro — Chat Retrospective → Improvements
# (USER RULES / PROJECT RULES / SKILLS / MEMORY TO SAVE)

Context: Analyze THIS agent chat thread (full conversation visible in Cursor).

## GOAL
1) Find undesired agent behaviors and points where the user had to intervene.
2) Diagnose issues with concrete chat evidence (no inventions).
3) Propose non-overlapping improvements in 4 groups:
   A) USER RULES (global startup instructions for the agent)
   B) PROJECT RULES (repo-scoped rules for THIS repository only)
   C) SKILLS (user-level/global skills; optionally project-level only if explicitly requested)
   D) MEMORY TO SAVE (cross-project lessons stored in Neo4j; NOT loaded with USER RULES)

---

# CRITICAL: PATHS / SCOPES (AVOID WRONG DIRECTORY)
There are TWO different `.cursor` roots:
1) Project `.cursor` (inside THIS repo) — should contain PROJECT RULES and optionally repo-scoped artifacts.
2) User `.cursor` (inside user home) — should contain global/user-level assets like commands and (in our setup) skills.

## Resolve paths (must do early and show them in Snapshot)
- PROJECT_ROOT:
  - `git rev-parse --show-toplevel`
- PROJECT_CURSOR_DIR:
  - `${PROJECT_ROOT}/.cursor`
- PROJECT_RULES_DIR (repo-scoped):
  - `${PROJECT_CURSOR_DIR}/rules`
- USER_HOME:
  - `$HOME` (macOS/Linux) or `%USERPROFILE%` (Windows)
- USER_CURSOR_DIR (global):
  - `${USER_HOME}/.cursor`
- USER_COMMANDS_DIR (global):
  - `${USER_CURSOR_DIR}/commands`
- USER_SKILLS_DIR (global; DEFAULT for SKILLS group in this project):
  - `${USER_CURSOR_DIR}/skills`

Never propose SKILLS changes targeting `${PROJECT_ROOT}/.cursor/skills` unless the user explicitly requests project-level skills.

---

# CAPABILITY CHECK (FIRST)
Before doing anything else:
- Identify which toolsets are available in this environment:
  - Shrimp Task Manager tools: plan_task, split_tasks, list_tasks, execute_task, verify_task
  - Neo4j memory tools: read_graph, search_nodes, open_nodes, create_entities, add_observations, create_relations, delete_*
- Only call tools that are actually available. If a toolset is not available, continue without it (do not error-loop).

---

# MANDATORY PRINCIPLES
- Internal CoVe for analysis: Draft → pick 3–5 highest-impact claims → verification Qs → answer independently → revise.
- DRY + KISS across outputs:
  - No repetition between groups.
  - Prefer fewer, stronger items; keep each item atomic.
- Token efficiency:
  - Max 12 issues (highest impact only).
  - Max 8 improvements per group unless absolutely necessary.
- Ask up to 3 questions only if absolutely necessary; otherwise proceed.
- No risky guidance without explicit caveats (security/legal/finance).

---

# GROUPING RULES (NO OVERLAP + JUSTIFICATION REQUIRED)
Each proposed item MUST be placed in exactly ONE group with a 1-sentence justification:
- USER RULES: stable, reusable agent behavior guidance for most repos.
- PROJECT RULES: depends on THIS repo’s conventions/workflows/tooling/domain constraints; stored in `${PROJECT_RULES_DIR}`.
- SKILLS: repeatable multi-step workflows / domain packages; stored in `${USER_SKILLS_DIR}` (global) in this setup.
- MEMORY TO SAVE: broadly useful across repos but too specific/verbose for USER RULES; store in Neo4j for recall later.

If an item could fit multiple groups, choose ONE using this priority:
PROJECT RULES → SKILLS → MEMORY TO SAVE → USER RULES

---

# WHAT TO FLAG (SCAN FULL CHAT)
- Incorrect/unsupported claims; stale assumptions; missing verification where needed.
- Not following explicit user constraints (scope, format, tooling, brevity).
- Token waste: rambling, repetition, low-signal questions.
- Weak planning/execution; lack of decomposition; confusion.
- Tooling mistakes (missing required research/tests/log checks; wrong file ops).
- Rule/skill misuse (didn’t activate when it should; activated but didn’t help).
- Any user intervention: corrections, reframes, retries.

---

# EVIDENCE RULE
Do NOT invent issues. Every issue must include a short quote from the chat (1–2 sentences max).

---

# PROJECT RULES — FILE STRATEGY (REPO-SCOPED)
Project Rules MUST be proposed as a small set of flat rule files under:
- `${PROJECT_RULES_DIR}/*.mdc`

## Keep rules flat inside `${PROJECT_RULES_DIR}`
Do NOT create subfolders inside `${PROJECT_RULES_DIR}` for `.mdc` files.
Nested rules directories elsewhere in the repo (e.g., `some/subdir/.cursor/rules`) may work, but keep each rules folder flat. :contentReference[oaicite:1]{index=1}

## Naming / structure (flat, ordered, DRY)
Use numeric prefixes for deterministic ordering and easy maintenance:
- `000-core.mdc`        (alwaysApply: true; minimal “laws”, no repo trivia)
- `050-workflow.mdc`    (how we work in THIS repo; review/test expectations)
- `100-<lang>.mdc`      (scoped by globs, e.g., Python/TS)
- `200-<domain>.mdc`    (e.g., infra, data-import, security-hardening)
- `900-ai-meta.mdc`     (meta: how to use rules/skills in THIS repo; keep tiny)

## Rule activation modes (choose ONE per file)
- alwaysApply: true  (no globs; minimal)
- globs: ...         (scoped injection)
- description: ...   (intelligent/manual attachment guidance)

Rules are stored in `.cursor/rules/`. :contentReference[oaicite:2]{index=2}

## Known Cursor issue guardrail (IMPORTANT)
If the UI creates `SKILL.md` under `${PROJECT_ROOT}/.cursor/skills` when you intended a Project Rule:
- Treat it as a Cursor bug and do NOT migrate Project Rules into project skills silently.
- Create/edit `.mdc` files directly in `${PROJECT_RULES_DIR}`. :contentReference[oaicite:3]{index=3}

---

# SKILLS — GOVERNANCE (USER-LEVEL / GLOBAL BY DEFAULT)
Skills are for repeatable, multi-step procedures and integrations, not for duplicating rules.
In this setup:
- Target path: `${USER_SKILLS_DIR}/<skill-name>/SKILL.md`
- Keep SKILLS changes OUT of the repo unless explicitly requested.

Cursor community guidance: skills are stored in `.cursor/skills/` as `SKILL.md` (project-level). In our setup we use the user-level/global skills directory (`~/.cursor/skills`) which Cursor docs and ecosystem tooling reference as a valid user-level skills location. :contentReference[oaicite:4]{index=4}

## Skill hygiene requirements
- Each skill: `${USER_SKILLS_DIR}/<skill-name>/SKILL.md`
- SKILL.md starts with YAML frontmatter (name + description at minimum).
- Progressive disclosure:
  - Keep SKILL.md short
  - Heavy detail → `references/`
  - Executables → `scripts/`

## Duplication avoidance
Avoid skill ID/name conflicts across multiple skill directories; if duplicates exist, prefer one canonical location (user-level) and remove/rename the other. :contentReference[oaicite:5]{index=5}

## What to recommend in SKILLS
- Split: one skill covers unrelated workflows.
- Merge: two skills overlap >50% and cause activation ambiguity.
- Add: recurring workflow missing a skill (appeared ≥2 times in issues).
- Remove: obsolete/noisy skills that duplicate PROJECT RULES.

---

# NEO4J MEMORY SERVER — DRY/KISS POLICY
(Only if memory tools are available.)

Tools:
- read_graph, search_nodes, open_nodes, create_entities, add_observations, create_relations, delete_*

Principles:
- Prefer targeted search_nodes over read_graph.
- Deduplicate by canonical naming + pre-search.
- create_entities as upsert-like; add_observations if exists.
- Observations atomic (one sentence each).
- Relations only between existing entities; relationType UPPER_SNAKE_CASE.
- No deletes unless user requested or duplicates are unambiguous AND listed for approval.

Entity types: rule | pattern | tool | workflow | risk | preference
Relations: PREVENTS | APPLIES_TO | RELATED_TO | USED_WITH | DEPENDS_ON

---

# INTERACTIVE APPLY MODEL (IMPORTANT)
- Produce proposals first. Do NOT apply anything automatically.
- The user must choose what to include/exclude per group.
- Only after the user types exactly: APPLY
  - Apply ONLY selected items:
    - USER RULES: final ready-to-paste block (no new content)
    - PROJECT RULES: patches under `${PROJECT_RULES_DIR}/*.mdc`
    - SKILLS: patches under `${USER_SKILLS_DIR}/*` (global)
    - MEMORY: execute Neo4j tool calls (dedup-first)
  - Verify completion:
    - Correct directories modified (repo vs user)
    - No duplicated memory entities
    - Minimal diff / no accidental collateral edits

---

# OUTPUT FORMAT
Prefer Shrimp tasks if Shrimp tools are available; otherwise produce the same sections as headings.

## If Shrimp is available: deliver as tasks

### Instantiate tasks with Shrimp (parameter mapping)

#### `plan_task` (what to pass)
Call `plan_task` with:
- `description`: "Run /retro on the current chat thread. Produce tasks matching OUTPUT FORMAT (0, 1, 2, 3.1–3.4, 4). Stop after the Selection Task and wait for the user to type exactly: APPLY before creating/executing the Apply Task."
- `requirements`: include constraints from CAPABILITY CHECK, EVIDENCE RULE, INTERACTIVE APPLY MODEL, and DRY/KISS limits (no inventions; toolsets optional; no auto-apply).

#### `split_tasks` (how to map OUTPUT FORMAT → task definitions)
Then call `split_tasks` with:
- `updateMode`: `clearAllTasks`
- `tasksRaw`: a JSON array defining **8 tasks**: 0, 1, 2, 3.1–3.4, 4 (do **not** create task 5 yet).

Notes:
- You do **not** pass task IDs to `split_tasks`. You pass task definitions; IDs are created by Shrimp.
- After `split_tasks`, call `list_tasks` and map **task name → taskId** for `execute_task`.
- If the chat used /commands, read the relevant specs under `${USER_COMMANDS_DIR}` before auditing expected behavior.

#### `split_tasks` (after user types APPLY → create Apply Task)
After the user types exactly `APPLY`, create the Apply Task by calling `split_tasks` again:
- `updateMode`: `append`
- `tasksRaw`: JSON array with **one** task:
  - name: "Apply selected improvements"
  - dependencies: ["Present selection checklist to user"]

#### `execute_task` / `verify_task` (how to use task IDs)
- `execute_task`: pass the `taskId` values returned by `list_tasks`, in dependency order.
- `verify_task`: pass the Apply Task’s `taskId` and include a brief completion summary + score.

0) Snapshot Task
- Task name: "Create retrospective snapshot"
- Must include:
  - PROJECT_ROOT + PROJECT_RULES_DIR
  - USER_COMMANDS_DIR
  - USER_SKILLS_DIR
  - What the user was trying to achieve + what success means (1 short paragraph)

1) Issues & Evidence Task
- Task name: "Identify and categorize issues with evidence"
- For each issue:
  - Issue ID: I-01, I-02, ...
  - Category: Accuracy | Instruction-following | Brevity/Token efficiency | Planning | Tooling | Safety/Risk | Skills/Rules | Other
  - Evidence: "..." (1–2 sentences)
  - Diagnosis: 1 sentence
  - User intervention: Yes/No + 1 sentence
  - Fix intent: 1 sentence
- Sort by impact

2) Compliance Audit Task
- Task name: "Audit adherence to predefined instructions"
- Must include:
  - Which USER RULES / PROJECT RULES / SKILLS were relevant during the work (list)
  - 3–8 key obligations the agent should have followed
  - Evidence-based status: OK / VIOLATION / NOT VERIFIED (+ shortest verification method)

3) Proposed Improvements Tasks (four separate tasks; DRY + KISS; no duplicates)

3.1 USER RULES Task
- Task name: "Propose USER RULES improvements"
- For each:
  - UR-01...
  - Proposed text (ready-to-paste; 1–3 lines)
  - Fixes: Issue IDs
  - Why USER RULES: 1 sentence

3.2 PROJECT RULES Task
- Task name: "Propose PROJECT RULES improvements"
- Deliver as minimal patch set under `${PROJECT_RULES_DIR}/*.mdc`:
  - Create (if missing):
  - Add:
  - Replace:
  - Remove:
- Constraints:
  - Keep each rule file small; split rather than bloat
  - Prefer ≤ 10 bullets per file
  - Each bullet ideally ≤ 120 chars
- For each change:
  - Fixes: Issue IDs
  - Why PROJECT RULES: 1 sentence

3.3 SKILLS Task
- Task name: "Propose SKILLS improvements"
- Deliver as minimal patch set under `${USER_SKILLS_DIR}/*` (global):
  - Add | Split | Merge | Remove | Refactor
- For each:
  - S-01...
  - Target: `${USER_SKILLS_DIR}/<name>/...`
  - Proposed change summary (max 5 lines)
  - Spec compliance check (frontmatter/name/description/progressive disclosure)
  - Fixes: Issue IDs
  - Why SKILLS: 1 sentence

3.4 MEMORY TO SAVE Task
- Task name: "Propose MEMORY TO SAVE items"
- For each:
  - M-01...
  - Memory entity name (canonical)
  - type: (rule|pattern|tool|workflow|risk|preference)
  - observations: 1–3 distinct facts (1 sentence each)
  - relations: (optional) {source, relationType, target}
  - Fixes: Issue IDs
  - Why MEMORY: 1 sentence

4) Selection Task
- Task name: "Present selection checklist to user"
- Provide a checklist-like list of all UR / PR / S / M item IDs with short labels.
- Ask user to respond with:
  - Include: <IDs>
  - Exclude: <IDs>
  - Then: APPLY

5) Apply Task (created only after user types APPLY)
- Task name: "Apply selected improvements"
- Implementation:
  5.1 Final USER RULES block (only included UR items; no new content)
  5.2 Final patches under `${PROJECT_RULES_DIR}/*.mdc` (only included PR items)
  5.3 Final patches under `${USER_SKILLS_DIR}/*` (only included S items)
  5.4 Neo4j memory execution plan + tool calls (only included M items), in this order:
     a) search_nodes (2–5 keywords: name + synonyms)
     b) open_nodes for best matches
     c) Decide: reuse vs create (1-sentence justification)
     d) create_entities and/or add_observations
     e) create_relations (only if both nodes exist; avoid duplicates)
     f) Never delete unless user requested; if needed, list candidates and require explicit approval
- Verification:
  - Correct directories modified (repo vs user)
  - Skills spec preserved
  - Memory entities created, no duplicates

---

# EXECUTION WORKFLOW
1) Capability check:
   - Determine whether Shrimp tools are available.
   - If the chat used /commands, identify which ones and read the relevant specs under `${USER_COMMANDS_DIR}` before auditing expected behavior.

2) If Shrimp is available:
   - `plan_task` → `split_tasks` (create tasks 0, 1, 2, 3.1–3.4, 4) → `list_tasks`
   - Execute tasks sequentially in dependency order using `execute_task`
   - Stop after the Selection Task and wait for user input
   - After user types exactly `APPLY`: `split_tasks` (append Apply Task) → `list_tasks` → `execute_task` (Apply) → `verify_task`

3) If Shrimp is NOT available:
   - Produce the same sections as headings (Snapshot, Issues & Evidence, Compliance Audit, Proposed Improvements (4 subsections), Selection).
   - Stop after Selection and wait for user input.
   - After user types exactly `APPLY`: perform the Apply step inline (only selected items) and include a short verification checklist (correct dirs modified; no accidental collateral edits).

Optional: UNCERTAIN
- List uncertainties with the shortest verification method (log/test/source/user confirm).
- Attach to the relevant tasks/sections.
