# Cursor Rules

This document describes the project rules and conventions defined in `.cursor/rules/`.

## Overview

Rules are workspace-level guidelines that Cursor applies when working on this project. They are stored as Markdown files (`.mdc`) in `.cursor/rules/`.

## Rule Types

### Global Rules (Integrated)

Global engineering policies, MCP tools usage guidelines, and workflow instructions are now integrated into **`cursor-user_roles.txt`** at the repository root. This includes:

- **Quality requirements:** Coverage (lines ≥ 80%, branches ≥ 70%), CI/CD policies, Git hygiene
- **MCP tools usage:** All 6 MCP servers (memory, duckduckgo, github, playwright, grafana, shrimp-task-manager) with usage guidelines
- **Workflow:** 7-step ALWAYS-ON WORKFLOW with MCP integration at each step
- **Guardrails:** Security, destructive operations, rollback procedures

See `cursor-user_roles.txt` for the complete integrated ruleset.

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

1. Context-specific rules (`.cursor/rules/*.mdc` with globs)
2. Global rules (`cursor-user_roles.txt` at repository root - highest priority)

**Note:** `cursor-user_roles.txt` serves as the primary source for global engineering policies, MCP tools usage, and workflow instructions. Context-specific rules in `.cursor/rules/` complement these global rules for specific file patterns.

## Best Practices

- Keep rules focused and specific
- Use globs to limit rule scope
- Document why rules exist
- Update rules as project evolves
- Remove obsolete rules
