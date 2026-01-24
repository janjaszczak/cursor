#!/usr/bin/env python3
"""
Cursor Deeplink Generator (prompt / command / rule / mcp-install)

Author intent:
- Generate Cursor deeplinks in either app format (cursor://...) or web format (https://cursor.com/link/...)
- Ensure query params are correctly URL-encoded.
- Enforce / warn about 8,000-character URL length limit (after encoding).

Docs:
- https://cursor.com/docs/integrations/deeplinks.md
- https://cursor.com/docs/context/mcp/install-links.md
"""

from __future__ import annotations

import argparse
import base64
import json
import sys
from typing import Any, Dict, Tuple
from urllib.parse import urlencode


APP_BASE = "cursor://anysphere.cursor-deeplink"
WEB_BASE = "https://cursor.com/link"
MAX_URL_LEN = 8000


def _json_loads(s: str) -> Any:
    try:
        return json.loads(s)
    except json.JSONDecodeError as e:
        raise SystemExit(f"Invalid JSON: {e}") from e


def _read_text_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError as e:
        raise SystemExit(f"File not found: {path}") from e


def _make_url(base: str, path: str, params: Dict[str, str]) -> str:
    # urlencode uses application/x-www-form-urlencoded:
    # - spaces -> '+'
    # - '+' encoded as %2B (important for base64)
    query = urlencode(params)
    return f"{base}{path}?{query}" if query else f"{base}{path}"


def gen_prompt_links(text: str) -> Tuple[str, str]:
    app = _make_url(APP_BASE, "/prompt", {"text": text})
    web = _make_url(WEB_BASE, "/prompt", {"text": text})
    return app, web


def gen_command_links(name: str, text: str) -> Tuple[str, str]:
    app = _make_url(APP_BASE, "/command", {"name": name, "text": text})
    web = _make_url(WEB_BASE, "/command", {"name": name, "text": text})
    return app, web


def gen_rule_links(name: str, text: str) -> Tuple[str, str]:
    app = _make_url(APP_BASE, "/rule", {"name": name, "text": text})
    web = _make_url(WEB_BASE, "/rule", {"name": name, "text": text})
    return app, web


def _extract_mcp_transport_config(config_obj: Any, name: str) -> Dict[str, Any]:
    """
    Accepts either:
    A) transport config object: {"command": "...", "args": [...] , ...}
    B) mcp.json-style object:  {"postgres": {"command": "...", "args": [...]}}
       In this case, we pick config_obj[name].
    """
    if isinstance(config_obj, dict) and "command" in config_obj:
        # Looks like a single transport config
        return config_obj

    if isinstance(config_obj, dict) and name in config_obj and isinstance(config_obj[name], dict):
        return config_obj[name]

    raise SystemExit(
        "MCP config must be either a transport config object "
        '(e.g. {"command":"npx","args":[...]}) '
        f'or an mcp.json-style mapping containing key "{name}".'
    )


def gen_mcp_install_links(name: str, config_json: str) -> Tuple[str, str, str]:
    """
    Cursor MCP install link format:
    cursor://anysphere.cursor-deeplink/mcp/install?name=$NAME&config=$BASE64_ENCODED_CONFIG

    config is base64(JSON.stringify(transportConfig)).
    """
    config_obj = _json_loads(config_json)
    transport_cfg = _extract_mcp_transport_config(config_obj, name)

    cfg_str = json.dumps(transport_cfg, separators=(",", ":"), ensure_ascii=False)
    cfg_b64 = base64.b64encode(cfg_str.encode("utf-8")).decode("ascii")

    app = _make_url(APP_BASE, "/mcp/install", {"name": name, "config": cfg_b64})
    web = _make_url(WEB_BASE, "/mcp/install", {"name": name, "config": cfg_b64})
    return app, web, cfg_str


def _print_links(app: str, web: str, only: str | None, as_md: bool) -> None:
    def warn(url: str) -> str:
        if len(url) > MAX_URL_LEN:
            return f"  WARNING: length {len(url)} > {MAX_URL_LEN} (Cursor deeplink max)."
        return f"  length: {len(url)}"

    if only == "app":
        out = app
        if as_md:
            print(out)
            print(warn(out), file=sys.stderr)
        else:
            print(out)
            print(warn(out), file=sys.stderr)
        return

    if only == "web":
        out = web
        if as_md:
            print(out)
            print(warn(out), file=sys.stderr)
        else:
            print(out)
            print(warn(out), file=sys.stderr)
        return

    if as_md:
        print(f"WEB: {web}")
        print(f"APP: {app}")
    else:
        print(web)
        print(app)

    print(warn(web), file=sys.stderr)
    print(warn(app), file=sys.stderr)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        prog="cursor-deeplink-gen",
        description="Generate Cursor deeplinks for prompt/command/rule and MCP install.",
    )
    p.add_argument("--only", choices=["web", "app"], default=None, help="Print only one link format.")
    p.add_argument("--md", action="store_true", help="Emit markdown-friendly output labels.")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("prompt", help="Generate a prompt deeplink.")
    sp.add_argument("--text", required=True, help="Prompt text (plain language).")

    sc = sub.add_parser("command", help="Generate a command deeplink.")
    sc.add_argument("--name", required=True, help="Command name (e.g., debug-api).")
    sc.add_argument("--text", required=True, help="Command content (markdown/plain).")

    sr = sub.add_parser("rule", help="Generate a rule deeplink.")
    sr.add_argument("--name", required=True, help="Rule name (file base name).")
    sr.add_argument("--text", required=True, help="Rule content (markdown/plain).")

    sm = sub.add_parser("mcp-install", help="Generate an MCP install deeplink.")
    sm.add_argument("--name", required=True, help="Server name (e.g., postgres).")
    mx = sm.add_mutually_exclusive_group(required=True)
    mx.add_argument("--config-json", help="JSON string: transport config OR mcp.json-style mapping.")
    mx.add_argument("--config-file", help="Path to JSON file: transport config OR mcp.json-style mapping.")

    args = p.parse_args(argv)

    if args.cmd == "prompt":
        app, web = gen_prompt_links(args.text)
        _print_links(app, web, args.only, args.md)
        return 0

    if args.cmd == "command":
        app, web = gen_command_links(args.name, args.text)
        _print_links(app, web, args.only, args.md)
        return 0

    if args.cmd == "rule":
        app, web = gen_rule_links(args.name, args.text)
        _print_links(app, web, args.only, args.md)
        return 0

    if args.cmd == "mcp-install":
        cfg = args.config_json if args.config_json is not None else _read_text_file(args.config_file)
        app, web, cfg_str = gen_mcp_install_links(args.name, cfg)
        _print_links(app, web, args.only, args.md)
        # Helpful debug on stderr (doesn't pollute link output)
        print(f"  MCP transport config (stringified): {cfg_str}", file=sys.stderr)
        return 0

    raise SystemExit("Unknown command")


if __name__ == "__main__":
    raise SystemExit(main())
