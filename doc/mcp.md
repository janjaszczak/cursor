# MCP (Model Context Protocol) Configuration

This document describes the MCP server setup, usage, Docker management, leftover Docker audit, and troubleshooting for this project.

## Overview

MCP servers in this repo use **mixed transports**. They are **not** Docker-only:

| Transport | Examples |
|-----------|----------|
| **Remote Streamable HTTP** | `github` (`https://api.githubcopilot.com/mcp/`), `Apify`, `browseros`, `BrowserClaw` |
| **Python launcher (stdio)** | `memory` (Neo4j still Docker underneath), `context7` |
| **Docker stdio** | `playwright`, `duckduckgo`, `searxng`, `grafana`, `shrimp-task-manager`, `postman`, `perplexity` |

Docker remains the right fit for **intentional free/self-hosted** search (`searxng`, `duckduckgo`) and for leftover catalog images that have not been migrated yet. Official images come from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp) or custom `docker/mcp-*` Dockerfiles.

## Configuration File

MCP servers are configured in `.cursor/mcp.json`. This file contains **no secrets** - all sensitive data is provided via environment variables.

## MCP Servers

13 MCP servers are configured. Search/scrape tooling is tiered by cost —
default to free/self-hosted, escalate to paid APIs only when needed:

1. **memory** (Neo4j) - Persistent knowledge storage in Neo4j graph database
2. **playwright** - Browser automation and web page interaction
3. **duckduckgo** - External web search, keyless (free)
4. **searxng** - External web search, self-hosted aggregated engines (free) — preferred default over duckduckgo, see [Cost tiering](#cost-tiering-search--scrape)
5. **github** - GitHub repository operations (official remote Streamable HTTP; not Docker)
6. **grafana** - Metrics, logs, and dashboards for debugging and performance
7. **browseros** - Visible browser automation on the user's own Chromium profile (CAPTCHA/2FA/OAuth)
8. **shrimp-task-manager** - Task planning, execution, and reflection
9. **postman** - API collection management (free tier for typical usage)
10. **perplexity** - Paid, synthesized search + citations — explicit deep-research/high-stakes only
11. **Apify** - Paid, usage-billed actor pipelines — verify real usage before relying on it
12. **context7** - Free remote MCP — version-specific library/framework documentation (not general web search)
13. **BrowserClaw** - Local HTTP MCP for agent web work (`http://127.0.0.1:9010/mcp`)

### Cost tiering (search / scrape)

`duckduckgo`, `searxng`, `perplexity`, and `Apify` overlap functionally (all
do some form of web search/scrape). To avoid paying for what a free
self-hosted tool already covers:

| Need | Default (free) | Escalate to (paid) only if |
|---|---|---|
| Routine web search / freshness check | `searxng` (preferred) or `duckduckgo` | — |
| Official docs for a named library/framework (version-aware) | `context7` | — |
| Synthesized answer + citations in one call | — | `perplexity`, user explicitly asked for deep research |
| Multi-page crawl / structured extraction | `playwright` (manual) | `Apify`, and only after confirming real recurring need — self-hosting Firecrawl was evaluated and rejected for now (5 containers, ≥8GB RAM, disproportionate to current usage) |

See `skills/deep-research/SKILL.md` for the agent-facing tool-selection gate.

### Leftover Docker MCP audit ([EUR-280](https://linear.app/eureka-labs/issue/EUR-280/poc-cursor-mcp-dockerremote-github-first-audyt-leftover))

GitHub moved to official remote in this change. Remaining Docker-backed entries:

| Server | Verdict | Why |
|--------|---------|-----|
| **playwright** | **MIGRATE** (later) | Official Playwright MCP can run via `npx` / local Chromium; Docker still works. No local `docker/mcp-playwright` folder. |
| **duckduckgo** | **KEEP** | Intentional free/keyless search tier. Local fallback Dockerfile stays (`docker/mcp-duckduckgo/`). |
| **searxng** | **KEEP** | Intentional free/self-hosted preferred search. Engine + wrapper still need Docker. |
| **grafana** | **MIGRATE** (later) | Official Grafana Cloud remote exists (`https://mcp.grafana.com/mcp`) but this repo points at **self-hosted** `GRAFANA_URL=http://localhost:3001`. Cloud remote is not a drop-in. Next step: official OSS `uvx mcp-grafana` **or** Cloud remote if the stack moves off localhost. |
| **shrimp-task-manager** | **KEEP** | Local task store in Docker volume `shrimp_data`; no official remote. Custom `docker/mcp-shrimp/` still required. |
| **postman** | **MIGRATE** (later) | Official remote exists (`https://mcp.postman.com/mcp` full mode). Docker `--full` can be replaced without losing the free-tier API-collection use case. |
| **perplexity** | **MIGRATE** (later) | Official hosted MCP exists; keep as **paid escalation only** (cost tiering unchanged). |
| **memory** | **KEEP** (this PR) | Neo4j stays Docker under the Python launcher. **Out of scope** — do not migrate memory/Neo4j here. |
| **github** (done) | **KILL** Docker leftover | Official remote `https://api.githubcopilot.com/mcp/` + `Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}`. Local `docker/mcp-github/` and `--github` build targets removed. |

**Do not** remove `searxng` / `duckduckgo` without strong evidence they are unused. Cost-tiering depends on them remaining the default free search path.

### Server Details

#### Memory (Neo4j)
- **Purpose:** Long-term project memory storage
- **Usage:** Store architectural decisions, constraints, and lessons learned. Do NOT store passwords, API keys, or other secrets.
- **Environment variables:** `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `NEO4J_DATABASE` (from host env and/or `~/.cursor/.env` loaded by the launcher). The launcher sets `NEO4J_URL=bolt://neo4j:7687` (image uses **`NEO4J_URL`**, not `NEO4J_URI`).
- **Docker images:** `neo4j:latest` (backing DB) + `mcp/neo4j-memory` (MCP server)
- **Launcher:** `mcp.json` runs `python -c` + `Path.home()/'.cursor'/'scripts'/'mcp-run-memory.py'` (avoids broken `${userHome}` path expansion on Windows that becomes `C:\c:\Users\...`). Starts Neo4j on `mcp-network` (`restart=unless-stopped`) before `docker run -i mcp/neo4j-memory`. Manual: `scripts/start-neo4j-mcp.sh` / `.ps1`.

#### Playwright
- **Purpose:** Browser automation
- **Usage:** End-to-end testing flows, web scraping (where allowed), UI validation
- **Environment variables:** None required
- **Docker image:** `mcp/playwright`

#### DuckDuckGo
- **Purpose:** External web search (free, keyless)
- **Usage:** Search for information not in repo, docs, or memory. Verify current facts and technology updates. Default fallback if `searxng` is not running.
- **Environment variables:** None required
- **Docker image:** `mcp/duckduckgo` (Docker Hub MCP Catalog; local fallback in `docker/mcp-duckduckgo/`)
- **Run contract:** `docker run -i --rm mcp/duckduckgo` only — do **not** pass `--transport=stdio` (image has no ENTRYPOINT; extra args replace CMD and break startup).

#### SearXNG
- **Purpose:** External web search, aggregated engines (Google/Bing/Brave/DuckDuckGo/Wikipedia) — free, keyless, self-hosted
- **Usage:** Preferred default search tool (more resilient than a single engine). Also has a `fetch`-style capability in some wrapper variants for single-page markdown extraction.
- **Environment variables:** `SEARXNG_SECRET` (low-sensitivity, auto-generated by the start script if unset)
- **Docker images:** `searxng/searxng` (engine, started via `scripts/start-searxng.sh`, **not** started by Cursor) + `isokoliuk/mcp-searxng` (MCP wrapper, public image, referenced directly in `mcp.json`)
- **Setup:** see [docker/mcp-searxng/README.md](../docker/mcp-searxng/README.md)
- **One-time step:** `./scripts/start-searxng.sh` must be run once (and after every machine reboot, unless you configure Docker to restart it) before the `searxng` MCP entry can connect — this is a backing service, not itself an MCP server, same pattern as `neo4j` for `memory`.

#### GitHub
- **Purpose:** GitHub repository operations
- **Usage:** Inspect and modify remote repositories (only when explicitly asked). Never perform destructive operations without explicit confirmation.
- **Environment variables:** `GITHUB_PERSONAL_ACCESS_TOKEN` (Cursor process env / `.env`; interpolated as `${env:GITHUB_PERSONAL_ACCESS_TOKEN}` — never hardcode the PAT)
- **Connection:** Official remote Streamable HTTP `https://api.githubcopilot.com/mcp/` ([install guide](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-cursor.md)). Requires Cursor v0.48.0+.
- **Not Docker:** local `docker/mcp-github/` and `mcp/github` image are removed.

#### Grafana
- **Purpose:** Metrics and dashboards
- **Usage:** Query metrics and logs for debugging, performance investigations. All operations are read-only unless explicitly approved.
- **Environment variables:** `GRAFANA_URL`, `GRAFANA_API_KEY`
- **Docker image:** `mcp/grafana`

#### Shrimp Task Manager
- **Purpose:** Task planning and execution
- **Usage:** Create task plans for complex work, track execution and reflect on results, store project rules and conventions
- **Environment variables:** `DATA_DIR`, `TEMPLATES_USE`, `ENABLE_GUI`, plus `MCP_PROMPT_*` variables for customization
- **Docker image:** `mcp/shrimp` (built from `docker/mcp-shrimp/Dockerfile`)

#### Context7
- **Purpose:** Version-specific documentation and code examples for libraries/frameworks
- **Usage:** When implementing against third-party APIs where training data may be stale; prompt with "use context7" or activate skill `mcp-context7-docs`. Not for general web search (use searxng/duckduckgo).
- **Environment variables:** `CONTEXT7_API_KEY` in `~/.cursor/.env` (KeePass `API Keys/Context7`). See **[mcp-secrets.md](mcp-secrets.md)**.
- **Connection:** Stdio via `scripts/mcp-run-context7.py` (loads `.env`, runs `@upstash/context7-mcp`). Requires Node.js 18+ / `npx` on PATH.

## Execution Model

Transports are mixed. Docker stdio is only one of them.

**Docker (leftover catalog + intentional self-hosted):**

```json
{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e", "ENV_VAR_NAME",
    "mcp/server-name",
    "--transport=stdio"
  ]
}
```

**Remote Streamable HTTP (GitHub):**

```json
{
  "url": "https://api.githubcopilot.com/mcp/",
  "headers": {
    "Authorization": "Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}"
  }
}
```

`${env:NAME}` is Cursor / VS Code interpolation. Do **not** put a raw PAT in `mcp.json`. `${VAR}` / `$VAR` are **not** expanded — use `${env:VAR}` for remote headers, or a launcher that reads `.env`.

**Exception — DuckDuckGo:** the Hub image has no `ENTRYPOINT`. Do not append `--transport=stdio` (or any args) after the image name; they replace `CMD` and the container fails to start.

**Benefits of each transport:**
- **Remote** — no image pull / cold start; vendor hosts the server (GitHub, Apify)
- **Docker** — same image on Windows and WSL; isolation; required for self-hosted `searxng` / Neo4j
- **Launcher** — reads `~/.cursor/.env` without relying on Docker `-e` from the Cursor process
- **Security** — all secrets via environment variables / `${env:…}` interpolation

## Environment Variables

Secrets and API keys: **[mcp-secrets.md](mcp-secrets.md)** (KeePass → `.env`, verify, troubleshooting).

**IMPORTANT:** Docker MCPs and the GitHub remote (`${env:GITHUB_PERSONAL_ACCESS_TOKEN}`) need variables in the **Cursor process environment** (often via `setup-env-vars.*` after editing `.env`). Launchers **memory** and **context7** read `~/.cursor/.env` directly.

**Common variables:** `NEO4J_*`, `GITHUB_PERSONAL_ACCESS_TOKEN`, `GRAFANA_URL`, `GRAFANA_API_KEY`, `POSTMAN_API_KEY`, `PERPLEXITY_API_KEY`, `CONTEXT7_API_KEY` — see [`.env.example`](../.env.example).

Full setup: [configuration.md](configuration.md).

## Docker Images

### Official Images (Docker Hub MCP Catalog)

- **mcp/grafana** - Grafana MCP server
- **mcp/playwright** - Playwright browser automation
- **mcp/duckduckgo** - DuckDuckGo web search
- **mcp/neo4j-memory** - Neo4j Memory MCP server

### Public Community Images (no custom Dockerfile needed)

- **isokoliuk/mcp-searxng** - SearXNG MCP wrapper ([source](https://github.com/ihor-sokoliuk/MCP-searxng))
- **searxng/searxng** - SearXNG engine itself (backing service, not an MCP server — started via `scripts/start-searxng.sh`, analogous to the `neo4j:latest` backing container for `memory`)

### Custom Images

Custom Dockerfiles are available in `docker/mcp-*/`:
- `docker/mcp-memory/` - Neo4j Memory MCP Server (if not available on Docker Hub)
- `docker/mcp-duckduckgo/` - DuckDuckGo MCP Server (if not available on Docker Hub)
- `docker/mcp-shrimp/` - Shrimp Task Manager (clones and builds from GitHub)
- `docker/mcp-searxng/` - **Not a build recipe** — holds `settings.yml` config mounted into the public `searxng/searxng` engine image, plus setup docs (see [docker/mcp-searxng/README.md](../docker/mcp-searxng/README.md))

## Managing Docker Images

### Check Available Images

```bash
# Windows
.\scripts\check-docker-images.ps1

# WSL
./scripts/check-docker-images.sh
```

This script checks if images exist locally, verifies availability on Docker Hub, and reports which images need to be built.

### Pull Latest Images

```bash
docker pull mcp/grafana
docker pull mcp/playwright
docker pull mcp/duckduckgo
docker pull mcp/neo4j-memory
docker pull neo4j:latest
docker pull isokoliuk/mcp-searxng
docker pull searxng/searxng
```

### Build Custom Images

For servers without official images, build from Dockerfiles:

```bash
# Windows
.\scripts\build-mcp-images.ps1 --all

# WSL
./scripts/build-mcp-images.sh --all
```

Or build individual images:
```bash
.\scripts\build-mcp-images.ps1 --memory
.\scripts\build-mcp-images.ps1 --duckduckgo
.\scripts\build-mcp-images.ps1 --shrimp
```

## Docker Volumes

### Shrimp Task Manager Data

Shrimp uses a Docker named volume for data persistence:

```bash
# Create volume (one-time setup)
docker volume create shrimp_data

# Backup data
docker run --rm -v shrimp_data:/data -v $(pwd):/backup alpine tar czf /backup/shrimp_backup.tar.gz -C /data .

# Restore data
docker run --rm -v shrimp_data:/data -v $(pwd):/backup alpine tar xzf /backup/shrimp_backup.tar.gz -C /data
```

**Advantages:**
- Works identically in Windows and WSL
- Data persists independently of host filesystem
- No path synchronization issues

## Testing

Test all MCP servers with:
- **Windows**: `.\scripts\test-mcp-servers.ps1`
- **WSL**: `./scripts/test-mcp-servers.sh`

Tests verify:
- Docker availability (for Docker-backed entries)
- Image presence (local or Docker Hub)
- Remote/URL entries (GitHub official endpoint + env interpolation)
- Security (no hardcoded secrets)
- Environment variable configuration
- Server health

Results are saved to `test-results/mcp-test-YYYYMMDD-HHMMSS.json` and HTML reports.

## Troubleshooting

### Image Not Found

If an image is not found:
1. Check if it exists on Docker Hub: `docker manifest inspect mcp/image-name`
2. Pull the image: `docker pull mcp/image-name`
3. If not available, build from Dockerfile: `.\scripts\build-mcp-images.ps1 --image-name`

### Environment Variables Not Working

1. Verify variables are set in WSL: `echo $VAR_NAME`
2. Check `mcp.json` uses `-e VAR_NAME` (not hardcoded values)
3. Restart Cursor after setting variables

### Docker Not Available

1. Ensure Docker Desktop is running (Windows)
2. Verify Docker is accessible: `docker --version`
3. Check WSL integration in Docker Desktop settings

### MCP Servers Not Starting

1. Verify Docker is running: `docker --version`
2. Verify environment variables are set (check with `echo $VAR_NAME` in WSL)
3. Check Docker images exist: `docker images | grep mcp`
4. Run test script: `.\scripts\test-mcp-servers.ps1`

### Volume Mount Issues

If using volume mounts (not recommended for cross-platform):
- **Windows:** Use `\\wsl.localhost\Ubuntu\...` paths
- **WSL:** Use `/home/...` paths
- **Better:** Use Docker named volumes (see Shrimp example above)

## Security

- **No secrets in `mcp.json`** - all sensitive data via environment variables
- **Secrets in `.env`** - not committed (rotate regularly)
- **KeePass integration** - recommended for production secret management
- **Never hardcode secrets** in `mcp.json`
- **Use environment variables** for all sensitive data (`-e VAR_NAME` or `${env:VAR_NAME}` on remotes)
- **Set variables in the Cursor process** (User env / WSL profile) so Docker `-e` and remote `${env:…}` resolve
- **Rotate secrets regularly**

## Version Management

| MCP Server | Current Version | Update Strategy |
|------------|----------------|----------------|
| memory | `mcp/neo4j-memory` + `neo4j` (Docker; launcher) | `docker pull mcp/neo4j-memory && docker pull neo4j:latest` |
| playwright | `mcp/playwright` (Docker) | `docker pull mcp/playwright` |
| duckduckgo | `mcp/duckduckgo` (Docker) | `docker pull mcp/duckduckgo` |
| searxng | `isokoliuk/mcp-searxng` + `searxng/searxng` (Docker) | `docker pull isokoliuk/mcp-searxng && docker pull searxng/searxng`, then re-run `scripts/start-searxng.sh` |
| github | official remote `https://api.githubcopilot.com/mcp/` | hosted; keep `GITHUB_PERSONAL_ACCESS_TOKEN` in `.env` |
| grafana | `mcp/grafana` (Docker) | `docker pull mcp/grafana` |
| shrimp-task-manager | `mcp/shrimp` (Docker, built from GitHub) | Rebuild from source |

**Update Process:**
1. Pull latest images: `docker pull mcp/server-name`
2. For custom images: `.\scripts\build-mcp-images.ps1 --all`
3. Restart Cursor to apply changes

## Rollback Plan

If you need to revert to the previous configuration (WSL-based execution):

### Quick Rollback

1. **Restore from backup:**
   ```bash
   # Windows
   Copy-Item "$env:USERPROFILE\.cursor\mcp.json.backup.*" "$env:USERPROFILE\.cursor\mcp.json" -Force
   
   # WSL
   cp ~/.cursor/mcp.json.backup.* ~/.cursor/mcp.json
   ```

2. **Restore wrapper scripts (if needed):**
   ```bash
   # Windows
   Copy-Item "$env:USERPROFILE\.cursor\scripts\archive\mcp-run-*.ps1" "$env:USERPROFILE\.cursor\scripts\" -Force
   
   # WSL
   cp ~/.cursor/scripts/archive/mcp-run-*.sh ~/.cursor/scripts/
   ```

3. **Restart Cursor** to apply changes

### Full Rollback

1. Restore `mcp.json` from Git history:
   ```bash
   git checkout HEAD~1 -- mcp.json
   ```

2. Verify configuration:
   ```bash
   .\scripts\verify-config.ps1
   ```

3. Test MCP servers in Cursor

### Troubleshooting Rollback

- **Docker images still present:** Safe to keep, won't interfere
- **Volume mounts:** Docker volumes (`shrimp_data`) persist independently
- **Environment variables:** No changes needed, same variables work for both approaches

## References

- [Docker Hub MCP Catalog](https://hub.docker.com/mcp)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Docker Documentation](https://docs.docker.com)
