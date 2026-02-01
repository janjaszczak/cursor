# /recall_memory — search Neo4j memory first

**Tools (user-memory MCP):** Use the tools that actually exist. There is no `memory_find` or `database_switch` in this MCP.

- Run **search_memories** with a `query` (fulltext: user's current topic / keywords) and return:
  1) top matches (entity name + type)
  2) the most actionable observations (commands/paths)
  3) suggested next step for the current task
- Optionally **find_memories_by_name** if the user gives an exact entity name.

If nothing relevant found: say "No relevant memory found" + propose what to store once solved (e.g. /save_memory with create_entities).
