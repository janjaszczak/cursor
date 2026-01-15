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

- **[doc/configuration.md](doc/configuration.md)** - Complete configuration guide (start here)
- **[doc/mcp.md](doc/mcp.md)** - MCP server configuration, usage, and updates
- **[doc/rules.md](doc/rules.md)** - Project rules and conventions
- **[doc/commands.md](doc/commands.md)** - Custom Cursor commands
- **[doc/setup.md](doc/setup.md)** - Current setup state
- **[doc/troubleshooting.md](doc/troubleshooting.md)** - Troubleshooting guide

## Project Structure

```
~/.cursor/                # User Cursor configuration (single source of truth)
├── rules/                # Project rules and conventions
├── mcp.json              # MCP server configurations
├── cli-config.json        # CLI permissions
├── commands/             # Custom commands
├── scripts/               # Setup and utility scripts
│   ├── setup-env-vars.*  # Environment variable setup
│   ├── sync-repo.*       # Git repository synchronization
│   ├── verify-config.*   # Configuration verification
│   └── fix-mcp-duplicates.*  # Fix MCP duplicate issues
├── doc/                  # Documentation
├── env.local.example     # Template for env.local
└── README.md             # This file
```

## Key Features

- **Single source of truth**: All Cursor config in `.cursor/` directory
- **Cross-platform**: Works on Windows and WSL with same configuration
- **MCP servers**: All MCPs run in WSL for consistency
- **Git sync**: Scripts to synchronize configuration across machines
- **Secure**: Secrets in environment variables, not in config files

## MCP Servers

This configuration includes:
- **memory** (Neo4j) - Persistent knowledge storage
- **playwright** - Browser automation
- **duckduckgo** - Web search
- **github** - GitHub repository operations
- **grafana** - Metrics and dashboards
- **shrimp-task-manager** - Task planning and execution

See [doc/configuration.md](doc/configuration.md) for detailed setup instructions.

### Cross-Platform Configuration

The `mcp.json` file is configured to work seamlessly in both Windows and WSL environments. Most MCP servers use Docker containers from the [Docker Hub MCP Catalog](https://hub.docker.com/mcp), providing:
- **Consistent execution** - Same behavior on Windows and WSL
- **Isolation** - Each server runs in its own container
- **Easy updates** - Pull latest images with `docker pull`
- **Security** - All secrets via environment variables, never hardcoded

**Docker-based servers:** memory, playwright, duckduckgo, grafana
**WSL-based servers:** github, shrimp-task-manager (not yet migrated)

### Testing MCP Servers

Test all MCP servers with:
- **Windows**: `.\scripts\test-mcp-servers.ps1`
- **WSL**: `./scripts/test-mcp-servers.sh`

This verifies:
- Docker availability and image presence
- Security (no hardcoded secrets)
- Environment variable configuration
- Server health checks

See [doc/mcp.md](doc/mcp.md) for more details on the execution model and Docker setup.

## Understanding Duplicates

**Why duplicates occur:** Cursor automatically creates a `.cursor/` directory in any folder you open. If you have:
- A global `.cursor/` in `%USERPROFILE%\.cursor\` (Windows) or `~/.cursor/` (WSL)
- A project `.cursor/` in the repository
- `CURSOR_CONFIG_DIR` pointing to the repo

Cursor may load configurations from multiple locations, causing duplicates.

**Solution:** Use `CURSOR_CONFIG_DIR` to point to a single source of truth (user `.cursor/` directory), and minimize global configs to empty `mcpServers: {}`.

This principle applies to **all Cursor configuration** (rules, MCP, CLI config), not just MCP servers.

See [doc/troubleshooting.md](doc/troubleshooting.md) for detailed fix instructions.

## Getting Help

- **Configuration**: See [doc/configuration.md](doc/configuration.md)
- **Troubleshooting**: See [doc/troubleshooting.md](doc/troubleshooting.md)
- **MCP details**: See [doc/mcp.md](doc/mcp.md)