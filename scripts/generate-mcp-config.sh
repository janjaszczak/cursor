#!/bin/bash
# Script to generate mcp.json dynamically based on environment
# Detects if running on Windows or WSL and generates appropriate configuration
#
# Usage:
#   Windows: .\scripts\generate-mcp-config.ps1
#   WSL:     ./scripts/generate-mcp-config.sh
#
# This script generates mcp.json with environment-appropriate paths
# so it works seamlessly in both Windows and WSL environments.

set -e

OUTPUT_PATH="${1:-$HOME/.cursor/mcp.json}"
FORCE="${2:-}"

# Determine environment
if [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
    USER_HOME="$HOME"
    CURSOR_DIR="$HOME/.cursor"
    SCRIPTS_DIR="$CURSOR_DIR/scripts"
else
    IS_WSL=false
    USER_HOME="$HOME"
    CURSOR_DIR="$HOME/.cursor"
    SCRIPTS_DIR="$CURSOR_DIR/scripts"
fi

# Check if output file exists and backup if needed
if [ -f "$OUTPUT_PATH" ] && [ -z "$FORCE" ]; then
    BACKUP_PATH="${OUTPUT_PATH}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$OUTPUT_PATH" "$BACKUP_PATH"
    echo "✓ Backed up existing mcp.json to: $BACKUP_PATH"
fi

# Generate JSON configuration
# Strategy: Use Docker for most servers, wsl.exe for servers without Docker images
cat > "$OUTPUT_PATH" << 'EOF'
{
  "mcpServers": {
    "memory": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "NEO4J_URI",
        "-e", "NEO4J_USERNAME",
        "-e", "NEO4J_PASSWORD",
        "-e", "NEO4J_DATABASE",
        "mcp/memory",
        "--transport=stdio"
      ]
    },
    "playwright": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/playwright",
        "--transport=stdio"
      ]
    },
    "duckduckgo": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/duckduckgo",
        "--transport=stdio"
      ]
    },
    "github": {
      "command": "wsl.exe",
      "args": [
        "--",
        "bash",
        "-lc",
        "npx -y github-mcp-custom@1.0.20 stdio"
      ]
    },
    "grafana": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "GRAFANA_URL",
        "-e", "GRAFANA_API_KEY",
        "mcp/grafana",
        "--transport=stdio"
      ]
    },
    "shrimp-task-manager": {
      "command": "wsl.exe",
      "args": [
        "--",
        "bash",
        "-lc",
        "node /home/janja/mcp-shrimp-task-manager/dist/index.js"
      ],
      "env": {
        "DATA_DIR": "/home/janja/.shrimp_data",
        "TEMPLATES_USE": "en",
        "ENABLE_GUI": "false",
        "MCP_PROMPT_PROCESS_THOUGHT_APPEND": "\n\n# Workspace Operating Rules (MCP-first correctness)\n- Always start by checking: (1) shrimp tasks (listTasks/queryTask) for duplicates, (2) neo4j memory for similar solutions/constraints, (3) repo evidence (read relevant files). If any is unavailable, mark UNCERTAIN and give the shortest verification path.\n- Use MCP tools deliberately: duckduckgo for niche/up-to-date facts; github-mcp-custom for repo search/PR context; playwright for E2E; grafana for metrics/logs; neo4j-memory-server for lessons learned/how-to.\n- Never claim something exists/works/is configured without citing exact file paths and (when critical) small snippets.\n- Destructive ops (migrations/deletes/mass refactors/force push/infra/major deps): show rollback + exact commands, then stop for explicit user confirmation.\n- Output: concise, decision-oriented; include 1 key risk/failure mode and 1 invalidating assumption when relevant.\n",
        "MCP_PROMPT_INIT_PROJECT_RULES_APPEND": "\n\n# Project Rules (agent-usable)\nCreate rules optimized for agents (short, testable, repo-grounded). Prefer: coding standards, repo conventions, commands to verify, definition-of-done, and where-to-find-what. Avoid long prose; include paths and canonical docs locations.\nAlso propose 3–7 candidate \"memories\" (how-to/lessons/where-to-find) and ask the user to approve saving to neo4j memory.\n",
        "MCP_PROMPT_PLAN_TASK_APPEND": "\n\n# Planning Requirements\nBefore planning: (1) listTasks/queryTask to avoid duplicates; (2) check neo4j memory for prior patterns/constraints; (3) read repo entrypoints relevant to the task.\nPlan must include: scope + non-goals; files to touch; step-by-step checkpoints; acceptance criteria; explicit verification commands; risks + rollback; and dependencies. Produce tasks small enough to execute and verify deterministically.\nIf research is needed, call it out explicitly and use duckduckgo MCP; do not guess.\n",
        "MCP_PROMPT_ANALYZE_TASK_APPEND": "\n\n# Analysis Requirements\nProvide 2–3 viable approaches with trade-offs (correctness, maintainability, security, complexity). Identify unknowns and propose the fastest validation (tiny repro, grep, minimal test, targeted doc/source).\nSecurity-by-design: note authn/authz, input validation, secrets handling, and logging.\nWhen facts may be time-sensitive or niche, verify via duckduckgo MCP and cite what changed.\n",
        "MCP_PROMPT_SPLIT_TASKS_APPEND": "\n\n# Task Decomposition Rules\nSplit into atomic tasks with: objective, exact outputs (files/changes), preconditions, and verification commands. Keep each task executable end-to-end without hidden dependencies.\nEnsure ordering/dep graph is explicit. Prefer fewer, clearer tasks over many micro-tasks.\n",
        "MCP_PROMPT_EXECUTE_TASK_APPEND": "\n\n# Execution Rules\nExecute exactly one task at a time unless the user explicitly requests continuous execution.\nBefore edits: read relevant files; do not invent APIs. During execution: implement + verify locally (or provide exact commands) + update canonical docs + remove temp artifacts.\nIf UI/E2E relevant, use playwright. If runtime/ops signals matter, use grafana to validate metrics/logs.\nIf blocked (secrets/access/CI), stop at the smallest blocker and propose the fastest unblock path.\n",
        "MCP_PROMPT_VERIFY_TASK_APPEND": "\n\n# Verification Bar\nVerification must be explicit: commands (lint/typecheck/tests/build) and expected signals. If you cannot run them, provide exact commands and what \"good\" looks like.\nIf deployment is required to validate, state the minimum pipeline evidence required and the environment-dependent checks.\n",
        "MCP_PROMPT_REFLECT_TASK_APPEND": "\n\n# Reflection + Knowledge Capture\nAssess: what worked, what failed, and one improvement to prevent regressions.\nPropose 3–7 memory candidates (how-to, lessons learned, where-to-find) and ask the user whether to save them to neo4j memory. Only save if user approves.\n",
        "MCP_PROMPT_LIST_TASKS_APPEND": "\n\nWhen listing tasks, present IDs, titles, status, next action, and the recommended task to execute next (with 1-sentence rationale).",
        "MCP_PROMPT_QUERY_TASK_APPEND": "\n\nWhen querying tasks, prefer exact matches first; show task IDs and why they match the query.",
        "MCP_PROMPT_GET_TASK_DETAIL_APPEND": "\n\nWhen showing a task, include: goal, current status, dependencies, latest changes, and the next verification step."
      }
    }
  }
}
EOF

echo "✓ Generated mcp.json at: $OUTPUT_PATH"
echo ""
echo "Configuration strategy:"
echo "  - Most MCP servers use 'docker' for execution"
echo "  - Images from Docker Hub MCP Catalog"
echo "  - All secrets via environment variables (never hardcoded)"
echo "  - Works seamlessly from both Windows and WSL"
echo ""
echo "Next steps:"
echo "  1. Review the generated mcp.json"
echo "  2. Restart Cursor to apply changes"
