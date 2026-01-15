# MCP Update Strategy

This document outlines the strategy for updating MCP (Model Context Protocol) servers used in this project.

## Version Pinning

### Current MCP Servers

| MCP Server | Current Version | Update Strategy |
|------------|----------------|----------------|
| memory (Neo4j) | `@sylweriusz/mcp-neo4j-memory-server` | `-y` (latest) |
| playwright | `@playwright/mcp@latest` | `@latest` |
| duckduckgo | `duckduckgo-mcp-server` | Latest via uvx |
| github | `github-mcp-custom@1.0.20` | **Pinned** |
| grafana | `mcp/grafana` | Latest Docker image |
| shrimp-task-manager | Local build | Manual update |

### Pinning Strategy

**Stable/Production MCPs:**
- Pin to specific versions (e.g., `github-mcp-custom@1.0.20`)
- Review and update monthly or when security updates are available

**Development/Utility MCPs:**
- Use `@latest` or `-y` for automatic updates
- Monitor for breaking changes

**Local Builds:**
- Update manually by pulling latest from source and rebuilding

## Update Process

### Monthly Review Checklist

1. **Check for updates:**
   ```bash
   # For npm packages
   npm outdated -g
   
   # For Docker images
   docker images | grep mcp
   ```

2. **Review changelogs:**
   - Check GitHub releases for each MCP
   - Review breaking changes
   - Assess security updates

3. **Test updates:**
   - Update one MCP at a time
   - Test in isolated environment first
   - Verify all functionality still works

4. **Update configuration:**
   - Update version in `.cursor/mcp.json`
   - Update this document
   - Commit changes

### Updating Specific MCPs

#### npm-based MCPs (memory, playwright, github)

These use `npx` with `-y` flag or specific versions. To update:

1. Check current version in `.cursor/mcp.json`
2. Test new version:
   ```bash
   npx -y @package/name@new-version
   ```
3. Update `.cursor/mcp.json` if pinning
4. Restart Cursor and verify

#### Docker-based MCPs (grafana)

```bash
# Pull latest image
docker pull mcp/grafana

# Test
docker run -i --rm -e GRAFANA_URL -e GRAFANA_API_KEY mcp/grafana --transport=stdio
```

#### Shrimp Task Manager (local build)

```bash
cd ~/mcp-shrimp-task-manager
git pull origin main
npm install
npm run build
# Restart Cursor
```

## Version Control

- **Never commit secrets** - all secrets must be in environment variables
- **Document breaking changes** - update this file when MCP behavior changes
- **Tag stable configurations** - use Git tags for known-good MCP combinations

## Security Considerations

1. **Regular updates** - Security patches should be applied promptly
2. **Version pinning** - Pin production MCPs to avoid unexpected changes
3. **Audit dependencies** - Run `npm audit` for npm-based MCPs
4. **Monitor CVEs** - Check for known vulnerabilities in MCP dependencies

## Rollback Procedure

If an MCP update causes issues:

1. Revert `.cursor/mcp.json` to previous version
2. For local builds, checkout previous commit:
   ```bash
   cd ~/mcp-shrimp-task-manager
   git checkout <previous-commit>
   npm install && npm run build
   ```
3. Restart Cursor
4. Document the issue for future reference

## Automation (Future)

Consider automating MCP updates:
- Weekly check for updates
- Automated testing pipeline
- Automated PR creation for safe updates
