# Cursor Commands

This document describes custom commands defined in `.cursor/commands/`.

## Overview

Custom commands are user-defined shortcuts that extend Cursor's functionality. They are stored as Markdown files in `.cursor/commands/` and can be invoked via the command palette or chat.

## Available Commands

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
