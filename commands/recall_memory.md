# /recall_memory — search Neo4j memory first

- Switch to this project DB (database_switch).
- Run memory_find for the user’s current topic and return:
  1) top matches (id + name)
  2) the most actionable observations (commands/paths)
  3) suggested next step for the current task
If nothing relevant found: say “No relevant memory found” + propose what to store once solved.
