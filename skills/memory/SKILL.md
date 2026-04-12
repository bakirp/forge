---
name: memory
description: "Cross-project decision memory. Routes to /memory-remember, /memory-recall, /memory-forget. Defines the canonical memory schema. Use when storing or retrieving decisions — triggered by 'remember this', 'what did we decide', 'save this decision', 'recall', 'forget'."
argument-hint: "[remember|recall|forget] [optional args]"
allowed-tools: Read Grep Glob Bash
---

# /memory — Cross-Project Decision Memory

FORGE maintains a decision memory bank at `~/.forge/memory.jsonl` — decisions persist across projects so past lessons inform future designs.

## Routing

If `$ARGUMENTS` starts with a sub-command, delegate:

| Argument | Action |
|----------|--------|
| `remember [decision]` | Invoke `/memory-remember` with remaining arguments |
| `recall [search terms]` | Invoke `/memory-recall` with remaining arguments |
| `forget [search terms]` | Invoke `/memory-forget` with remaining arguments |
| `forget --prune` | Invoke `/memory-forget --prune` |
| *(no argument)* | Show memory bank status (below) |

## Status (No Arguments)

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  echo "ENTRIES=$(wc -l < ~/.forge/memory.jsonl | tr -d ' ') PROJECTS=$(grep -o '"project":"[^"]*"' ~/.forge/memory.jsonl | sort -u | wc -l | tr -d ' ') LATEST=$(tail -1 ~/.forge/memory.jsonl | grep -o '"date":"[^"]*"' | head -1)"
else
  echo "EMPTY"
fi
```

If non-empty: show entry count, project count, latest date, location, and available commands. If empty: show "No decisions stored yet" with example usage.

## Memory Schema

Every entry in `~/.forge/memory.jsonl` is a single-line JSON object:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | `YYYYMMDD_HHmmss_XXXX` (timestamp + 4 hex) |
| `project` | string | yes | Project name (from directory or CLAUDE.md) |
| `date` | string | yes | ISO date `YYYY-MM-DD` |
| `category` | string | yes | `architecture` &#124; `stack-choice` &#124; `security` &#124; `workflow` &#124; `anti-pattern` |
| `decision` | string | yes | One-sentence summary |
| `rationale` | string | yes | One-sentence explanation |
| `anti_patterns` | string[] | yes | What to avoid (`[]` if none) |
| `tags` | string[] | yes | Lowercase keywords for recall filtering |
| `confidence` | number | yes | 0.0-1.0, default 0.8 |

### Example Entry

```json
{"id":"20260401_143022_a7f2","project":"myapp","date":"2026-04-01","category":"architecture","decision":"Use PostgreSQL over SQLite for the user service","rationale":"Need concurrent writes from multiple services","anti_patterns":["SQLite for multi-service writes"],"tags":["database","postgres","concurrency"],"confidence":0.9}
```

## Rules

- One JSON object per line — no pretty-printing. Append-only for writes; only `/forget` does rewrites.
- Never store secrets, credentials, API keys, or PII.
- Decisions should be reusable across projects — avoid project-specific implementation details.

> **Compliance:** follow `skills/shared/compliance-telemetry.md`. Keys: `secrets-stored` (critical), `invalid-json` (major). Log via `scripts/compliance-log.sh`.
> **Shared rules & routing:** see `skills/shared/rules.md` and `skills/shared/workflow-routing.md`.

## What's Next

After remember/recall/forget, continue with current workflow (`/architect`, `/build`, etc.).
