---
name: memory-recall
description: "Retrieve relevant past decisions from the FORGE memory bank. Triggered automatically at /architect start and available on-demand. Read-only — never modifies memory. Use to retrieve past decisions — triggered by 'what did we decide', 'recall decisions', 'check memory', 'past decisions about'."
argument-hint: "[optional: search terms or tags to filter by]"
allowed-tools: Read Grep Glob Bash
---

# /memory-recall — Retrieve Past Decisions

Read-only — never modify `memory.jsonl`.

## Step 1: Check Memory Bank

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  echo "$(wc -l < ~/.forge/memory.jsonl | tr -d ' ') entries"
else
  echo "EMPTY"
fi
```
If empty at session-start bootstrap: skip silently. If empty when invoked explicitly: print `FORGE memory: No past decisions stored yet.` and stop.

## Step 2: Read Entries

`cat ~/.forge/memory.jsonl` (if >200 lines, `tail -200`).

## Step 3: Gather Context

Collect relevance signals: project name (`basename "$(pwd)"` + `CLAUDE.md`), `$ARGUMENTS` as search terms, task context keywords from `/architect`, and tech stack indicators (`package.json`, `requirements.txt`, `go.mod`, etc.).

## Step 4: Rank Entries

```bash
bash scripts/memory-rank.sh "$SEARCH_TERMS" "$(basename "$(pwd)")" 5
```

Scoring: project match (+3), tag overlap (+2/tag), text match (+1), high confidence (+1 if >=0.8), age penalty (-1 if >6mo). Returns top N.

If script unavailable, rank manually: Tier 1 — project name match (highest). Tier 2 — tag overlap with task/search/stack (medium). Tier 3 — category relevance (lower). Tiebreaker: recency + confidence. Select **top 5**.

## Step 5: Format Output

```
FORGE remembers:
1. [decision] — Rationale: [rationale]
   (from [project], [date], confidence: [confidence])
   Anti-pattern: [anti_patterns joined by "; "]  ← only if non-empty
```

Session-start: top 3, under 300 tokens. No matches at session-start: skip silently. No matches when explicit: print `No relevant past decisions found.` Never surface irrelevant entries.

## Rules & Compliance

- Never modify `memory.jsonl` — strictly read-only
- Prefer precision over recall: irrelevant memory is worse than missing relevant ones
- Cap at 200 entries read; session-start: top 3 / 300 tokens; /architect: top 5 / no cap
- Deprioritize entries referencing technology not present in current project

> **Compliance:** follow `skills/shared/compliance-telemetry.md`. Keys: `memory-modified` (critical), `irrelevant-surfaced` (minor). Log via `scripts/compliance-log.sh`.
> **Shared rules & routing:** see `skills/shared/rules.md` and `skills/shared/workflow-routing.md`. Recommended: apply recalled decisions to /architect or /brainstorm. If stale: /memory forget.
