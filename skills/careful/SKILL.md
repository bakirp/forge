---
name: careful
description: "Guard skill that warns before destructive operations. Intercepts force pushes, hard resets, branch deletes, and other irreversible actions. Enable with /careful to activate guardrails. Use when safety matters — triggered by 'enable careful mode', 'be careful', 'turn on guardrails', 'watch for destructive commands'."
argument-hint: "[optional: on|off to toggle]"
allowed-tools: Read Grep Glob Bash
---

# /careful — Destructive Operation Guardrails

Session-scoped guardrails that warn before any destructive or irreversible operation.

## Step 1 — Activate Guard Mode

Parse `$ARGUMENTS`: no argument or `on` activates; `off` deactivates (jump to Step 3). Print `FORGE /careful — Activated`.

## Step 2 — Intercept Pattern

Before executing ANY command while active, check against these destructive patterns:

**Git High Risk:** `git push --force`/`-f`/`--force-with-lease` to main/master, `git reset --hard`, `git clean -f`/`-fd`/`-fdx`, `git branch -D`, `git checkout -- .`/`git restore .` (discard all), `git stash drop`/`clear`, `git rebase` on shared branches.

**Git Medium Risk:** `git push --force` to non-main branches, `git branch -D` on branches with unmerged commits.

**File System:** `rm -rf` on project directories or paths outside project; overwriting files with uncommitted changes.

**Database:** `DROP TABLE/DATABASE`, `TRUNCATE`, `DELETE` without `WHERE`, `ALTER TABLE ... DROP COLUMN`.

**Warning output** — display then wait for explicit user confirmation:
```
FORGE /careful — WARNING
  Command: [exact command]  Risk: [what could be lost]
  Reversible: [yes/no + how]  Alternatives: [safer option(s)]
```

Force push to main/master requires double confirmation: "Are you absolutely sure? This rewrites shared history."

| Destructive Command | Safer Alternative |
|---|---|
| `git push --force` | `git push --force-with-lease` |
| `git reset --hard` | `git stash` or `git reset --soft` |
| `git clean -f` | `git clean -n` (dry run first) |
| `git branch -D` | `git branch -d` (refuses if unmerged) |
| `git checkout -- .` | `git stash` (preserves changes) |
| `rm -rf directory` | `mv directory directory.bak` |
| `DROP TABLE` | `ALTER TABLE ... RENAME TO ..._backup` |

## Step 3 — Deactivate

Print `FORGE /careful — Deactivated`. Standard safety defaults still apply.

## Rules & Compliance

- Every flagged command needs user acknowledgment; always present a safer alternative. Force push to main/master always requires double confirmation.
- Session-scoped only — does not persist across sessions; subagents do NOT inherit it.
- Only flag genuinely destructive operations — regular `git add/commit/push/pull`, `rm` on single files pass through.
- If confirmed after warning, proceed — careful mode advises, it does not block.

Follow `skills/shared/compliance-telemetry.md`. Log via `scripts/compliance-log.sh`. Keys: `destructive-allowed` (critical) — op allowed without acknowledgment; `force-push-main` (critical) — force push to main without double confirmation.

`/careful` is a support skill — continue your current workflow with guardrails active. See `skills/shared/workflow-routing.md`.
