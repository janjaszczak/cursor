#!/bin/bash
# Script to build Docker images for MCP servers
# Builds custom Docker images for servers that don't have official images
#
# Usage: ./scripts/build-mcp-images.sh [--all] [--memory] [--duckduckgo]

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker_dir="$script_dir/../docker"

echo ""
echo "=== Building MCP Docker Images ==="
echo ""

if [ ! -d "$docker_dir" ]; then
    echo "Error: Docker directory not found: $docker_dir" >&2
    exit 1
fi

built_images=()

# Parse arguments
build_all=false
build_memory=false
build_duckduckgo=false
build_github=false
build_shrimp=false

for arg in "$@"; do
    case $arg in
        --all)
            build_all=true
            ;;
        --memory)
            build_memory=true
            ;;
        --duckduckgo)
            build_duckduckgo=true
            ;;
        --github)
            build_github=true
            ;;
        --shrimp)
            build_shrimp=true
            ;;
    esac
done

# If no specific flags, build all
if [ "$build_all" = false ] && [ "$build_memory" = false ] && [ "$build_duckduckgo" = false ] && [ "$build_github" = false ] && [ "$build_shrimp" = false ]; then
    build_all=true
fi

# Build memory image
if [ "$build_all" = true ] || [ "$build_memory" = true ]; then
    memory_dir="$docker_dir/mcp-memory"
    if [ -d "$memory_dir" ]; then
        echo "Building mcp/memory..."
        if docker build -t mcp/memory:latest "$memory_dir"; then
            echo "  ✓ mcp/memory built successfully"
            built_images+=("mcp/memory:latest")
        else
            echo "  ✗ Failed to build mcp/memory" >&2
            exit 1
        fi
    fi
fi

# Build duckduckgo image
if [ "$build_all" = true ] || [ "$build_duckduckgo" = true ]; then
    duckduckgo_dir="$docker_dir/mcp-duckduckgo"
    if [ -d "$duckduckgo_dir" ]; then
        echo "Building mcp/duckduckgo..."
        if docker build -t mcp/duckduckgo:latest "$duckduckgo_dir"; then
            echo "  ✓ mcp/duckduckgo built successfully"
            built_images+=("mcp/duckduckgo:latest")
        else
            echo "  ✗ Failed to build mcp/duckduckgo" >&2
            exit 1
        fi
    fi
fi

# Build github image
if [ "$build_all" = true ] || [ "$build_github" = true ]; then
    github_dir="$docker_dir/mcp-github"
    if [ -d "$github_dir" ]; then
        echo "Building mcp/github..."
        if docker build -t mcp/github:latest "$github_dir"; then
            echo "  ✓ mcp/github built successfully"
            built_images+=("mcp/github:latest")
        else
            echo "  ✗ Failed to build mcp/github" >&2
            exit 1
        fi
    fi
fi

# Build shrimp image
if [ "$build_all" = true ] || [ "$build_shrimp" = true ]; then
    shrimp_dir="$docker_dir/mcp-shrimp"
    if [ -d "$shrimp_dir" ]; then
        echo "Building mcp/shrimp..."
        if docker build -t mcp/shrimp:latest "$shrimp_dir"; then
            echo "  ✓ mcp/shrimp built successfully"
            built_images+=("mcp/shrimp:latest")
        else
            echo "  ✗ Failed to build mcp/shrimp" >&2
            exit 1
        fi
    fi
fi

echo ""
echo "=== Summary ==="
echo "Built images: ${#built_images[@]}"
for img in "${built_images[@]}"; do
    echo "  - $img"
done

if [ ${#built_images[@]} -eq 0 ]; then
    echo ""
    echo "No images were built. Use --all, --memory, --duckduckgo, --github, or --shrimp flags." >&2
    exit 1
fi

exit 0
