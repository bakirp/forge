---
name: careful
description: "Guard skill that warns before destructive operations. Intercepts force pushes, hard resets, branch deletes, and other irreversible actions. Enable with /careful to activate guardrails."
argument-hint: "[optional: on|off to toggle]"
allowed-tools: Read Grep Glob Bash
---

# /careful — Destructive Operation Guardrails

Activate session-scoped guardrails that warn before any destructive or irreversible operation is executed.

## Step 1 — Activate Guard Mode

When invoked (or invoked with `on`), enable careful mode for the current session.

Parse `$ARGUMENTS`:
- No argument or `on` — activate careful mode
- `off` — deactivate careful mode (jump to Step 3)

Output on activation:

```
FORGE /careful — Activated

Destructive operation guardrails enabled. You will be warned before:
- git push --force / git push -f
- git reset --hard
- git clean -f / git clean -fd
- git branch -D (force delete)
- git checkout -- . / git restore . (discard all changes)
- rm -rf on project directories
- DROP TABLE / TRUNCATE / DELETE without WHERE
- Overwriting files with uncommitted changes
```

## Step 2 — Intercept Pattern

When careful mode is active, before executing ANY command, check it against the destructive patterns list.

### Destructive Patterns to Intercept

**Git — High Risk:**
- `git push --force`, `git push -f`, `git push --force-with-lease` to main/master
- `git reset --hard`
- `git clean -f`, `git clean -fd`, `git clean -fdx`
- `git branch -D` (force delete)
- `git checkout -- .`, `git restore .` (discard all uncommitted changes)
- `git stash drop`, `git stash clear`
- `git rebase` on shared/public branches

**Git — Medium Risk:**
- `git push --force`, `git push -f` to non-main branches
- `git push --force-with-lease` to non-main branches
- `git branch -D` on branches with unmerged commits

**File System:**
- `rm -rf` on any project directory
- `rm -rf` on paths outside the project (especially `/`, `~`, etc.)
- Overwriting a file that has uncommitted changes

**Database:**
- `DROP TABLE`, `DROP DATABASE`
- `TRUNCATE`
- `DELETE` without a `WHERE` clause
- `ALTER TABLE ... DROP COLUMN`

### When a Destructive Pattern is Detected

Output the warning:

```
FORGE /careful — WARNING

Destructive operation detected:
  Command: [the exact command]
  Risk: [what data or work could be lost]
  Reversible: [yes/no, and how if yes]

Alternatives:
  - [safer alternative 1]
  - [safer alternative 2]

Proceed anyway? (yes to confirm, or use an alternative)
```

Wait for explicit user confirmation before proceeding.

**Special case**: `git push --force` to `main` or `master` always requires **double confirmation** — warn once, then ask "Are you absolutely sure? This rewrites shared history."

### Safer Alternatives to Suggest

| Destructive Command | Safer Alternative |
|---|---|
| `git push --force` | `git push --force-with-lease` (rejects if remote has new commits) |
| `git reset --hard` | `git stash` (preserves changes) or `git reset --soft` (keeps staging) |
| `git clean -f` | `git clean -n` (dry run first) |
| `git branch -D` | `git branch -d` (refuses if unmerged) |
| `git checkout -- .` | `git stash` (preserves changes for later) |
| `rm -rf directory` | `mv directory directory.bak` (rename instead of delete) |
| `DROP TABLE` | `ALTER TABLE ... RENAME TO ..._backup` |

## Step 3 — Deactivate

When `/careful off` is invoked:

```
FORGE /careful — Deactivated

Destructive operation guardrails disabled. Standard safety defaults still apply.
```

## Rules

- **Never silently allow a destructive operation** when careful mode is active. Every flagged command must be acknowledged by the user.
- **Always present a safer alternative** when one exists. The user should have an easy path to a less risky option.
- **Force push to main/master always requires double confirmation** — no exceptions, even if the user seems sure.
- **Careful mode is session-scoped** — it does not persist across sessions. Each new session starts with careful mode off.
- **Do not be annoying** — only flag genuinely destructive operations. Regular `git add`, `git commit`, `git push` (without force), `git pull`, `git checkout <branch>`, `rm` on single files, etc. should pass through without interruption.
- **Log intercepted commands** — keep a mental count of how many destructive operations were caught during the session for the deactivation summary.
- **Respect user overrides** — if the user confirms "yes" after a warning, proceed. Careful mode advises; it does not block.
