---
name: memory-forget
description: "Remove or prune entries from the FORGE memory bank. Search by keyword to selectively delete, or use --prune to auto-remove stale low-confidence entries. Use to clean up memory — triggered by 'forget this', 'remove from memory', 'clean up memory', 'prune old decisions'."
argument-hint: "[search term] or [--prune]"
allowed-tools: Read Grep Glob Bash Write
---

# /memory-forget — Remove Memory Entries

You search, display, and selectively delete entries from the memory bank. Always confirm before deleting.

## Step 1: Check Memory Bank

```bash
if [ -f ~/.forge/memory.jsonl ] && [ -s ~/.forge/memory.jsonl ]; then
  echo "$(wc -l < ~/.forge/memory.jsonl | tr -d ' ') entries"
else
  echo "EMPTY"
fi
```

If empty:
```
FORGE /forget — Memory bank is empty. Nothing to forget.
```
Stop here.

## Step 2: Determine Mode

- If `$ARGUMENTS` is `--prune` → go to **Auto-Prune** (Step 5)
- If `$ARGUMENTS` is provided → use as search term for **Manual Deletion** (Step 3)
- If no arguments → ask the user: "What would you like to forget? Provide a search term, or use `--prune` for auto-cleanup."

## Step 3: Search and Display

Read all entries:
```bash
cat ~/.forge/memory.jsonl
```

Filter entries where the search term matches any of: `decision`, `tags`, `project`, `category`, or `rationale` fields. Case-insensitive matching.

Display matches:

```
FORGE /forget — Found [N] entries matching "[search term]":

1. [id] | [date] | [project] | [category] | confidence: [confidence]
   Decision: [decision]
   Rationale: [rationale]

2. [id] | [date] | [project] | [category] | confidence: [confidence]
   Decision: [decision]
   Rationale: [rationale]

Delete which entries? (numbers e.g. "1,3", "all", or "cancel")
```

If no matches:
```
FORGE /forget — No entries matching "[search term]".
```

## Step 4: Delete Selected Entries

After the user confirms which entries to delete, collect the IDs of selected entries.

**Safe rewrite process:**

1. Read the entire file
2. Filter out entries matching the selected IDs
3. Write remaining entries to a temp file
4. Atomically replace the original

```bash
# Use jq for exact ID matching — grep -v can match partial IDs and delete wrong entries
# Example for deleting ids "20260401_143022_a7f2" and "20260315_091100_b3c1":
jq -c 'select(.id != "20260401_143022_a7f2" and .id != "20260315_091100_b3c1")' ~/.forge/memory.jsonl > ~/.forge/memory.jsonl.tmp && mv ~/.forge/memory.jsonl.tmp ~/.forge/memory.jsonl
```

If `jq` is not available, use exact pattern matching with anchored grep:
```bash
grep -v -E '^.*"id":"20260401_143022_a7f2".*$' ~/.forge/memory.jsonl > ~/.forge/memory.jsonl.tmp && mv ~/.forge/memory.jsonl.tmp ~/.forge/memory.jsonl
```

If all entries are deleted, leave `memory.jsonl` as an empty file (do not delete it).

Confirm:
```
FORGE /forget — Deleted [N] entries.
Memory bank: [remaining] entries.
```

## Step 5: Auto-Prune Mode (`--prune`)

Find entries matching ALL of:
- `date` is older than 6 months from today
- `confidence` < 0.5

Calculate the 6-month cutoff:
```bash
# macOS:
date -v-6m +%Y-%m-%d
# Linux:
date -d "6 months ago" +%Y-%m-%d
```

Read all entries and filter for stale candidates.

If no candidates:
```
FORGE /forget --prune — No stale entries found.
Criteria: older than 6 months AND confidence < 0.5.
```

If candidates found:
```
FORGE /forget --prune — Found [N] stale entries:

1. [id] | [date] | [project] | confidence: [confidence]
   Decision: [decision]

2. [id] | [date] | [project] | confidence: [confidence]
   Decision: [decision]

Criteria: older than 6 months AND confidence < 0.5.

Delete all [N] stale entries? (y/n/select numbers)
```

Wait for confirmation, then delete using the same safe rewrite process from Step 4.

## Rules

- **Always confirm before deleting** — never delete silently, never auto-delete without user approval
- The rewrite must preserve all non-deleted entries exactly (no field modification, no reordering)
- If `memory.jsonl` is empty after deletion, leave it as an empty file
- The `--prune` thresholds are fixed for v1: 6 months old AND confidence < 0.5 (both must be true)
- Never delete entries with confidence >= 0.5 in prune mode, regardless of age
- If the file has only 1-2 entries, warn the user before deleting ("This will remove most of your memory bank")
