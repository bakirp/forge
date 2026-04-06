---
name: finish
description: "Completes a feature branch lifecycle. Runs final checks, merges the worktree back, and cleans up. The counterpart to /worktree. Use when done with a feature branch — triggered by 'finish the branch', 'merge back', 'done with this worktree', 'close the feature'."
argument-hint: "[optional: branch-name to finish]"
allowed-tools: Read Grep Glob Write Bash
---

# /finish — Branch Completion and Cleanup

You close the loop on a feature branch. Run checks, merge back, clean up the worktree. The counterpart to `/worktree`.

## Step 1: Identify Branch

Determine which branch to finish:

1. If `$ARGUMENTS` specifies a branch name, use it
2. If currently inside a worktree, detect the branch:
   ```bash
   git rev-parse --abbrev-ref HEAD
   git worktree list
   ```
3. If neither, list active worktrees and ask:
   ```bash
   git worktree list
   ```
   ```
   FORGE /finish — Which branch?

   Active worktrees:
     [path]  [branch]  [commit]
     ...

   Specify a branch to finish.
   ```

Also detect the base branch (the branch the feature was created from):
```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$DEFAULT_BRANCH" ]; then
  for branch in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      DEFAULT_BRANCH="$branch"
      break
    fi
  done
fi
```

## Step 2: Pre-Finish Checks

Run all checks from the worktree directory:

### Run Tests

```bash
cd .forge/worktrees/[branch-name]
# Detect and run the project's test suite
# Node: npm test / bun test / vitest / jest
# Python: pytest
# Go: go test ./...
# Rust: cargo test
```

### Check for Uncommitted Changes

```bash
cd .forge/worktrees/[branch-name]
git status --porcelain
```

### Check for FORGE Reports

```bash
ls .forge/review/report.md 2>/dev/null
ls .forge/verify/report.md 2>/dev/null
```

### Report Pre-Check Results

```
FORGE /finish — Pre-checks

Branch: [branch-name]
Tests: [PASS | FAIL — N passed, N failed]
Uncommitted changes: [yes/no]
Review report: [found/missing]
Verify report: [found/missing]

[If all good]: Ready to finish.
[If issues]: Resolve before finishing? (y/n to override)
```

If tests fail, strongly recommend fixing before proceeding. If the user overrides, note it but continue.

If there are uncommitted changes, offer to commit them:
```
Uncommitted changes in worktree. Commit them before merging? (y/n)
```

## Step 3: Merge Strategy

### Show Diff Summary

Before any merge, show what will be merged:

```bash
git log --oneline $DEFAULT_BRANCH..[branch-name]
git diff --stat $DEFAULT_BRANCH..[branch-name]
```

```
FORGE /finish — Merge preview

Commits to merge: [count]
  [short log]

Files changed: [count]
  [diff stat summary]

Proceed with merge? (y/n)
```

### Determine Merge Method

```bash
# Check if fast-forward is possible
git merge-base --is-ancestor $DEFAULT_BRANCH [branch-name] && echo "ff-possible"
```

- If fast-forward is possible: use `git merge --ff-only`
- If not: present options to the user:
  ```
  Fast-forward not possible. Choose merge strategy:
    1. Rebase onto [default-branch] then fast-forward
    2. Merge commit (preserves branch history)
  ```

## Step 4: Merge Back

```bash
# Switch to the base branch in the main checkout
git checkout $DEFAULT_BRANCH

# Merge the feature branch
git merge --ff-only [branch-name]
# Or, if user chose merge commit:
git merge [branch-name] -m "Merge [branch-name] into $DEFAULT_BRANCH"
```

If merge conflicts arise:
```
FORGE /finish — Merge conflict

Conflicts in:
  [list of conflicted files]

Resolving conflicts...
```

Help resolve each conflict by reading both sides and producing the correct merge. After resolving:
```bash
git add [resolved files]
git commit -m "Merge [branch-name] into $DEFAULT_BRANCH (conflicts resolved)"
```

## Step 5: Clean Up

After a successful merge:

```bash
# Remove the worktree
git worktree remove .forge/worktrees/[branch-name]

# Delete the feature branch (safe delete — refuses if unmerged)
git branch -d [branch-name]
```

If `git branch -d` fails (unmerged commits), warn the user:
```
FORGE /finish — Warning

Branch [branch-name] has unmerged commits. This should not happen after a successful merge.
Investigate before force-deleting.
```

Never use `git branch -D` (force delete) automatically.

## Step 6: Report

```
FORGE /finish — Complete

Branch [branch-name] merged into [default-branch].
Worktree cleaned up.
Files changed: [count]
Commits merged: [count]

Next: /ship to create a PR and deploy.
```

## Rules

- Never force-delete a branch with unmerged commits — use `-d` not `-D`
- Always show the diff summary before merging — no silent merges
- If merge conflicts arise, help resolve them — do not abort the merge
- Clean up the worktree directory after a successful merge
- If pre-checks fail and the user does not override, stop and explain what needs fixing
- If not inside a worktree and no branch specified, list options — do not guess
