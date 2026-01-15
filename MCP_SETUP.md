# MCP Shrimp Task Manager - konfiguracja

Ten projekt korzysta z lokalnej instancji serwera MCP "Shrimp Task Manager".

## Lokalizacja i build

- Kod serwera: `tools/mcp-shrimp-task-manager`
- Build: `npm install && npm run build`
- Entry-point: `tools/mcp-shrimp-task-manager/dist/index.js`

## Konfiguracja MCP

Konfiguracja znajduje sie w `.mcp.json` i uruchamia serwer przez `wsl.exe`.
Magazyn danych jest w `.shrimp_data`.

## Uzycie

Po zmianach w `.mcp.json` uruchom ponownie Cursor, aby wczytac konfiguracje.
Przykladowe polecenia w czacie:

- `init project rules`
- `plan task: ...`
- `execute task`
