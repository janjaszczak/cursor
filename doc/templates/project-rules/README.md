# Project rule templates (optional, per-repo only)

These `.mdc` files are **examples** for stack-specific rules in `<application-repo>/.cursor/rules/`.

**Do not** install them in `~/.cursor` or copy loop/CoVe here — global behavior is in [`USER_RULES.txt`](../../USER_RULES.txt) → Settings → User Rules.

## When to use

| Template | Use in app repo when |
|----------|----------------------|
| `100-next-stack.mdc.example` | Next.js frontend |
| `100-python-backend.mdc.example` | FastAPI backend |

Create from [`commands/retro.md`](../../commands/retro.md) prefix convention (000/100/200).

Global agentic loop and CoVe: **never** duplicate — already in User Rules.
