# Cursor Commands

This document describes custom commands defined in `.cursor/commands/`.

## Overview

Custom commands are user-defined shortcuts that extend Cursor's functionality. They are stored as Markdown files in `.cursor/commands/` and can be invoked via the command palette or chat.

## Available Commands

Four custom commands are defined: `/save_memory`, `/recall_memory`, `/cleanup`, `/retro`.

### `/save_memory`

**Purpose:** Force write to Neo4j memory (no extra confirmation)

**Usage:**
```
/save_memory
```

**Behavior:**
1. Ensures correct project DB (calls `database_switch` if needed)
2. Uses `memory_store` with:
   - `name`: Concise, searchable title
   - `memoryType`: One of `{howto, decision, constraint, location, lesson, snippet}`
   - `observations`: Include exact commands, file paths, URLs, and pitfalls
   - `metadata`: Tags, repo, date, confidence (high/med/low)
3. Creates relations to existing memories if applicable (e.g., "DEPENDS_ON", "RELATED_TO")

**Output:**
- Memory ID(s)
- 1-line retrieval query to find it later

**Example:**
```
/save_memory
Store: "Neo4j setup with Docker"
Type: howto
Observations: "docker run -d --name neo4j -p 7687:7687 neo4j:latest"
```

### `/recall_memory`

**Purpose:** Search Neo4j memory first before starting work

**Usage:**
```
/recall_memory
```

**Behavior:**
1. Switches to project DB (`database_switch`)
2. Runs `memory_find` for current topic
3. Returns:
   - Top matches (ID + name)
   - Most actionable observations (commands/paths)
   - Suggested next step for current task

**Output:**
- If found: Top matches with actionable info
- If not found: "No relevant memory found" + proposal for what to store once solved

**Example:**
```
/recall_memory
Topic: "GitHub MCP setup"
Returns: Memory about GitHub token configuration and WSL setup
```

### `/cleanup`

**Purpose:** Post-work repo hygiene: audit scripts, docs, and artifacts; propose KEEP/MOVE/MERGE/DELETE; apply only after user types "APPLY CLEANUP"

**Usage:**
```
/cleanup
```

**Behavior:**
1. Preconditions: confirm Git branch and status; prefer Git as rollback (commit checkpoints per step)
2. Memory-first: switch to project DB, run memory_find for cleanup/repo hygiene constraints
3. Audit (no changes): collect git status, diff, candidate new files; identify canonical locations (docs, scripts, temp)
4. Produce a cleanup proposal: table with actions (KEEP/MOVE/MERGE/DELETE), reason, target, risk; verification plan; ask for "APPLY CLEANUP"
5. Apply only after user types **APPLY CLEANUP**: consolidate scripts/docs, remove garbage, update .gitignore minimally
6. Verify: lint/tests/build
7. Optional: propose 1–3 memories for canonical docs/scripts map

**Output:** Proposal table; then after APPLY CLEANUP, execution summary and verification result.

### `/retro`

**Purpose:** Chat retrospective: analyze the conversation for issues and propose improvements to USER RULES, PROJECT RULES, SKILLS, and MEMORY

**Usage:**
```
/retro
```

**Behavior:**
1. Capability check: identify available tools (Shrimp, Neo4j memory)
2. Resolve paths: PROJECT_ROOT, PROJECT_CURSOR_DIR, USER_CURSOR_DIR, USER_COMMANDS_DIR, USER_SKILLS_DIR
3. Identify issues with evidence from the chat; audit adherence to instructions
4. Propose improvements in four groups: USER RULES, PROJECT RULES, SKILLS, MEMORY TO SAVE
5. Present selection checklist; wait for user to type **APPLY**
6. After APPLY: apply only selected items (patches, Neo4j tool calls); verify

**Output:** Snapshot, issues with evidence, compliance audit, proposed improvements per group, selection checklist; after APPLY, completion summary.

**Note:** Uses Shrimp tasks if available; otherwise same sections as headings. See [commands/retro.md](../commands/retro.md) for full spec.

## Command Structure

Commands are defined as Markdown files with:
- Title: Command name (e.g., `# /save_memory`)
- Description: What the command does
- Behavior: Step-by-step execution
- Output: What to return

## Creating New Commands

1. Create a new `.md` file in `.cursor/commands/`
2. Name it descriptively (e.g., `my_command.md`)
3. Use the format:
   ```markdown
   # /command_name — brief description
   
   - Step 1
   - Step 2
   - Output format
   ```

4. The command will be available in Cursor's command palette

## Best Practices

- Keep commands focused on single tasks
- Document expected inputs and outputs
- Include error handling instructions
- Test commands before committing
- Use descriptive names

## Integration with MCP

Commands can use MCP tools:
- `memory_store` / `memory_find` for Neo4j memory
- `github_*` for GitHub operations
- `grafana_*` for metrics
- Other MCP tools as needed

See [mcp.md](mcp.md) for available MCP servers.
