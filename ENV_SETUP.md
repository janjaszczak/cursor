# Environment Variables Setup

## Quick Start

1. **Edit `env.local` file** with your actual secrets
2. **Run setup script** to load variables into system

## File: `env.local`

This file contains all environment variables needed for MCP servers. It's **NOT** in `.gitignore`, so you can commit it to the repository.

### Current Status

- ✅ `GITHUB_PERSONAL_ACCESS_TOKEN` - Set
- ✅ `GRAFANA_API_KEY` - Set  
- ⚠️ `NEO4J_PASSWORD` - Needs to be set (database can be set up fresh)

### Setting Neo4j Password

Since you mentioned the database can be set up fresh, you can:

1. **Set a new password** when setting up Neo4j:
   ```bash
   # In Neo4j, set initial password or reset it
   ```

2. **Update `env.local`**:
   ```
   NEO4J_PASSWORD=your_new_password_here
   ```

3. **Run setup script again** to apply changes

## Running Setup Scripts

### Windows (as Administrator)
```powershell
# Right-click PowerShell -> Run as Administrator
cd C:\Users\janja\OneDrive\Dokumenty\GitHub\ai
.\scripts\setup-env-vars.ps1
```

### WSL
```bash
cd /mnt/c/Users/janja/OneDrive/Dokumenty/GitHub/ai
./scripts/setup-env-vars.sh
# Or with sudo for system-wide:
sudo ./scripts/setup-env-vars.sh
```

## How It Works

1. Script reads `env.local` file from repo root
2. Parses KEY=VALUE pairs (ignores comments and empty lines)
3. Sets environment variables in system/user profile
4. Skips variables marked as `CHANGE_ME` or empty

## Security Notes

- `env.local` is committed to Git (not in .gitignore)
- Rotate secrets regularly
- Consider using KeePass for sensitive values if needed
- For production, use proper secret management

## Troubleshooting

### Script says "env.local not found"
- Script will create a template file automatically
- Edit the template and run script again

### Variables not loading
- Check `env.local` file format (KEY=VALUE, one per line)
- Ensure no spaces around `=` sign
- Comments start with `#`

### Neo4j connection fails
- Verify Neo4j is running: `docker ps` or check service
- Check `NEO4J_URI` matches your Neo4j instance
- Verify password matches Neo4j database password
