# /save_memory — force write to Neo4j memory

Store the following as persistent memory NOW (no extra confirmation):
- Ensure correct project DB: if not already set, call database_switch to a project-specific DB (e.g., repo name).
- Use memory_store with:
  - name: concise, searchable title
  - memoryType: one of {howto, decision, constraint, location, lesson, snippet}
  - observations: include exact commands, file paths, URLs, and pitfalls
  - metadata: tags, repo, date, confidence (high/med/low)
- If applicable, create relations to existing memories (e.g., “DEPENDS_ON”, “RELATED_TO”).

After storing, output: memory id(s) + 1-line retrieval query to find it later.
