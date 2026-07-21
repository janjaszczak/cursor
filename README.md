# Cursor Configuration Repository

This repository serves as the **single source of truth** for Cursor IDE configuration across Windows and WSL environments.

## Quick Start

1. **Set `CURSOR_CONFIG_DIR`** to point to this user directory:
   - Windows: `C:\Users\janja\.cursor`
   - WSL: `~/.cursor`
2. **Configure MCP environment variables** in WSL (see [doc/configuration.md](doc/configuration.md))
3. **Restart Cursor** to apply changes

## Documentation

All documentation is in the **[doc/](doc/)** directory:

- **[doc/configuration.md](doc/configuration.md)** - Complete configuration guide and current setup (start here)
- **[doc/mcp.md](doc/mcp.md)** - MCP server configuration, Docker management, and troubleshooting
- **[doc/rules.md](doc/rules.md)** - Project rules and conventions
- **[doc/commands.md](doc/commands.md)** - Custom Cursor commands

## Project Structure

```
~/.cursor/                # User Cursor configuration (single source of truth)
├── USER_RULES.txt        # Global rules → Settings → User Rules (all projects)
├── AGENTS.default.md     # Global AGENTS fallback when repo has no AGENTS.md
├── agents/               # Subagents (per user, all projects)
├── .cursorignore         # Indexing exclusions for this workspace
├── mcp.json              # MCP server configurations
├── cli-config.json        # CLI permissions
├── commands/             # Custom commands
├── scripts/               # Setup and utility scripts
│   ├── setup-env-vars.*  # Environment variable setup
│   ├── verify-config.*   # Configuration verification
│   ├── get-keepass-secret.*  # KeePassXC secret retrieval
│   ├── save-keepass-password-to-keyring.*  # KeePass keyring setup
│   ├── keepass_ops.py    # KeePass get/add/update (Python)
│   ├── build-mcp-images.*  # Build MCP Docker images
│   ├── check-docker-images.*  # Check MCP image availability
│   └── test-mcp-servers.*  # Test MCP server configuration
├── doc/                  # Documentation
├── .env.example          # Template for .env
└── README.md             # This file
```

## Key Features

- **Single source of truth**: All Cursor config in `.cursor/` directory
- **Cross-platform**: Works on Windows and WSL with same configuration
- **MCP servers**: All MCPs run in Docker containers for cross-platform consistency
- **Git**: Use `git pull` / `git push` or your preferred method to sync configuration across machines
- **Secure**: Secrets in environment variables, not in config files

## MCP Servers

This configuration includes 12 servers. Free/self-hosted (no per-request cost) are preferred as defaults; paid APIs are kept as explicit escalation paths:

**Free / self-hosted (default tools):**
- **memory** (Neo4j) - Persistent knowledge storage
- **playwright** - Browser automation
- **duckduckgo** - Web search (keyless)
- **searxng** - Web search, aggregated engines (self-hosted, see [docker/mcp-searxng](docker/mcp-searxng/README.md)) — preferred over duckduckgo for routine search
- **github** - GitHub repository operations
- **grafana** - Metrics and dashboards
- **browseros** - Visible browser automation (user's own Chromium profile)
- **shrimp-task-manager** - Task planning and execution
- **context7** - Version-specific library documentation lookup (remote MCP, no API key required to start)

**Paid APIs (use only when the free tools above are insufficient):**
- **perplexity** - Synthesized search + citations in one call; use only for explicit deep-research/high-stakes requests
- **Apify** - Actor-based scraping/crawling pipelines; audit real usage at console.apify.com before relying on it
- **postman** - API collection management (has a free tier)

See [doc/configuration.md](doc/configuration.md) for detailed setup instructions and [doc/mcp.md](doc/mcp.md) for the cost-tiering rationale.

### Cross-Platform Configuration

The `mcp.json` file is configured to work seamlessly in both Windows and WSL environments. Most MCP servers use Docker containers (from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp) or custom `docker/mcp-*` builds), providing:
- **Consistent execution** - Same behavior on Windows and WSL
- **Isolation** - Each server runs in its own container
- **Easy updates** - Pull latest images with `docker pull`
- **Security** - All secrets via environment variables, never hardcoded

**Docker-based:** memory, playwright, duckduckgo, searxng, grafana, github, shrimp-task-manager, postman, perplexity. **URL-based (no local container):** browseros (local BrowserOS), Apify (hosted), context7 (hosted docs).

### Testing MCP Servers

Test all MCP servers with:
- **Windows**: `.\scripts\test-mcp-servers.ps1`
- **WSL**: `./scripts/test-mcp-servers.sh`

This verifies:
- Docker availability and image presence
- Security (no hardcoded secrets)
- Environment variable configuration
- Server health checks

See [doc/mcp.md](doc/mcp.md) for complete MCP documentation including Docker management.

## Understanding Duplicates

**Why duplicates occur:** Cursor automatically creates a `.cursor/` directory in any folder you open. If you have:
- A global `.cursor/` in `%USERPROFILE%\.cursor\` (Windows) or `~/.cursor/` (WSL)
- A project `.cursor/` in the repository
- `CURSOR_CONFIG_DIR` pointing to the repo

Cursor may load configurations from multiple locations, causing duplicates.

**Solution:** Use `CURSOR_CONFIG_DIR` to point to a single source of truth (user `.cursor/` directory), and minimize global configs to empty `mcpServers: {}`.

This principle applies to **all Cursor configuration** (rules, MCP, CLI config), not just MCP servers.

See [doc/configuration.md](doc/configuration.md) for fixing duplicate issues.

## Getting Help

- **Configuration and Setup**: See [doc/configuration.md](doc/configuration.md)
- **MCP Servers**: See [doc/mcp.md](doc/mcp.md)