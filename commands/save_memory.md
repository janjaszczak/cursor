# /save_memory — force write to Neo4j memory

Store the following as persistent memory NOW (no extra confirmation).

**Tools (user-memory MCP):** Use the tools that actually exist. There is no `memory_store` or `database_switch` in this MCP.

- **create_entities** — to store new memories. Pass `entities`: list of `{ name, type, observations }`.
  - name: concise, searchable title (unique identifier).
  - type: one of person, company, location, concept, event; or for retro: rule, pattern, tool, workflow, risk, preference.
  - observations: list of strings (exact commands, file paths, URLs, pitfalls; one fact per string).
- **add_observations** — to add facts to an existing entity (entityName + observations list).
- **create_relations** — to link entities (e.g. RELATED_TO, DEPENDS_ON) when both nodes exist.

Before creating: optionally **search_memories** (query) to avoid duplicates; if an entity with the same name exists, use add_observations instead of create_entities.

After storing, output: entity name(s) + 1-line retrieval query (e.g. search_memories query) to find it later.
