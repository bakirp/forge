---
name: worktree
description: "Creates an isolated git worktree for a task. Sets up a feature branch, configures the environment, and provides a clean workspace that /finish will complete. Use when starting isolated work — triggered by 'create a worktree', 'isolated workspace', 'set up a worktree', 'work in isolation'."
argument-hint: "[branch-name or task description]"
allowed-tools: Read Grep Glob Write Bash
---

# /worktree — Isolated Workspace Setup

All task work happens in `.forge/worktrees/` — never touch the main checkout.

> Shared protocols: `skills/shared/rules.md`, `skills/shared/compliance-telemetry.md`, `skills/shared/workflow-routing.md`.

## Step 1: Determine Branch Name

Slugify `$ARGUMENTS` (lowercase, hyphens, strip special chars) and prefix with `forge/`. Use directly if already a valid branch name. If `$ARGUMENTS` is empty, ask the user.

```bash
BRANCH="forge/$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
```

## Step 2: Check Prerequisites

- **Git repo** — `git rev-parse --git-dir`; stop if not a repo.
- **Clean working dir** — `git status --porcelain`; if dirty, offer to stash.
- **No duplicates** — check `git branch --list` and `git worktree list`; offer to switch if branch exists, stop if worktree path exists.

## Step 3: Detect Base Branch

```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
```

If undetected, ask the user which branch to base off.

## Step 4: Create Worktree

Create `.forge/worktrees/` if needed; ensure `.forge/.gitignore` exists with `*`.

```bash
git worktree add -b [branch-name] .forge/worktrees/[branch-name] $DEFAULT_BRANCH
```

Verify with `git worktree list`; on failure report error and suggest fixes.

## Step 5: Configure Environment

In the new worktree: copy `.env.example`/`.env.template`/`.env.sample` as `.env` if found; detect package manager and run install. The worktree shares `.git` with the main repo — commits are visible from both.

## Step 6: Report

```
FORGE /worktree — Ready

Branch: [branch-name]
Worktree: .forge/worktrees/[branch-name]
Base: [default-branch]

Work in this isolated copy. When done, run /finish to merge back.
```

## What's Next

Run /build to implement, then /finish to merge back and clean up.

## Rules & Compliance

Never create a worktree on an existing branch — offer to switch. Always branch from the detected default branch. Worktree path is always `.forge/worktrees/`. Follow `skills/shared/compliance-telemetry.md`; log violations via `scripts/compliance-log.sh`:

| rule_key | severity | trigger |
|----------|----------|---------|
| `existing-branch` | major | Worktree created on already-existing branch |
| `wrong-path` | major | Worktree created outside `.forge/worktrees/` |
| `uncommitted-not-warned` | minor | Dirty working dir not warned about |

```bash
bash scripts/telemetry.sh worktree completed
```
