---
name: freeze
description: "Scoped edit locks. Restricts modifications to specified files or directories. Prevents accidental changes to critical code during focused work. Use /freeze to lock, /freeze off to unlock. Use to protect files — triggered by 'freeze these files', 'lock files', 'don't edit these', 'protect this file', 'edit lock'."
argument-hint: "[file or directory patterns to freeze, or 'off' to unfreeze]"
allowed-tools: Read Grep Glob Bash
---

# /freeze — Scoped Edit Locks

Restrict modifications to specified files or directories during the current session.

## Step 1 — Parse Freeze Scope

Parse `$ARGUMENTS` to determine the action:

- **File paths / dirs / globs**: `src/auth/*.ts`, `src/core/`, `*.config.*`
- **Multiple targets**: space-separated patterns — `src/auth/ src/core/database.ts *.lock`
- **`off` / `off [pattern]`**: unfreeze all or a specific pattern
- **`list`**: show current freeze state
- **No argument**: show usage help with examples

## Step 2 — Activate Freeze

Glob-verify each pattern (warn if no matches but still register). Register with timestamp, confirm with file counts. Warn if pattern overlaps the current task scope.

```
FORGE /freeze — Activated

Frozen (modifications blocked):
  - src/auth/*.ts (12 files matched)
  - src/core/database.ts (1 file)

Any attempt to edit these files will be blocked. Use /freeze list or /freeze off to manage.
```

## Step 3 — Enforce

Before any file modification (Write, Edit, Bash writes): resolve target path, check against frozen patterns, block if matched — show the file, matching pattern, and options (`/freeze off [pattern]`, `/freeze off`, `override freeze for [file]`). Wait for user instruction. Reads are always allowed.

## Step 4 — Unfreeze

Handle `/freeze off` (all) or `/freeze off [pattern]` (specific). If pattern matches no active lock, list current locks and suggest exact matches.

```
FORGE /freeze — Unfrozen

Removed: [pattern(s), with lock duration]
Remaining: [remaining locks or "none — all files editable"]
Blocked this session: [N] modification attempts
```

## Step 5 — Report (List)

Show active locks with file counts, timestamps, and blocked-attempt count. If none active, state that and suggest `/freeze [patterns]`.

```
FORGE /freeze list

Active locks:
  1. src/auth/*.ts — 12 files (since 14:32)
  2. src/core/database.ts — 1 file (since 14:32)

Blocked this session: 3 modification attempts
```

## Rules & Compliance

- Session-scoped and advisory — locks do not persist; user can override with explicit confirmation.
- Pattern matching uses glob syntax (`*`, `**`, `?`) relative to project root. Never freeze `.git/` internals.
- Always show what is frozen when activating, listing, or blocking. Track blocked attempts for reporting.
- Warn on scope conflicts. Subagents from `/build` or `/autopilot` do NOT inherit freeze locks.
- **Compliance & telemetry**: follow `skills/shared/compliance-telemetry.md`. Key: `frozen-file-modified` (major). Log via `scripts/compliance-log.sh`. **Shared rules**: `skills/shared/rules.md`. **Workflow routing**: `skills/shared/workflow-routing.md`.
