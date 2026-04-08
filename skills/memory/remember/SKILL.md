---
name: memory-remember
description: "Store architectural decisions from the current session into the FORGE memory bank. Triggered at end of /architect and /retro, or invoked manually with an explicit decision. Use to save decisions — triggered by 'remember this decision', 'store this', 'save to memory'."
argument-hint: "[decision to remember, or blank to extract from session]"
allowed-tools: Read Grep Glob Bash Write
---

# /memory-remember — Store Decisions

You extract decisions from the current session and store them in the memory bank for future recall.

## Step 1: Extract Decisions

Two modes:

### Explicit (arguments provided)
If `$ARGUMENTS` contains a specific decision, use it directly. Parse it as the `decision` field. Ask the user for the rationale if not obvious from context.

### Session extraction (no arguments)
If invoked at the end of `/architect` (typical), scan for decisions:

1. Read the architecture doc just produced (most recent file in `.forge/architecture/`):
   ```bash
   ls -t .forge/architecture/*.md 2>/dev/null | head -1
   ```

2. Extract key decisions from the doc:
   - Technology/stack choices (from Dependencies, Overview sections)
   - Architectural patterns (from Data Flow, Component Boundaries)
   - Security decisions (from Security Considerations)
   - Anti-patterns identified (from Edge Cases, Deferred)

3. Present extracted decisions to the user:
   ```
   FORGE /remember — Extracted [N] decisions from this session:

   1. [decision] — [rationale]
      Category: [category] | Tags: [tags]

   2. [decision] — [rationale]
      Category: [category] | Tags: [tags]

   Store all? (y/n/select numbers to store, e.g. "1,3")
   ```

Wait for user confirmation before storing anything.

## Step 2: Detect Project

```bash
basename "$(pwd)"
```

Also check `CLAUDE.md` for a more specific project name. Use the most descriptive name available.

## Step 3: Format Entries

For each confirmed decision, construct a JSON object matching the schema from `/memory`:

- **id**: Generate a unique ID:
  ```bash
  echo "$(date +%Y%m%d_%H%M%S)_$(xxd -l2 -p /dev/urandom)"
  ```
- **project**: detected project name
- **date**: today's date (`date +%Y-%m-%d`)
- **category**: classify as `architecture`, `stack-choice`, `security`, `workflow`, or `anti-pattern`
- **decision**: one-sentence summary
- **rationale**: one-sentence explanation of why
- **anti_patterns**: array of things to avoid (empty `[]` if none)
- **tags**: array of lowercase keywords from the decision domain
- **confidence**: default `0.8`. Use `0.9` for strongly validated decisions, `0.6` for experimental ones.

## Step 4: Deduplicate

Read existing entries:
```bash
cat ~/.forge/memory.jsonl 2>/dev/null
```

For each new entry, check if an existing entry has:
- Same `project` AND same `category` AND significant keyword overlap in the `decision` field

If a duplicate is found:
```
Skipping: "[decision]"
  Similar to existing entry [id]: "[existing decision]"
```

If the new entry refines or contradicts an existing one (same topic, different conclusion):
```
Conflict detected:
  Existing: [existing decision] (id: [id], confidence: [confidence])
  New:      [new decision]

Replace existing? (y = replace / n = keep both / s = skip new)
```

If replacing, the old entry must be removed (use the same rewrite approach as `/forget`).

## Step 5: Append

For each entry that passes deduplication:

Use `jq` to construct the JSON safely (handles quoting, escaping, and special characters):

```bash
jq -n -c \
  --arg id "[id]" \
  --arg project "[project]" \
  --arg date "[date]" \
  --arg category "[category]" \
  --arg decision "[decision]" \
  --arg rationale "[rationale]" \
  --argjson anti_patterns '[array]' \
  --argjson tags '[array]' \
  --argjson confidence [confidence] \
  '{id:$id,project:$project,date:$date,category:$category,decision:$decision,rationale:$rationale,anti_patterns:$anti_patterns,tags:$tags,confidence:$confidence}' \
  >> ~/.forge/memory.jsonl
```

If `jq` is not available, fall back to `python3 -c 'import json,sys; ...'` for safe JSON construction. **Never use raw `echo` with string interpolation** — special characters (quotes, backslashes, newlines) in decisions or rationale will produce invalid JSONL.

Validate the last written line before considering the append complete:
```bash
tail -1 ~/.forge/memory.jsonl | jq empty || echo "ERROR: Invalid JSON written — remove last line"
```

Run deduplication to consolidate any historical duplicates:
```bash
bash scripts/memory-dedup.sh
```

## Step 6: Confirm

```
FORGE /remember — Stored [N] decision(s):
- [decision 1] (id: [id1], category: [category])
- [decision 2] (id: [id2], category: [category])

Memory bank: [total] entries across [N] projects.
```

## Rules

- Always confirm with the user before storing — never store silently
- Never store secrets, credentials, API keys, or PII
- Each JSONL line must be valid JSON — validate before appending
- Decisions should be reusable across projects — avoid project-specific paths or variable names
- Always deduplicate before appending
- If unsure whether something is worth remembering, ask the user
- Default confidence is 0.8 — only the user can set it higher or lower
