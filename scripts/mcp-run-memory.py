#!/usr/bin/env python3
"""Ensure Neo4j is up on mcp-network, then exec mcp/neo4j-memory (stdio).

Logs go to stderr only so MCP JSON-RPC on stdout stays clean.
Requires NEO4J_PASSWORD (and typically NEO4J_USERNAME / NEO4J_DATABASE) in env.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import time
from pathlib import Path


NETWORK = "mcp-network"
NEO4J_CONTAINER = "neo4j"
NEO4J_IMAGE = "neo4j:latest"
MEMORY_IMAGE = "mcp/neo4j-memory"
NEO4J_URL = "bolt://neo4j:7687"
READY_TIMEOUT_S = 90
READY_POLL_S = 2


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def load_dotenv_if_needed() -> None:
    """Load ~/.cursor/.env when Cursor envFile path expansion is broken/unavailable.

    On Windows, Cursor has been observed to expand `${userHome}/.cursor/...` into
    `C:\\c:\\Users\\...` (invalid). Prefer Path.home() here instead.
    """
    if os.environ.get("NEO4J_PASSWORD", "").strip() and os.environ.get(
        "NEO4J_PASSWORD"
    ) != "CHANGE_ME":
        return

    env_path = Path.home() / ".cursor" / ".env"
    if not env_path.is_file():
        return

    loaded = 0
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if not key:
            continue
        # Do not override vars already set by the parent process.
        if key in os.environ and os.environ[key].strip():
            continue
        os.environ[key] = value
        loaded += 1
    if loaded:
        log(f"Loaded {loaded} vars from {env_path}")


def run(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        check=check,
        capture_output=True,
        text=True,
    )


def docker_available() -> str:
    docker = shutil.which("docker")
    if not docker:
        log("ERROR: docker not found on PATH")
        sys.exit(1)
    return docker


def ensure_network(docker: str) -> None:
    result = run([docker, "network", "create", NETWORK], check=False)
    if result.returncode == 0:
        log(f"Created Docker network '{NETWORK}'")
    # exit 0 or "already exists" are both fine


def container_exists(docker: str, name: str) -> bool:
    result = run(
        [docker, "ps", "-a", "--filter", f"name=^{name}$", "--format", "{{.Names}}"],
        check=False,
    )
    names = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    return name in names


def container_running(docker: str, name: str) -> bool:
    result = run(
        [docker, "ps", "--filter", f"name=^{name}$", "--format", "{{.Names}}"],
        check=False,
    )
    names = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    return name in names


def ensure_neo4j(docker: str) -> None:
    password = os.environ.get("NEO4J_PASSWORD", "").strip()
    if not password or password == "CHANGE_ME":
        log("ERROR: NEO4J_PASSWORD is not set (or still CHANGE_ME)")
        sys.exit(1)

    if container_exists(docker, NEO4J_CONTAINER):
        if not container_running(docker, NEO4J_CONTAINER):
            log(f"Starting existing container '{NEO4J_CONTAINER}'...")
            run([docker, "start", NEO4J_CONTAINER])
        else:
            log(f"Container '{NEO4J_CONTAINER}' already running")
        run(
            [docker, "update", "--restart", "unless-stopped", NEO4J_CONTAINER],
            check=False,
        )
    else:
        log(f"Creating container '{NEO4J_CONTAINER}' on {NETWORK}...")
        run(
            [
                docker,
                "run",
                "-d",
                "--name",
                NEO4J_CONTAINER,
                "--restart",
                "unless-stopped",
                "--network",
                NETWORK,
                "-p",
                "7687:7687",
                "-e",
                f"NEO4J_AUTH=neo4j/{password}",
                NEO4J_IMAGE,
            ]
        )


def wait_neo4j_ready(docker: str) -> None:
    deadline = time.time() + READY_TIMEOUT_S
    log(f"Waiting for Neo4j readiness (up to {READY_TIMEOUT_S}s)...")
    while time.time() < deadline:
        http = run(
            [
                docker,
                "exec",
                NEO4J_CONTAINER,
                "bash",
                "-c",
                "wget -qO- http://127.0.0.1:7474 >/dev/null 2>&1 || "
                "curl -sf http://127.0.0.1:7474 >/dev/null 2>&1",
            ],
            check=False,
        )
        if http.returncode == 0:
            log("Neo4j is ready")
            return

        logs = run([docker, "logs", "--tail", "30", NEO4J_CONTAINER], check=False)
        combined = (logs.stdout or "") + (logs.stderr or "")
        if "Remote interface available" in combined or "Started." in combined:
            # HTTP probe can lag briefly after log line; accept after one settle.
            time.sleep(READY_POLL_S)
            http2 = run(
                [
                    docker,
                    "exec",
                    NEO4J_CONTAINER,
                    "bash",
                    "-c",
                    "wget -qO- http://127.0.0.1:7474 >/dev/null 2>&1 || "
                    "curl -sf http://127.0.0.1:7474 >/dev/null 2>&1",
                ],
                check=False,
            )
            if http2.returncode == 0 or "Started." in combined:
                log("Neo4j is ready")
                return

        time.sleep(READY_POLL_S)

    log(f"ERROR: Neo4j did not become ready within {READY_TIMEOUT_S}s")
    sys.exit(1)


def exec_memory(docker: str) -> None:
    username = os.environ.get("NEO4J_USERNAME", "neo4j")
    password = os.environ["NEO4J_PASSWORD"]
    database = os.environ.get("NEO4J_DATABASE", "neo4j")

    # Ensure child docker sees credentials even if only envFile loaded them here.
    os.environ["NEO4J_USERNAME"] = username
    os.environ["NEO4J_PASSWORD"] = password
    os.environ["NEO4J_DATABASE"] = database

    args = [
        docker,
        "run",
        "-i",
        "--rm",
        "--network",
        NETWORK,
        "-e",
        f"NEO4J_URL={NEO4J_URL}",
        "-e",
        "NEO4J_USERNAME",
        "-e",
        "NEO4J_PASSWORD",
        "-e",
        "NEO4J_DATABASE",
        MEMORY_IMAGE,
    ]
    log(f"Exec {MEMORY_IMAGE} with NEO4J_URL={NEO4J_URL}")
    # Use subprocess (not os.execvp): on Windows execvp can drop/mangle argv for docker.exe.
    rc = subprocess.call(args, stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr)
    sys.exit(rc)


def main() -> None:
    load_dotenv_if_needed()
    docker = docker_available()
    ensure_network(docker)
    ensure_neo4j(docker)
    wait_neo4j_ready(docker)
    exec_memory(docker)


if __name__ == "__main__":
    main()
