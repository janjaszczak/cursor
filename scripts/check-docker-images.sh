#!/bin/bash
# Script to check availability of Docker images from Docker Hub MCP Catalog
# Verifies which MCP server images are available and can be used
#
# Usage: ./scripts/check-docker-images.sh

set -e

echo ""
echo "=== Checking Docker Images from MCP Catalog ==="
echo ""

# List of MCP servers to check
declare -a servers=(
    "grafana:mcp/grafana:"
    "github:mcp/github:"
    "playwright:mcp/playwright:"
    "duckduckgo:mcp/duckduckgo:"
    "memory:mcp/neo4j-memory:"
    "shrimp:mcp/shrimp:"
    "postman:mcp/postman:"
)

available_images=()
missing_images=()
results=()

for server_info in "${servers[@]}"; do
    IFS=':' read -r name primary_image alt_image <<< "$server_info"
    
    echo "Checking $name..."
    found=false
    image_name=""
    
    # Check primary image locally
    if docker images "$primary_image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
        found=true
        image_name="$primary_image"
        echo "  ✓ Found locally: $image_name"
    else
        # Check Docker Hub
        if docker manifest inspect "$primary_image" >/dev/null 2>&1; then
            found=true
            image_name="$primary_image"
            echo "  ✓ Available on Docker Hub: $image_name"
        fi
    fi
    
    # Check alternative image if primary not found
    if [ "$found" = false ] && [ -n "$alt_image" ]; then
        if docker images "$alt_image" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
            found=true
            image_name="$alt_image"
            echo "  ✓ Found locally (alt): $image_name"
        elif docker manifest inspect "$alt_image" >/dev/null 2>&1; then
            found=true
            image_name="$alt_image"
            echo "  ✓ Available on Docker Hub (alt): $image_name"
        fi
    fi
    
    if [ "$found" = true ]; then
        available_images+=("$name:$image_name")
        results+=("{\"name\":\"$name\",\"status\":\"Available\",\"image\":\"$image_name\"}")
    else
        missing_images+=("$name")
        results+=("{\"name\":\"$name\",\"status\":\"Missing\",\"image\":\"\"}")
        echo "  ⚠ Image not found - will need Dockerfile"
    fi
done

# Summary
echo ""
echo "=== Summary ==="
echo "Available images: ${#available_images[@]}"
echo "Missing images: ${#missing_images[@]}"

if [ ${#available_images[@]} -gt 0 ]; then
    echo ""
    echo "Available Docker images:"
    for img in "${available_images[@]}"; do
        IFS=':' read -r name image <<< "$img"
        echo "  - $name: $image"
    done
fi

if [ ${#missing_images[@]} -gt 0 ]; then
    echo ""
    echo "Images requiring Dockerfile:"
    for name in "${missing_images[@]}"; do
        echo "  - $name"
    fi
fi

# Export results to JSON
output_dir="$HOME/.cursor/test-results"
mkdir -p "$output_dir"
output_path="$output_dir/docker-images-check-$(date +%Y%m%d-%H%M%S).json"

echo "[" > "$output_path"
for i in "${!results[@]}"; do
    echo -n "${results[$i]}" >> "$output_path"
    if [ $i -lt $((${#results[@]} - 1)) ]; then
        echo "," >> "$output_path"
    fi
done
echo "" >> "$output_path"
echo "]" >> "$output_path"

echo ""
echo "Results saved to: $output_path"

exit $(if [ ${#missing_images[@]} -gt 0 ]; then 1; else 0; fi)
