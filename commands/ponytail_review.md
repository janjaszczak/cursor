# /ponytail_review — Over-engineering review (diff or repo)

You are in PONYTAIL REVIEW mode. Goal: find code that didn't need to be written —
unnecessary abstractions, unused dependencies, dead code, premature generalization —
without touching validation, error handling, security, or accessibility.

Default is **review-only**. Do not delete/rewrite anything until the user confirms
(or this is invoked as part of `/cleanup` with **APPLY CLEANUP** already given).

## 0) Scope
- `/ponytail_review` (no args) → diff mode: `git diff` (staged + unstaged) against the
  base branch, or the current PR's changed files if that's clearer.
- `/ponytail_review repo` → full-repo audit: walk source directories, skip
  generated/vendored paths (`node_modules/`, `dist/`, `build/`, `.venv/`, lockfiles).
- `/ponytail_review debt` → scan for deferred shortcuts (comments like
  `# native for now, revisit at scale` or similar) and list them with file:line; do not
  create a ledger file unless the user asks for one.

## 1) Apply the ladder as a filter
For each changed/flagged unit, ask in order — first "yes" stops the check:
1. Does this need to exist at all? (YAGNI)
2. Does the codebase already have this? (search before flagging as "missing")
3. Does stdlib/native platform/an installed dependency already cover it?
4. Would one line do what a wrapper/class/module currently takes many lines to do?

If a rung applies and the diff didn't take it, that's a finding.

## 2) Do NOT flag
- Anything load-bearing for correctness: trust-boundary validation, error handling,
  security checks, accessibility — even if it adds lines.
- Abstractions with a real second caller today or an explicit near-term requirement
  stated by the user/plan.

## 3) Output (concise)
```text
## Ponytail review — <scope: diff | repo | debt>

### Findings
| File:line | What it is | Why it's excess | Suggested fix |
|---|---|---|---|
| ... | ... | ... | delete / inline / reuse <existing> |

### Verdict
<N> rung(s) skipped out of the diff/repo reviewed. <"Clean" if zero.>

### Debt (if scope=debt or any found)
| File:line | Shortcut taken | Revisit when |
|---|---|---|
```

## 4) Apply (only if user confirms, or already inside APPLY CLEANUP)
- Delete or inline the confirmed findings in small, verifiable steps.
- Re-run the repo's verify command (per `AGENTS.md` / `AGENTS.default.md`) after each
  batch of deletions — deleting "unnecessary" code must not break tests.

## 5) Hard constraints
- Never remove validation/error-handling/security/accessibility code, even if it looks
  unused at first glance — confirm with a repo-wide reference search first
  (pairs with `repo-grounding`).
- If uncertain whether something is dead code vs. used via reflection/dynamic
  dispatch/config, mark UNCERTAIN and do not propose deletion.
