# cleanup

# /cleanup — Post-work Project Hygiene (audit → propose → apply)

You are in CLEANUP mode. Goal: restore repo order after agent work.
Default is SAFE (dry-run). Do NOT delete/move/rename until user confirms: **APPLY CLEANUP**.

## 0) Preconditions (Git safety)
- Confirm current branch and status. Prefer Git as rollback (commit checkpoints per cleanup step).
- If there are important uncommitted changes unrelated to cleanup, STOP and ask what to do.

## 1) Memory-first (Neo4j)
1) Switch to project DB (database_switch).
2) memory_find for: "cleanup", "repo hygiene", "docs location", "scripts folder", "<repo name>".
3) Apply constraints found (canonical doc locations, naming conventions, what not to delete).

## 2) Audit (no changes)
Collect evidence:
- `git status --porcelain` (untracked + modified)
- `git diff --name-only` (recently changed files)
- List candidate "new files created by agent" (untracked, or added in last commits if available).
- Identify canonical locations that already exist:
  - docs: `docs/`, `README*`, `CONTRIBUTING*`, `ARCHITECTURE*`
  - scripts/tools: `scripts/`, `tools/`, `bin/`
  - temp: `tmp/`, `temp/`, `.cache/`, `logs/`

### 2.1 Scripts consolidation candidates
Find scripts likely created ad-hoc:
- Root-level: `*.sh`, `*.ps1`, `*.py`, `*.js`, `*.ts` outside canonical folders
- Names suggesting one-offs: `tmp_*`, `debug_*`, `fix_*`, `scratch*`, `test_*manual*`
Determine if script is NEEDED by checking references:
- Search references in repo (use ripgrep / grep):
  - package.json scripts, Makefile, CI configs (.github/workflows, .gitlab-ci), docker-compose, README/docs
If referenced → KEEP and MOVE into canonical scripts folder (do not create new folder if one exists).
If not referenced → classify as TEMP and propose delete OR archive into a single canonical place (prefer delete after merge).

### 2.2 Documentation consolidation candidates (DRY/KISS)
Detect docs likely created as duplicates:
- New markdown files like: `*_notes.md`, `fix-*.md`, `debug*.md`, `TEMP*.md`, `doc*.md` in root or random folders
Rule:
- Prefer updating existing canonical docs (README / docs/…).
- Do NOT create a new “report” doc unless no canonical place exists.
For each candidate doc:
- Extract unique content and propose where it should be merged (exact target file + section).
- After merge, propose deletion of the duplicate file.

### 2.3 Garbage / generated artifacts
Propose cleanup for:
- caches: `__pycache__/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`, `dist/`, `build/`, `.next/`, `coverage/`
- OS/editor: `.DS_Store`, `Thumbs.db`, `*.swp`, `*.tmp`, `*.bak`
- logs: `*.log` (unless intentionally tracked)
Rule: if tracked in Git, do NOT delete automatically; propose and ask.

### 2.4 Do NOT touch (unless user explicitly asks)
- lockfiles: `poetry.lock`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`
- env/secrets: `.env*`, key material, tokens
- dependencies dirs: `node_modules/` (do not commit; only .gitignore updates)

## 3) Produce a Cleanup Proposal (must be concise)
Output ONLY:
A) A table with actions: KEEP / MOVE / MERGE / DELETE
   - file path
   - reason
   - target location (if MOVE/MERGE)
   - risk level (low/med/high)
B) A short verification plan (commands to run after apply)
C) Ask: "Type **APPLY CLEANUP** to execute."

If any item is uncertain, run a mini-CoVe:
- Draft decision → 3 verification questions (is it referenced? is it generated? is it canonical?) → answer via repo evidence → revise.
Mark remaining items as UNCERTAIN and do not apply them.

## 4) Apply (ONLY after: APPLY CLEANUP)
Execute in small steps with Git checkpoints:
1) Consolidate scripts:
   - move to canonical folder (reuse existing folder; otherwise propose one and ask)
   - update references (README/docs, CI, Makefile, package scripts)
2) Consolidate docs:
   - merge content into canonical doc(s)
   - delete duplicates only after merge is confirmed
3) Remove garbage artifacts
4) Update `.gitignore` minimally (only for confirmed generated artifacts)

## 5) Verify (required)
Run the most appropriate verification:
- lint/format/typecheck
- unit tests (and integration if cheap)
- build
If you cannot run commands, provide exact commands and expected “good” signals.

## 6) Memory candidates (Neo4j)
After successful cleanup, propose 1–3 memories (ask user to approve):
- canonical docs map (where to write what)
- canonical scripts map + how to run key scripts
- “cleanup checklist” and common pitfalls
If user says **SAVE MEMORY:** store immediately using memory_store, after checking memory_find to avoid duplicates.

