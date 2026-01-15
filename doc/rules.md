# Cursor Rules

This document describes the project rules and conventions defined in `.cursor/rules/`.

## Overview

Rules are workspace-level guidelines that Cursor applies when working on this project. They are stored as Markdown files (`.mdc`) in `.cursor/rules/`.

## Rule Types

### Always Applied Rules

These rules apply to all files in the workspace:

#### `quality.mdc`
**Description:** Global engineering policies (coverage, lint/format, Git hygiene)

**Key policies:**
- CI coverage: lines ≥ 80%, branches ≥ 70%, per-file guardrail lines ≥ 70%
- Run linters/formatters in CI before tests; block merges on errors
- Use Conventional Commits; keep PRs small with test steps and risks
- Never commit secrets; provide `.env.example` and local setup notes

#### `mcp-tools.mdc`
**Description:** How to use available MCP servers and tools

**Key policies:**
- Prefer using MCP tools instead of "simulating" their behavior
- Before using tools that change external state, explain and ask for confirmation
- Never expose or log secrets returned by MCP tools

**MCP servers:**
- `memory` - Long-term project memory (Neo4j)
- `duckduckgo` - External web search
- `github` - GitHub repository operations
- `playwright` - Browser automation
- `grafana` - Metrics and dashboards

### Context-Specific Rules

These rules apply only to files matching specific glob patterns:

#### `next-stack.mdc`
**Applies to:** `frontend/**`

**Stack:**
- Next.js App Router (Server Components by default)
- Tailwind CSS + shadcn/ui
- TanStack Query for client server-state
- React Hook Form + Zod for forms
- Prisma (server-only)

**Conventions:**
- AirBnB style (ESLint) + Prettier
- PascalCase for React components
- Named exports preferred

#### `python-backend.mdc`
**Applies to:** `backend/**`

**Stack:**
- FastAPI with Pydantic v2
- Alembic for migrations
- pytest for testing

**Conventions:**
- Keep handlers thin; move logic to services
- Use Depends for dependency injection
- Write idempotent Alembic migrations for every schema change
- Stream file-by-file for ETL/parsers
- Log invalid records to CSV

#### `python-style.mdc`
**Applies to:** `**/*.py`

**Conventions:**
- Type hints consistently (including return types)
- Concise docstrings (Google style)
- Follow PEP 8; Black for formatting
- Keep functions small and cohesive

#### `vanilla-web.mdc`
**Applies to:** `**/*.html`, `**/*.css`, `**/*.js`

**Conventions:**
- HTML/CSS/JS only (no framework)
- Keep JS modular (ESM)
- Prefer small, focused functions
- Avoid global state

#### `parsers.mdc`
**Applies to:** `data/**`

**Conventions:**
- Process input files sequentially
- Validate/coerce types explicitly
- Skip irreparable records; log to CSV
- Emit metrics: rows_ok, rows_skipped, parse_errors
- Ensure idempotent DB writes

#### `solid.mdc`
**Applies to:** `**/*.{ts,tsx,js,jsx}`, `**/*.py`, `**/*.{env,yml,md}`

**SOLID Principles:**
- **SRP**: One reason to change per class/module
- **OCP**: Extend via interfaces/abstracts
- **LSP**: Subtypes keep invariants
- **ISP**: Minimal, client-specific interfaces
- **DIP**: High-level depends on abstractions

## How Rules Work

1. **Always applied rules** (`alwaysApply: true`) are active for all files
2. **Context-specific rules** apply only to files matching their `globs` patterns
3. Rules are evaluated in order; later rules can override earlier ones
4. Rules use frontmatter YAML for metadata:
   ```yaml
   ---
   description: Rule description
   globs: ["pattern/**"]
   alwaysApply: false
   ---
   ```

## Adding New Rules

1. Create a new `.mdc` file in `.cursor/rules/`
2. Add frontmatter with description and globs (if context-specific)
3. Write the rule content in Markdown
4. Test by opening a matching file in Cursor

## Rule Priority

1. Always-applied rules (lowest priority)
2. Context-specific rules (higher priority, based on file path)
3. User-level rules (highest priority, from `cursor-user_roles.txt`)

## Best Practices

- Keep rules focused and specific
- Use globs to limit rule scope
- Document why rules exist
- Update rules as project evolves
- Remove obsolete rules
