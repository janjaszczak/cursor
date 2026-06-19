# Cursor Commands

This document describes custom commands defined in `.cursor/commands/`.

## Overview

Custom commands are user-defined shortcuts that extend Cursor's functionality. They are stored as Markdown files in `.cursor/commands/` and can be invoked via the command palette or chat.

## Available Commands

Six custom commands are defined: `/save_memory`, `/recall_memory`, `/cleanup`, `/retro`, `/status`, `/next`.

### `/save_memory`

**Purpose:** Force write to Neo4j memory (no extra confirmation)

**Usage:**
```
/save_memory
```

**Behavior:**
1. Uses **user-memory MCP** tools: `create_entities` (name, type, observations), `add_observations` for existing entities, `create_relations` to link. There is no `memory_store` or `database_switch` in this MCP.
2. Before creating: optionally `search_memories` (query) to avoid duplicates.
3. See [commands/save_memory.md](commands/save_memory.md) for full tool mapping.

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
1. Uses **user-memory MCP** tools: `search_memories` (query) for fulltext search; optionally `find_memories_by_name`. There is no `memory_find` or `database_switch` in this MCP.
2. Runs search for current topic
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
2. Memory-first (if Neo4j MCP available): run search_memories for cleanup/repo hygiene constraints
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

### `/status`

**Purpose:** Read-only project status snapshot and recommendation for the next task (no edits, no mode switch, no execution).

**Usage:**
```
/status
```

**Behavior:**
1. Capability check (Shrimp, memory MCP, git, optional GitHub/CI)
2. Collect: Shrimp tasks (`in_progress` / `pending`), git status, memory search, light repo/CI signals
3. Recommend next task with suggested mode (PLAN | DEBUG | ASK | MULTITASK | AGENT) and skills
4. Stop without making changes

**Output:** Structured snapshot + recommended next task + blockers.

See [commands/status.md](../commands/status.md) for full spec.

### `/next`

**Purpose:** Check status, pick the next task, switch to the appropriate working mode, and **start execution**.

**Usage:**
```
/next
/next plan          # force PLAN mode
/next debug         # force DEBUG mode
/next status only   # status block only (same as /status)
```

**Behavior:**
1. Run `/status` evidence collection (short summary)
2. Pick next task (Shrimp `in_progress` → pending → git WIP → memory → issues)
3. Route to mode: PLAN (SwitchMode + plan-as-contract), DEBUG (RCA), ASK (read-only), MULTITASK (parallel subagents), or AGENT (default implement)
4. Execute: Shrimp `execute_task` loop or direct implementation with minimal skills
5. Ambiguity → ask user to pick; PLAN → wait for approval unless "just do it"

**Output:** Status line + chosen task + mode + immediate first action.

See [commands/next.md](../commands/next.md) for full spec.

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
- `create_entities` / `search_memories` (user-memory MCP) for Neo4j memory
- `github_*` for GitHub operations
- `grafana_*` for metrics
- Other MCP tools as needed

See [mcp.md](mcp.md) for available MCP servers.
