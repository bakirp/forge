---
name: freeze
description: "Scoped edit locks. Restricts modifications to specified files or directories. Prevents accidental changes to critical code during focused work. Use /freeze to lock, /freeze off to unlock. Use to protect files — triggered by 'freeze these files', 'lock files', 'don't edit these', 'protect this file', 'edit lock'."
argument-hint: "[file or directory patterns to freeze, or 'off' to unfreeze]"
allowed-tools: Read Grep Glob Bash
---

# /freeze — Scoped Edit Locks

Restrict modifications to specified files or directories during the current session. Prevents accidental changes to critical code while working on focused tasks.

## Step 1 — Parse Freeze Scope

Parse `$ARGUMENTS` to determine the action:

- **File paths**: `src/auth/*.ts` — freeze specific files matching the pattern
- **Directories**: `src/core/` — freeze everything within a directory
- **Glob patterns**: `*.config.*` — freeze files matching a wildcard pattern
- **Multiple targets**: `src/auth/ src/core/database.ts *.lock` — freeze several patterns at once
- **`off`**: unfreeze all locked patterns
- **`off [pattern]`**: unfreeze a specific pattern
- **`list`**: show current freeze state
- **No argument**: show usage help

If no argument is provided, output:

```
FORGE /freeze — Usage

/freeze [patterns]     Lock files matching the patterns
/freeze list           Show current locks
/freeze off            Remove all locks
/freeze off [pattern]  Remove a specific lock

Examples:
  /freeze src/auth/*.ts src/core/database.ts
  /freeze *.lock package.json
  /freeze off src/auth/*.ts
```

## Step 2 — Activate Freeze

When patterns are provided, resolve them against the project to confirm they match real files, then activate the lock.

1. Use Glob to verify each pattern matches at least one file. If a pattern matches nothing, warn but still register it (the file may be created later).
2. Register each pattern with a timestamp.
3. Output confirmation:

```
FORGE /freeze — Activated

Frozen (modifications blocked):
  - src/auth/*.ts (12 files matched)
  - src/core/database.ts (1 file)

Any attempt to edit these files will be blocked and require explicit override.
Use /freeze list to see all locks, /freeze off to remove them.
```

If the user tries to freeze files that are part of the current task scope (e.g., files they just asked to modify), warn:

```
FORGE /freeze — Warning

Pattern "src/auth/login.ts" overlaps with your current task scope.
Freezing it will block modifications you just requested.

Proceed anyway? (yes to confirm)
```

## Step 3 — Enforce

When freeze is active, before modifying any file (via Write, Edit, or Bash commands that write to files):

1. Resolve the target file path.
2. Check if it matches any frozen pattern.
3. If it matches a frozen pattern, **block the modification**:

```
FORGE /freeze — BLOCKED

Cannot modify: src/auth/session.ts
Reason: Scoped edit lock active on pattern "src/auth/*.ts"

Options:
  /freeze off src/auth/*.ts   — Remove this lock
  /freeze off                 — Remove all locks
  /freeze list                — See all active locks

To override this once, confirm: "override freeze for [file]"
```

4. Wait for user instruction before proceeding.

**Important**: Frozen files can still be **read** — only modifications (write, edit, delete, move, rename) are blocked.

## Step 4 — Unfreeze

Handle unfreeze requests:

**`/freeze off`** — Remove all locks:
```
FORGE /freeze — Deactivated

All edit locks removed. The following patterns were unfrozen:
  - src/auth/*.ts (locked for 23 minutes)
  - src/core/database.ts (locked for 23 minutes)

Blocked this session: [N] modification attempts
All files are now editable.
```

**`/freeze off [pattern]`** — Remove a specific lock:
```
FORGE /freeze — Partially Unfrozen

Removed lock: src/auth/*.ts
Remaining locks:
  - src/core/database.ts

Use /freeze list to see all locks, /freeze off to remove all.
```

If the pattern does not match any active lock, inform the user:
```
FORGE /freeze — No Match

No active lock matches "src/api/". Current locks:
  - src/auth/*.ts
  - src/core/database.ts

Use /freeze off [pattern] with an exact match, or /freeze off to remove all.
```

## Step 5 — Report (List)

When `/freeze list` is invoked:

```
FORGE /freeze list

Active locks:
  1. src/auth/*.ts — 12 files matched (since 14:32)
  2. src/core/database.ts — 1 file (since 14:32)

Blocked this session: 3 modification attempts

/freeze off [number or pattern] to remove a lock.
/freeze off to remove all locks.
```

If no locks are active:
```
FORGE /freeze list

No active locks. Use /freeze [patterns] to lock files.
```

## Rules

- **Freeze is session-scoped** — locks do not persist across sessions. Each new session starts with no active locks.
- **Freeze is advisory** — the user can always override with explicit confirmation. Freeze warns and blocks by default but does not prevent an informed user from proceeding.
- **Frozen files can still be read** — only modifications (write, edit, delete, move, rename) are blocked. Reading, searching, and analyzing frozen files is always allowed.
- **Always show what is frozen** when activating, listing, or when a freeze block triggers. The user should never have to guess what is locked.
- **Warn on scope conflicts** — if the user tries to freeze files that are part of the current task, warn them. Do not silently freeze files they are about to edit.
- **Pattern matching uses glob syntax** — `*` matches any characters in a filename, `**` matches across directories, `?` matches a single character. Patterns are matched against paths relative to the project root.
- **Track blocked attempts** — keep a count of how many modifications were blocked during the session for reporting in `/freeze list` and on deactivation.
- **Do not freeze `.git/` internals** — git operations (commit, branch, merge) should always work even if the repo root is frozen. Only user-facing files are subject to freeze.
- **Advisory and session-scoped** — no other FORGE skill programmatically checks whether freeze locks are active. Enforcement relies on conversation context within a single session.

> **Warning:** Subagents spawned by `/build` or `/autopilot` run in isolated contexts and will NOT inherit freeze locks. This guard only applies to the current conversation session.
