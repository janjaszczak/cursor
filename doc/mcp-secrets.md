# MCP secrets and environment variables

Runbook for **adding, rotating, and verifying** API keys and other secrets used by MCP servers.  
Skill KeePass: [`skills/keepass/SKILL.md`](../skills/keepass/SKILL.md) (`/keepass`).

---

## Where each piece lives

| Layer | File / store | Role |
|-------|----------------|------|
| **Source of truth** | `cursor.kdbx` (KeePass) | All API keys, tokens, host passwords |
| **Runtime (local)** | `~/.cursor/.env` | Values MCP actually uses — **gitignored** |
| **Template** | `.env.example` | Variable **names** and comments — safe to commit |
| **Config (no secrets)** | `mcp.json` | Server definitions; `-e VAR_NAME` or Python launchers only |
| **Keyring** | secret-tool / SecretStore | **Only** the KeePass **master** password for `cursor.kdbx` |

**Never** commit real secrets to Git or put them in `mcp.json`. Cursor does **not** expand `${VAR}` or `$VAR` inside `mcp.json` `headers` — use `.env` + a launcher script instead (see Context7 below).

---

## How secrets reach an MCP server

Three patterns in this repo:

| Pattern | MCP examples | What you maintain |
|---------|----------------|-------------------|
| **Docker `-e VAR`** | github, grafana, postman, perplexity | `VAR` in `.env` + optionally **User/shell env** via `setup-env-vars.*` so the Cursor process passes it into `docker run` |
| **Python launcher reads `.env`** | memory (`mcp-run-memory.py`), context7 (`mcp-run-context7.py`) | Only `~/.cursor/.env` — launcher loads it before starting the server |
| **URL / no key in repo** | duckduckgo, searxng, browseros, shrimp | No API key, or host-only (Apify: configure token in Cursor MCP UI if needed) |

After any change to `.env` or `mcp.json`: **restart Cursor**.

---

## Recipe: add or rotate one API key

### 1. Prerequisites

- `~/.cursor/keepass-db.path` — one absolute path to `cursor.kdbx` ([`keepass-db.path.example`](../keepass-db.path.example))
- Keyring works: `~/.cursor/scripts/test-keepass-read.sh` (WSL) or `get-keepass-secret.ps1` (Windows)
- Copy template if needed: `cp ~/.cursor/.env.example ~/.cursor/.env`

### 2. Create or update the KeePass entry

Suggested layout for MCP keys:

```text
API Keys/
  Context7
  GitHub
  …
```

Use the **Password** field (or a custom attribute) for the token. The helper scripts default to attribute `Password`.

### 3. Find the exact entry path

Paths are **group/title**, not what you see in the UI with a leading slash:

```bash
DB="$(grep -v '^#' ~/.cursor/keepass-db.path | head -1)"
keepassxc-cli search "$DB" "Context7"
# Example output: /API Keys/Context7  →  use: API Keys/Context7
```

Read without printing the secret in chat logs:

```bash
~/.cursor/scripts/get-keepass-secret.sh "API Keys/Context7" "Password"
# Windows: .\get-keepass-secret.ps1 "API Keys/Context7" "Password"
```

If lookup fails, the path is wrong — **search first**, do not guess `Cursor/API Keys/...` unless that group exists in your database.

### 4. Write into `~/.cursor/.env`

Match the name in [`.env.example`](../.env.example). One variable per line:

```bash
CONTEXT7_API_KEY=<paste value from KeePass>
GITHUB_PERSONAL_ACCESS_TOKEN=<…>
```

For **Docker MCPs** (GitHub, Grafana, Postman, Perplexity), also run env sync if Cursor does not see variables:

| Where Cursor runs | Command |
|-------------------|---------|
| **Windows** | PowerShell **as Administrator**: `cd $env:USERPROFILE\.cursor; .\scripts\setup-env-vars.ps1` |
| **WSL / Linux** | `cd ~/.cursor && ./scripts/setup-env-vars.sh` (optional; adds exports to `~/.profile` / `~/.bashrc`) |

Launchers (**memory**, **context7**) do **not** require `setup-env-vars` if `.env` is filled — they read `.env` themselves.

### 5. WSL + Windows: two `.cursor` trees

Often **`/home/<user>/.cursor`** and **`C:\Users\<user>\.cursor`** are separate copies.

Keep in sync (at minimum):

- `mcp.json`
- `.env` (secrets)
- `scripts/mcp-run-*.py`

Or set **`CURSOR_CONFIG_DIR`** to one canonical directory, or run [`scripts/sync-keepass-to-wsl-home.sh`](../scripts/sync-keepass-to-wsl-home.sh) after editing on Windows.

### 6. Verify

```bash
cd ~/.cursor && ./scripts/verify-config.sh
python scripts/quality-gate.py
./scripts/test-mcp-servers.sh   # optional
```

Restart Cursor. For Context7, MCP list should show `context7`; a prompt with `use context7` should hit the server (Node.js 18+ / `npx` on PATH).

---

## Variable ↔ MCP reference

| Environment variable | MCP server | KeePass (example path) | Notes |
|----------------------|------------|-------------------------|--------|
| `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE` | memory | (your Neo4j creds) | Launcher; `NEO4J_URI` in `.env` is for host tools, not the container |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | github | `API Keys/GitHub` (if you use that layout) | Docker `-e` |
| `GRAFANA_URL`, `GRAFANA_API_KEY` | grafana | | Docker `-e` |
| `POSTMAN_API_KEY` | postman | | Docker `-e` |
| `PERPLEXITY_API_KEY` | perplexity | | Paid escalation only — see [mcp.md § Cost tiering](mcp.md#cost-tiering-search--scrape) |
| `CONTEXT7_API_KEY` | context7 | **`API Keys/Context7`** | Launcher [`mcp-run-context7.py`](../scripts/mcp-run-context7.py) |
| `SEARXNG_SECRET` | searxng (backing) | optional | Local CSRF token; see [docker/mcp-searxng/README.md](../docker/mcp-searxng/README.md) |

Add a new row here when you introduce a new `-e` in `mcp.json` or a new launcher.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `Could not find entry with path …` | Wrong KeePass path | `keepassxc-cli search` → use `Group/Title` without leading `/` |
| MCP works in WSL but not Windows | `.env` or User env only on one side | Sync `.env`; run `setup-env-vars.ps1` on Windows |
| Context7: `CONTEXT7_API_KEY is not set` | Missing or placeholder in `.env` | Step 4 above; restart Cursor |
| GitHub/Grafana MCP auth errors | Docker `-e` empty in Cursor process | `setup-env-vars.*`; restart Cursor |
| Secret in KeePass UI under “Cursor / API Keys” | Group may still be `API Keys` at DB root | Trust **`search`**, not the folder label in KeePassXC |
| Tempted to put key in `mcp.json` `headers` | Cursor won’t substitute env vars | Use `.env` + launcher pattern like context7 |

Hooks block **writing** secrets into tracked files ([`doc/hooks.md`](hooks.md)); editing `.env` manually or via approved flow is expected.

---

## Related docs

- [configuration.md](configuration.md) — full setup, `CURSOR_CONFIG_DIR`, Neo4j/SearXNG
- [mcp.md](mcp.md) — server list, Docker, cost tiering
- [keepass.md](keepass.md) — database path, keyring, host entries
- [CONFIG_REPO.md](CONFIG_REPO.md) — do not commit `.env`
