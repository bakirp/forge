---
name: memory-recall
description: "Retrieve relevant past decisions from the FORGE memory bank. Triggered automatically at /architect start and available on-demand. Read-only — never modifies memory. Use to retrieve past decisions — triggered by 'what did we decide', 'recall decisions', 'check memory', 'past decisions about'."
argument-hint: "[optional: search terms or tags to filter by]"
allowed-tools: Read Grep Glob Bash
---

# /memory-recall — Retrieve Past Decisions

You surface relevant past decisions from the memory bank. You are read-only — never modify `memory.jsonl`.

## Step 1: Check Memory Bank

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  echo "$(wc -l < ~/.forge/memory.jsonl | tr -d ' ') entries"
else
  echo "EMPTY"
fi
```

If empty or missing:
- If invoked at session start (from root SKILL.md bootstrap): **skip silently** — do not print any message.
- If invoked explicitly by the user or from `/architect`: print:
```
FORGE memory: No past decisions stored yet.
```
Stop here.

## Step 2: Read Entries

```bash
cat ~/.forge/memory.jsonl
```

If the file has more than 200 lines, read only the last 200 (most recent entries are most relevant):
```bash
tail -200 ~/.forge/memory.jsonl
```

## Step 3: Gather Context

Determine what's relevant by collecting signals:

**Project name**:
```bash
basename "$(pwd)"
```
Also check `CLAUDE.md` for a project name if present.

**Search terms**: If `$ARGUMENTS` were provided, use them as explicit filter terms.

**Task context**: If invoked from within `/architect`, extract domain keywords from the task description being architected.

**Tech stack signals**: Check for `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `Gemfile`, etc. to understand the project's domain.

## Step 4: Rank Entries

Use the ranking script to score and filter entries:

```bash
bash scripts/memory-rank.sh "$SEARCH_TERMS" "$(basename "$(pwd)")" 5
```

The script scores entries by: project name match (+3), tag overlap (+2 per tag), decision/rationale text match (+1), high confidence (+1 if >= 0.8), and age penalty (-1 if > 6 months old). Returns the top N results.

If the script is unavailable, fall back to manual ranking using three tiers:

**Tier 1 — Project match** (highest weight):
Entries where `project` matches the current project name.

**Tier 2 — Tag overlap** (medium weight):
Entries whose `tags` array overlaps with keywords from the current task context, search terms, or detected tech stack.

**Tier 3 — Category relevance** (lower weight):
- Inside `/architect`: prioritize `architecture` and `stack-choice` categories
- Inside `/ship`: prioritize `security` category
- General context: prioritize `anti-pattern` (always useful to surface warnings)

**Tiebreaker**: More recent entries rank higher. Higher confidence ranks higher.

Select the **top 5** entries.

## Step 5: Format Output

For each selected entry:

```
FORGE remembers:
1. [decision] — Rationale: [rationale]
   (from [project], [date], confidence: [confidence])
   [If anti_patterns not empty]: Anti-pattern: [anti_patterns joined by "; "]

2. [decision] — Rationale: [rationale]
   ...
```

If invoked at session start (from root SKILL.md), limit to **top 3** and keep total output under **300 tokens**.

If no entries match the relevance criteria:
- If invoked at session start: **skip silently**.
- If invoked explicitly or from `/architect`:
```
FORGE memory: No relevant past decisions found for this context.
```

Do not surface irrelevant entries just to show something.

## Rules

- Never modify `memory.jsonl` — recall is strictly read-only
- Prefer precision over recall: surfacing an irrelevant memory is worse than missing a relevant one
- Cap at 200 entries read to bound context usage
- Session-start injection: top 3, under 300 tokens
- /architect injection: top 5, no token cap
- If entries reference a technology not present in the current project, deprioritize them
