---
name: memory
description: "Cross-project decision memory. Routes to /memory-remember, /memory-recall, /memory-forget. Defines the canonical memory schema."
argument-hint: "[remember|recall|forget] [optional args]"
allowed-tools: Read Grep Glob Bash
---

# /memory — Cross-Project Decision Memory

FORGE maintains a decision memory bank at `~/.forge/memory.jsonl`. Decisions made during `/architect` sessions persist across projects, so past lessons inform future designs.

## Routing

If `$ARGUMENTS` starts with a sub-command, delegate:

| Argument | Action |
|----------|--------|
| `remember [decision]` | Invoke `/memory-remember` with the remaining arguments |
| `recall [search terms]` | Invoke `/memory-recall` with the remaining arguments |
| `forget [search terms]` | Invoke `/memory-forget` with the remaining arguments |
| `forget --prune` | Invoke `/memory-forget --prune` |
| *(no argument)* | Show memory bank status (below) |

## Status (No Arguments)

When invoked without arguments, show the current state:

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  ENTRIES=$(wc -l < ~/.forge/memory.jsonl | tr -d ' ')
  PROJECTS=$(cat ~/.forge/memory.jsonl | grep -o '"project":"[^"]*"' | sort -u | wc -l | tr -d ' ')
  LATEST=$(tail -1 ~/.forge/memory.jsonl | grep -o '"date":"[^"]*"' | head -1)
  echo "ENTRIES=$ENTRIES PROJECTS=$PROJECTS LATEST=$LATEST"
else
  echo "EMPTY"
fi
```

Display:
```
FORGE /memory — Status

Memory bank: [N] entries across [N] projects
Latest entry: [date]
Location: ~/.forge/memory.jsonl

Commands:
  /memory remember [decision]  — Store a decision
  /memory recall [terms]       — Retrieve relevant decisions
  /memory forget [terms]       — Remove entries
  /memory forget --prune       — Auto-remove stale entries
```

If empty:
```
FORGE /memory — Empty

No decisions stored yet. Decisions are automatically stored at the
end of /architect sessions, or you can store one manually:

  /memory remember "Use PostgreSQL for multi-service writes"
```

## Memory Schema

Every entry in `~/.forge/memory.jsonl` is a single-line JSON object with these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique ID: `YYYYMMDD_HHmmss_XXXX` (timestamp + 4 hex chars) |
| `project` | string | yes | Project name (from directory name or CLAUDE.md) |
| `date` | string | yes | ISO date: `YYYY-MM-DD` |
| `category` | string | yes | One of: `architecture`, `stack-choice`, `security`, `workflow`, `anti-pattern` |
| `decision` | string | yes | One-sentence summary of the decision |
| `rationale` | string | yes | One-sentence explanation of why |
| `anti_patterns` | string[] | yes | What to avoid (empty array `[]` if none) |
| `tags` | string[] | yes | Lowercase keywords for recall filtering |
| `confidence` | number | yes | 0.0–1.0. Default 0.8 for new entries. |

### Valid Categories

- **architecture** — System design, component boundaries, data flow decisions
- **stack-choice** — Technology, framework, or library selections
- **security** — Auth, encryption, data handling, threat mitigations
- **workflow** — Process decisions, CI/CD patterns, testing approaches
- **anti-pattern** — Something that failed or should be avoided

### Example Entry

```json
{"id":"20260401_143022_a7f2","project":"myapp","date":"2026-04-01","category":"architecture","decision":"Use PostgreSQL over SQLite for the user service","rationale":"Need concurrent writes from multiple services; SQLite locks on write","anti_patterns":["SQLite for multi-service writes","Single-file database for concurrent access"],"tags":["database","postgres","sqlite","concurrency"],"confidence":0.9}
```

## Rules

- One JSON object per line — no pretty-printing, no multi-line entries
- Append-only for writes (`/remember`). Only `/forget` does full rewrites.
- Never store secrets, credentials, API keys, or PII as decisions
- Decisions should be reusable across projects — avoid project-specific implementation details
