---
name: memory-remember
description: "Store architectural decisions from the current session into the FORGE memory bank. Triggered at end of /architect and /retro, or invoked manually with an explicit decision. Use to save decisions — triggered by 'remember this decision', 'store this', 'save to memory'."
argument-hint: "[decision to remember, or blank to extract from session]"
allowed-tools: Read Grep Glob Bash Write
---

# /memory-remember — Store Decisions

Always confirm with the user before storing any decision — never store silently.

## Step 1: Extract Decisions

**Explicit** (arguments provided): Use `$ARGUMENTS` as the `decision` field; ask user for rationale if not obvious.

**Session extraction** (no arguments): Scan the most recent architecture doc (`ls -t .forge/architecture/*.md 2>/dev/null | head -1`) for technology choices, architectural patterns, security decisions, and anti-patterns. Present extracted decisions for confirmation:
```
FORGE /remember — Extracted [N] decisions:
1. [decision] — [rationale]
   Category: [category] | Tags: [tags]
Store all? (y/n/select numbers, e.g. "1,3")
```

## Step 2: Detect Project

Use `basename "$(pwd)"`, checking `CLAUDE.md` for a more specific name.

## Step 3: Format Entries

Construct JSON per `/memory` schema. Generate id: `echo "$(date +%Y%m%d_%H%M%S)_$(xxd -l2 -p /dev/urandom)"`. Default confidence `0.8`; use `0.9` for strongly validated, `0.6` for experimental. Categories: `architecture`, `stack-choice`, `security`, `workflow`, `anti-pattern`.

## Step 4: Deduplicate

Read existing entries (`cat ~/.forge/memory.jsonl 2>/dev/null`). For each new entry, check if an existing entry has same `project` + `category` + significant keyword overlap in `decision`.

- **Duplicate**: skip with message `Skipping: "[decision]" — similar to existing [id]`
- **Conflict** (same topic, different conclusion): ask user `Replace existing? (y/replace / n/keep both / s/skip new)`
  If replacing, remove old entry using `/forget` rewrite approach.

## Step 5: Append

Use `jq` for safe JSON construction:
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

If `jq` unavailable, use `python3 -c 'import json,sys; ...'`. **Never use raw `echo`**. Validate: `tail -1 ~/.forge/memory.jsonl | jq empty`. Then run `bash scripts/memory-dedup.sh`.

## Step 6: Confirm

```
FORGE /remember — Stored [N] decision(s): [decision1] ([id], [category]), ...
Memory bank: [total] entries across [N] projects.
```

## Rules & Compliance

- Always confirm before storing; never store secrets, credentials, API keys, or PII
- Each JSONL line must be valid JSON — validate before appending
- Decisions should be reusable across projects; always deduplicate before appending
- If unsure whether something is worth remembering, ask the user
- Default confidence 0.8 — only the user can set it higher or lower

> **Compliance:** follow `skills/shared/compliance-telemetry.md`. Keys: `no-confirmation` (major), `secrets-stored` (critical), `invalid-json` (major), `duplicate-entry` (minor). Log via `scripts/compliance-log.sh`.
> **Shared rules & routing:** see `skills/shared/rules.md` and `skills/shared/workflow-routing.md`. Recommended: `/memory recall` to verify stored decision is retrievable.
