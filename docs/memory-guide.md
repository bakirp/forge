# FORGE Memory Guide

FORGE maintains a cross-project decision memory bank at `~/.forge/memory.jsonl`. Decisions made during architecture sessions persist and inform future projects.

## What Gets Remembered

- **Architecture decisions** — system design, component boundaries, data flow patterns
- **Stack choices** — technology, framework, or library selections and why
- **Security decisions** — auth approaches, encryption choices, threat mitigations
- **Anti-patterns** — things that failed or should be avoided
- **Workflow decisions** — CI/CD patterns, testing approaches, process choices

Decisions are stored as one-sentence summaries with rationale, making them reusable across projects. Project-specific implementation details (file paths, variable names) are not stored.

## How It Works

### Automatic

- **At `/architect` start**: FORGE automatically recalls relevant past decisions and surfaces them as context before you design.
- **At `/architect` end**: FORGE extracts key decisions from the architecture doc and asks which to store.
- **At session start**: The top 3 relevant memories are injected (under 300 tokens).

### Manual

| Command | What it does |
|---------|-------------|
| `/memory` | Show memory bank status |
| `/memory remember "Use Redis for session cache"` | Store a specific decision |
| `/memory recall database` | Search for past decisions about databases |
| `/memory forget postgres` | Find and delete entries about postgres |
| `/memory forget --prune` | Auto-remove stale, low-confidence entries |

## Memory Schema

Each entry in `memory.jsonl` is a single-line JSON object:

```json
{
  "id": "20260401_143022_a7f2",
  "project": "myapp",
  "date": "2026-04-01",
  "category": "architecture",
  "decision": "Use PostgreSQL over SQLite for the user service",
  "rationale": "Need concurrent writes from multiple services",
  "anti_patterns": ["SQLite for multi-service writes"],
  "tags": ["database", "postgres", "concurrency"],
  "confidence": 0.9
}
```

**Categories**: `architecture`, `stack-choice`, `security`, `workflow`, `anti-pattern`

**Confidence**: 0.0–1.0. New entries default to 0.8. Higher means more validated.

## Reviewing Your Memory Bank

The file is plain JSONL — standard unix tools work:

```bash
# View all entries
cat ~/.forge/memory.jsonl

# Search for database decisions
grep "database" ~/.forge/memory.jsonl

# Count entries
wc -l ~/.forge/memory.jsonl

# View entries from a specific project
grep '"project":"myapp"' ~/.forge/memory.jsonl

# Pretty-print an entry
head -1 ~/.forge/memory.jsonl | python3 -m json.tool
```

## When to Use /forget

- A decision is **outdated** (technology changed, better approach found)
- A project was **decommissioned** and its decisions are no longer relevant
- A decision was **wrong** and you don't want it influencing future projects
- The memory bank is getting **noisy** with low-value entries

### Auto-Prune

`/memory forget --prune` removes entries that are both:
- Older than 6 months
- Confidence below 0.5

This cleans up experimental or uncertain decisions that haven't been validated over time.

## Exporting and Sharing

The memory bank is a plain file — copy, move, or version-control it:

```bash
# Back up your memory
cp ~/.forge/memory.jsonl ~/backups/forge-memory-backup.jsonl

# Track in git
cd ~/.forge && git init && git add memory.jsonl && git commit -m "memory snapshot"

# Share with a teammate (they merge into their own bank)
cat your-memory.jsonl >> ~/.forge/memory.jsonl
```

Note: shared/team memory banks are planned for a future release.

## Limits

| Constraint | Value | Reason |
|-----------|-------|--------|
| Session-start injection | Top 3 entries, max 300 tokens | Keep context lean |
| /architect recall | Top 5 entries | More context for design |
| Read cap | Last 200 entries | Bound context usage |
| Auto-prune threshold | 6 months + confidence < 0.5 | Both must be true |
| Recall method | Keyword + tag matching | Vector search deferred to a future release |
