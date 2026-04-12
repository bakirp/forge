---
name: memory-forget
description: "Remove or prune entries from the FORGE memory bank. Search by keyword to selectively delete, or use --prune to auto-remove stale low-confidence entries. Use to clean up memory — triggered by 'forget this', 'remove from memory', 'clean up memory', 'prune old decisions'."
argument-hint: "[search term] or [--prune]"
allowed-tools: Read Grep Glob Bash Write
---

# /memory-forget — Remove Memory Entries

Always confirm before deleting — never delete silently or auto-delete without user approval.

## Step 1: Check Memory Bank

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  echo "$(wc -l < ~/.forge/memory.jsonl | tr -d ' ') entries"
else
  echo "EMPTY"
fi
```
If empty: respond `FORGE /forget — Memory bank is empty. Nothing to forget.` and stop.

## Step 2: Determine Mode

`--prune` → Step 5. Search term provided → Step 3. No arguments → ask user for search term or suggest `--prune`.

## Step 3: Search and Display

Read `~/.forge/memory.jsonl`, filter entries where search term matches `decision`, `tags`, `project`, `category`, or `rationale` (case-insensitive). Display:
```
FORGE /forget — Found [N] entries matching "[search term]":
1. [id] | [date] | [project] | [category] | confidence: [confidence]
   Decision: [decision] — Rationale: [rationale]
Delete which entries? (numbers e.g. "1,3", "all", or "cancel")
```
No matches: `FORGE /forget — No entries matching "[search term]".`

## Step 4: Delete Selected Entries

Collect IDs of confirmed entries, perform safe rewrite — filter out selected IDs, write to temp file, atomically replace:
```bash
jq -c 'select(.id != "ID1" and .id != "ID2")' ~/.forge/memory.jsonl > ~/.forge/memory.jsonl.tmp && mv ~/.forge/memory.jsonl.tmp ~/.forge/memory.jsonl
```
If `jq` unavailable: `grep -v -E '^.*"id":"TARGET_ID".*$'` with same temp-file pattern. If all deleted, leave `memory.jsonl` as empty file. Confirm: `FORGE /forget — Deleted [N] entries. Memory bank: [remaining] entries.`

## Step 5: Auto-Prune Mode (`--prune`)

Find entries matching ALL of: `date` older than 6 months AND `confidence` < 0.5. Calculate cutoff:
```bash
date -v-6m +%Y-%m-%d  # macOS; Linux: date -d "6 months ago" +%Y-%m-%d
```

If no candidates: `FORGE /forget --prune — No stale entries found. Criteria: older than 6 months AND confidence < 0.5.`

If candidates found, display and confirm:
```
FORGE /forget --prune — Found [N] stale entries:
1. [id] | [date] | [project] | confidence: [confidence]
   Decision: [decision]
Criteria: older than 6 months AND confidence < 0.5.
Delete all [N] stale entries? (y/n/select numbers)
```
After confirmation, delete using Step 4 safe rewrite process.

## Rules & Compliance

- Rewrite must preserve all non-deleted entries exactly (no field modification, no reordering)
- If `memory.jsonl` empty after deletion, leave as empty file
- `--prune` thresholds fixed: 6 months old AND confidence < 0.5 (both required) — never delete entries with confidence >= 0.5 in prune mode
- If only 1-2 entries remain, warn user before deleting

> **Compliance:** follow `skills/shared/compliance-telemetry.md`. Keys: `no-confirmation` (critical), `entries-modified` (critical). Log via `scripts/compliance-log.sh`.
> **Shared rules & routing:** see `skills/shared/rules.md` and `skills/shared/workflow-routing.md`. Recommended: `/memory recall` to verify remaining decisions.
