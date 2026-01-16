#!/bin/bash
# Verification script for Cursor configuration (WSL version)
# Checks that all components are properly configured

set -e

errors=()
warnings=()

echo ""
echo "=== Cursor Configuration Verification ==="
echo ""

# Check CURSOR_CONFIG_DIR
echo "Checking CURSOR_CONFIG_DIR..."
if [ -n "$CURSOR_CONFIG_DIR" ]; then
    if [ -d "$CURSOR_CONFIG_DIR" ]; then
        echo "  ✓ CURSOR_CONFIG_DIR is set: $CURSOR_CONFIG_DIR"
    else
        errors+=("CURSOR_CONFIG_DIR points to non-existent path: $CURSOR_CONFIG_DIR")
        echo "  ✗ CURSOR_CONFIG_DIR path does not exist"
    fi
else
    errors+=("CURSOR_CONFIG_DIR is not set")
    echo "  ✗ CURSOR_CONFIG_DIR is not set"
fi

# Check user .cursor directory
echo ""
echo "Checking user .cursor directory..."
USER_CURSOR_PATH="$HOME/.cursor"
if [ -d "$USER_CURSOR_PATH" ]; then
    echo "  ✓ User .cursor directory exists"
    
    # Check for required files
    for file in mcp.json cli-config.json; do
        if [ -f "$USER_CURSOR_PATH/$file" ]; then
            echo "    ✓ $file exists"
        else
            errors+=("Required file missing: $file")
            echo "    ✗ $file missing"
        fi
    done
    
    # Check rules directory
    if [ -d "$USER_CURSOR_PATH/rules" ]; then
        rule_count=$(find "$USER_CURSOR_PATH/rules" -name "*.mdc" | wc -l)
        echo "    ✓ Rules directory exists ($rule_count rules)"
    else
        warnings+=("Rules directory not found")
        echo "    ⚠ Rules directory not found"
    fi
else
    errors+=("User .cursor directory does not exist")
    echo "  ✗ User .cursor directory does not exist"
fi

# Check environment variables
echo ""
echo "Checking MCP environment variables..."
required_vars=(
    "NEO4J_URI"
    "NEO4J_USERNAME"
    "NEO4J_PASSWORD"
    "NEO4J_DATABASE"
    "GITHUB_PERSONAL_ACCESS_TOKEN"
    "GRAFANA_URL"
    "GRAFANA_API_KEY"
    "POSTMAN_API_KEY"
)

for var in "${required_vars[@]}"; do
    value="${!var}"
    if [ -n "$value" ]; then
        if [[ "$value" =~ ^\<SET_FROM_KEEPASS\>|^$ ]]; then
            warnings+=("$var is not set (placeholder or empty)")
            echo "  ⚠ $var is not set (needs KeePass)"
        else
            echo "  ✓ $var is set"
        fi
    else
        warnings+=("$var is not set")
        echo "  ⚠ $var is not set"
    fi
done

# Check Docker availability
echo ""
echo "Checking Docker..."
if docker --version >/dev/null 2>&1; then
    echo "  ✓ Docker is available"
    
    # Check Docker images for MCP servers
    mcp_images=("mcp/grafana" "mcp/playwright" "mcp/duckduckgo" "mcp/neo4j-memory" "mcp/github" "mcp/shrimp" "mcp/postman")
    for image in "${mcp_images[@]}"; do
        if docker images "$image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
            echo "    ✓ Image exists: $image"
        elif docker manifest inspect "$image" >/dev/null 2>&1; then
            echo "    ✓ Image available on Docker Hub: $image"
        else
            warnings+=("Docker image not found: $image")
            echo "    ⚠ Image not found: $image"
        fi
    done
else
    errors+=("Docker is not available")
    echo "  ✗ Docker is not available"
fi

# Check Shrimp Docker image and volume
echo ""
echo "Checking Shrimp Task Manager..."
if docker images mcp/shrimp --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
    echo "  ✓ Shrimp Docker image exists: mcp/shrimp"
elif docker manifest inspect mcp/shrimp >/dev/null 2>&1; then
    echo "  ✓ Shrimp image available on Docker Hub: mcp/shrimp"
else
    warnings+=("Shrimp Docker image (mcp/shrimp) not found - needs build")
    echo "  ⚠ Shrimp image not found - run: ./scripts/build-mcp-images.sh --shrimp"
fi

# Check if Docker volume exists
if docker volume ls --format "{{.Name}}" | grep -q "^shrimp_data$"; then
    echo "  ✓ Shrimp data volume exists: shrimp_data"
else
    warnings+=("Shrimp data volume (shrimp_data) not found - will be created on first run")
    echo "  ℹ Shrimp volume will be created automatically on first run"
fi

# Check sync scripts
echo ""
echo "Checking sync scripts..."
USER_CURSOR_PATH="$HOME/.cursor"
for script in "$USER_CURSOR_PATH/scripts/sync-repo.ps1" "$USER_CURSOR_PATH/scripts/sync-repo.sh"; do
    if [ -f "$script" ]; then
        echo "  ✓ $(basename $script) exists"
    else
        warnings+=("Sync script missing: $script")
        echo "  ⚠ $(basename $script) missing"
    fi
done

# Summary
echo ""
echo "=== Verification Summary ==="
if [ ${#errors[@]} -eq 0 ] && [ ${#warnings[@]} -eq 0 ]; then
    echo "✓ All checks passed!"
    exit 0
else
    if [ ${#errors[@]} -gt 0 ]; then
        echo ""
        echo "Errors (${#errors[@]}):"
        for error in "${errors[@]}"; do
            echo "  ✗ $error"
        done
    fi
    if [ ${#warnings[@]} -gt 0 ]; then
        echo ""
        echo "Warnings (${#warnings[@]}):"
        for warning in "${warnings[@]}"; do
            echo "  ⚠ $warning"
        done
    fi
    exit 1
fi
