---
name: mcp-context7-docs
description: Fetch version-specific library and framework documentation via Context7 MCP. Use when implementing against third-party APIs/SDKs where model knowledge may be stale, or when the user says "use context7" / asks for current docs for a named library.
compatibility: Requires context7 MCP in mcp.json (remote URL). Network access to mcp.context7.com. Optional CONTEXT7_API_KEY in Cursor MCP headers for higher rate limits.
allowed-tools: MCP(*)
metadata:
  author: janjaszczak
  intent: Version-accurate docs; not a substitute for general web search.
---

# mcp-context7-docs

## Activation gate (anti-noise)

Activate when at least one is true:

- User asks for current/official docs for a **named library or framework** (Next.js, FastAPI, Prisma, etc.).
- User includes "use context7" or equivalent.
- You are about to call a third-party API and the exact version or recent API surface matters.

Do **not** activate for:

- General web search, news, or "what happened lately" → use **searxng** / **duckduckgo** (see `skills/deep-research/SKILL.md`).
- Deep synthesized research with citations in one call → **perplexity** only when user explicitly requests deep research.
- Repo-local conventions → read the repository first (`repo-grounding`).

## Procedure

1. Identify library name and version if known (from `package.json`, `pyproject.toml`, lockfile, or user).
2. Call Context7 MCP tools to resolve and fetch relevant documentation snippets.
3. Prefer official API shapes from Context7 over memory or training cutoff; cite that docs came from Context7 when they drive a design choice.
4. If Context7 is unavailable: mark UNCERTAIN, fall back to searxng for the official docs URL, then read repo lockfiles for version.

## Output

- Short: which library/version was targeted + key API constraints + next implementation step.
- Do not dump full doc pages; keep only what the current task needs.

## Failure handling

- MCP unreachable: suggest Cursor restart after confirming `context7` entry in `mcp.json`; optional free key at context7.com/dashboard for rate limits.
