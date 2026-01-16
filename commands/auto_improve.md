@auto_improve — Chat Retrospective → Improvements (USER RULES / PROJECT RULES / MEMORY TO SAVE)

Context: Analyze THIS agent chat thread (full conversation visible in Cursor).

GOAL
1) Find undesired agent behaviors and points where the user had to intervene.
2) Diagnose issues with concrete chat evidence.
3) Propose non-overlapping improvements in 3 groups:
   A) USER RULES (global startup instructions for the agent)
   B) PROJECT RULES (repo-scoped reminders for THIS repository only)
   C) MEMORY TO SAVE (cross-project lessons to store in the Neo4j memory server; NOT loaded with USER RULES)

MANDATORY PRINCIPLES
- Internal CoVe for analysis: Draft → pick 3–5 highest-impact claims → verification Qs → answer independently → revise.
- DRY + KISS across outputs:
  - No repetition between groups.
  - Prefer fewer, stronger items; keep each item atomic.
- Be professional and concise (no verbosity/token waste).
- Ask up to 3 questions only if absolutely necessary; otherwise proceed.

GROUPING RULES (NO OVERLAP + JUSTIFICATION REQUIRED)
Each proposed item MUST be placed in exactly ONE group with a 1-sentence justification:
- USER RULES: stable, reusable behavior guidance for most repos (core agent operating model).
- PROJECT RULES: depends on THIS repo’s conventions/workflows/tooling/domain constraints.
- MEMORY TO SAVE: broadly useful across repos but too specific/verbose for USER RULES; store in Neo4j for recall later.

If an item could fit multiple groups, choose ONE using this priority:
PROJECT RULES → MEMORY TO SAVE → USER RULES

WHAT TO FLAG (SCAN FULL CHAT)
- Incorrect/unsupported claims; stale assumptions; missing verification where needed.
- Not following explicit user constraints (scope, format, tooling, brevity).
- Token waste: rambling, repetition, low-signal questions.
- Weak planning/execution; lack of decomposition; confusion.
- Tooling mistakes (missing required research/tests/log checks; wrong file ops).
- Risky guidance without appropriate caution (security/legal/finance).
- Any user intervention: corrections, reframes, retries.

EVIDENCE RULE
Do NOT invent issues. Every issue must include a short quote from the chat (1–2 sentences max).

REPO FILE TARGET (PROJECT RULES)
- Create/update: `.cursor/rules/{REPO_NAME}_rules.md`
- Determine {REPO_NAME} from the git repo root folder name:
  - repo_root = `git rev-parse --show-toplevel`
  - REPO_NAME = basename(repo_root)
- Keep this file compact (avoid context bloat).

NEO4J MEMORY SERVER (MEMORY TO SAVE) — TOOLING AND DRY/KISS POLICY
You have access to memory tools (Neo4j-backed):
- read_graph
- search_nodes
- open_nodes
- create_entities
- add_observations
- create_relations
- delete_entities / delete_observations / delete_relations (destructive; avoid unless explicitly needed)

Principles:
- Prefer targeted queries (search_nodes) over read_graph (too large).
- Deduplicate by canonical naming + pre-search.
- Use create_entities for upsert-like behavior; if the entity exists, merge/add observations instead of duplicating.
- Keep observations as single, distinct facts (one sentence each).
- Create relations only between existing entities; keep relationType descriptive and consistent (UPPER_SNAKE_CASE).
- Avoid destructive deletes unless (a) user explicitly requests cleanup or (b) duplicates are unambiguous AND you list them for approval first.

ENTITY + RELATION SCHEMA (KISS)
Entity types (examples; use only what’s needed): rule | pattern | tool | workflow | risk | preference
Relations (examples; use only what’s needed): PREVENTS | APPLIES_TO | RELATED_TO | USED_WITH | DEPENDS_ON
(Always directed: source → target.)

INTERACTIVE APPLY MODEL (IMPORTANT)
- Produce proposals first. Do NOT apply anything automatically.
- The user must choose what to include/exclude per group.
- Only after the user types exactly: APPLY
  - finalize outputs (ready-to-paste)
  - update `.cursor/rules/{REPO_NAME}_rules.md`
  - execute Neo4j memory tool calls for selected MEMORY items (with DRY/KISS checks)

OUTPUT FORMAT (MANDATORY)

0) Snapshot (1 short paragraph)
- What the user was trying to achieve + what success means.

1) Issues & Evidence (sorted by impact)
For each issue:
- Issue ID: I-01, I-02, ...
- Category: Accuracy | Instruction-following | Brevity/Token efficiency | Planning | Tooling | Safety/Risk | Other
- Evidence: “...” (1–2 sentences)
- Diagnosis: 1 sentence
- User intervention: Yes/No + 1 sentence
- Fix intent: 1 sentence

2) Proposed Improvements (three groups; DRY + KISS; no duplicates)
2.1 USER RULES (global)
For each:
- UR-01...
- Proposed text (ready-to-paste; 1–3 lines)
- Fixes: Issue IDs
- Why USER RULES: 1 sentence

2.2 PROJECT RULES (repo-scoped)
Deliver as a minimal patch for `.cursor/rules/{REPO_NAME}_rules.md`:
- Add:
- Replace:
- Remove:
Constraints:
- Prefer max 10 bullets total (post-consolidation).
- Each bullet ideally ≤ 120 chars.
For each:
- Fixes: Issue IDs
- Why PROJECT RULES: 1 sentence

2.3 MEMORY TO SAVE (Neo4j; cross-project)
For each:
- M-01...
- Memory entity name (canonical)
- type: (rule|pattern|tool|workflow|risk|preference)
- observations: 1–3 distinct facts (1 sentence each)
- relations: (optional) list of {source, relationType, target}
- Fixes: Issue IDs
- Why MEMORY: 1 sentence

3) Selection + APPLY Plan (user-controlled)
- Provide a checklist-like list of all UR / PR / M item IDs with short labels.
- Ask user to respond with:
  - Include: <IDs>
  - Exclude: <IDs>
  - Then: APPLY

4) After APPLY (do this only after the user types APPLY)
4.1 Final USER RULES block (only included UR items; no new content)
4.2 Final patch for `.cursor/rules/{REPO_NAME}_rules.md` (only included PR items)
4.3 Neo4j memory execution plan + tool calls (only included M items), strictly in this order:
   a) For each memory item: search_nodes with 2–5 keywords (name + synonyms)
   b) open_nodes for the best candidate matches (if any)
   c) Decide: reuse existing entity vs create new (justify briefly)
   d) create_entities (preferred) and/or add_observations (if entity exists)
   e) create_relations (only if both nodes exist; avoid duplicates)
   f) Never delete unless user requested; if deletion is needed, present candidates and require explicit approval

Optional: UNCERTAIN
- List uncertainties with the shortest verification method (log/test/source/user confirm).
