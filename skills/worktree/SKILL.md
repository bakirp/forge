---
name: worktree
description: "Creates an isolated git worktree for a task. Sets up a feature branch, configures the environment, and provides a clean workspace that /finish will complete. Use when starting isolated work — triggered by 'create a worktree', 'isolated workspace', 'new feature branch', 'work in isolation'."
argument-hint: "[branch-name or task description]"
allowed-tools: Read Grep Glob Write Bash
---

# /worktree — Isolated Workspace Setup

You create a clean, isolated workspace for a task. The worktree lets work happen without touching the main checkout.

## Step 1: Determine Branch Name

From `$ARGUMENTS`, derive the branch name:

- If it looks like a branch name (lowercase, hyphens, no spaces): use it directly
- If it's a task description: slugify it (lowercase, replace spaces with hyphens, strip special chars)
- Always prefix with `forge/` (e.g., `forge/add-auth-endpoint`)

```bash
# Example slugification
BRANCH="forge/$(echo "$ARGUMENTS" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
```

If `$ARGUMENTS` is empty, ask the user for a branch name or task description. Do not proceed without one.

## Step 2: Check Prerequisites

### Verify Git Repository

```bash
git rev-parse --git-dir
```

If not a git repo, stop:
```
FORGE /worktree — ERROR
Not a git repository. Initialize with `git init` first.
```

### Check Working Directory

```bash
git status --porcelain
```

If dirty (uncommitted changes):
```
FORGE /worktree — Warning

Uncommitted changes detected:
  [list changed files]

Stash changes before creating worktree? (y/n)
```

If user says yes: `git stash push -m "forge: stash before worktree [branch-name]"`

### Check for Existing Branch/Worktree

```bash
git branch --list "[branch-name]"
git worktree list
```

If the branch already exists:
```
FORGE /worktree — Branch exists

Branch [branch-name] already exists.
Switch to it instead? (y/n)
```

If a worktree already exists at the target path, report and stop.

## Step 3: Detect Base Branch

Find the repository's default branch — do not assume `main`:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$DEFAULT_BRANCH" ]; then
  # Fallback: check for common names
  for branch in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      DEFAULT_BRANCH="$branch"
      break
    fi
  done
fi
```

If no default branch detected, ask the user which branch to base off.

## Step 4: Create Worktree

Create `.forge/worktrees/` if it doesn't exist.

```bash
git worktree add -b [branch-name] .forge/worktrees/[branch-name] $DEFAULT_BRANCH
```

Verify creation:
```bash
git worktree list
ls .forge/worktrees/[branch-name]
```

If creation fails, report the error and suggest fixes (e.g., branch name conflict, path already exists).

## Step 5: Configure Environment

In the new worktree directory, set up the development environment:

### Copy Non-Tracked Config Files

```bash
# Check for example/template config files in the main checkout
for template in .env.example .env.template .env.sample; do
  if [ -f "$template" ]; then
    cp "$template" ".forge/worktrees/[branch-name]/.env"
    break
  fi
done
```

### Install Dependencies

Detect the package manager and install:

```bash
cd .forge/worktrees/[branch-name]

# Node
if [ -f "package.json" ]; then
  if [ -f "bun.lockb" ]; then bun install
  elif [ -f "pnpm-lock.yaml" ]; then pnpm install
  elif [ -f "yarn.lock" ]; then yarn install
  else npm install
  fi
fi

# Python
if [ -f "requirements.txt" ]; then pip install -r requirements.txt; fi
if [ -f "pyproject.toml" ]; then pip install -e .; fi

# Go
if [ -f "go.mod" ]; then go mod download; fi

# Rust
if [ -f "Cargo.toml" ]; then cargo fetch; fi
```

Note: The worktree shares `.git` with the main repo. Commits made in the worktree are visible from the main checkout.

## Step 6: Report

```
FORGE /worktree — Ready

Branch: [branch-name]
Worktree: .forge/worktrees/[branch-name]
Base: [default-branch]

Work in this isolated copy. When done, run /finish to merge back.
```

## Rules

- Never create a worktree on a branch that already exists — offer to switch instead
- Always branch from the detected default branch, not current HEAD (unless the user explicitly specifies a different base)
- Warn if working directory has uncommitted changes before proceeding
- Worktree path is always under `.forge/worktrees/` — never create worktrees elsewhere
- Keep the main worktree clean — all task work happens in the new worktree
- If `$ARGUMENTS` is empty, ask for a name — do not generate one automatically
