---
name: finish
description: "Completes a feature branch lifecycle. Runs final checks, merges the worktree back, and cleans up. The counterpart to /worktree. Use when done with a feature branch — triggered by 'finish the branch', 'merge back', 'done with this worktree', 'close the feature'."
argument-hint: "[optional: branch-name to finish]"
allowed-tools: Read Grep Glob Write Bash
---

# /finish — Branch Completion and Cleanup

Close the loop on a feature branch: run checks, merge back, clean up the worktree. Counterpart to `/worktree`.

## Step 1: Identify Branch

Use `$ARGUMENTS` if provided; otherwise detect via `git rev-parse --abbrev-ref HEAD` and `git worktree list`. If neither works, list worktrees and ask the user. Detect base branch: `DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)`.

## Step 2: Pre-Finish Checks

Run from the worktree directory (`cd .forge/worktrees/[branch-name]`):

1. **Tests** — detect and run the project's test suite
2. **Uncommitted changes** — `git status --porcelain`; if dirty, offer to commit first
3. **FORGE reports** — resolve via `bash scripts/manifest.sh resolve-feature-name`. If `.forge/review/${FEATURE_NAME}.md` is FAIL/NEEDS_CHANGES or `.forge/verify/${FEATURE_NAME}.md` is FAIL: **block merge**. Missing reports: warn, don't block.

```
FORGE /finish — Pre-checks
Branch: [branch-name] | Tests: [PASS|FAIL] | Uncommitted: [yes/no]
Review: [PASS|FAIL—blocked|not found—warning] | Verify: [PASS|FAIL—blocked|not found—warning]
[Ready to finish | Cannot merge — resolve issues | Warnings — override? (y/n)]
```

If tests fail, strongly recommend fixing; if user overrides, note it and continue.

## Step 3: Merge Strategy

```bash
git log --oneline $DEFAULT_BRANCH..[branch-name]
git diff --stat $DEFAULT_BRANCH..[branch-name]
```

Show commit count, short log, files changed, and diff stat summary. Ask to proceed. Check fast-forward: `git merge-base --is-ancestor $DEFAULT_BRANCH [branch-name]`. If possible use `--ff-only`; otherwise offer rebase-then-ff or merge commit.

## Step 4: Merge Back

```bash
git checkout $DEFAULT_BRANCH
git merge --ff-only [branch-name]
# Or: git merge [branch-name] -m "Merge [branch-name] into $DEFAULT_BRANCH"
```

On conflicts: list conflicted files, help resolve each by reading both sides, then `git add` and commit with "(conflicts resolved)" note.

## Step 5: Clean Up

```bash
git worktree remove .forge/worktrees/[branch-name]
git branch -d [branch-name]
```

If `-d` fails (unmerged commits), warn and investigate — never use `-D` automatically.

## Step 6: Report

```
FORGE /finish — Complete
Branch [branch-name] merged into [default-branch].
Worktree cleaned up. Files changed: [count] | Commits merged: [count]
```

> **Next:** `/ship` to create a PR and deploy, or `/review` if code review hasn't been done yet.

## Rules & Compliance

Never force-delete a branch (`-d` not `-D`). Always show diff summary before merging. Help resolve merge conflicts — never abort. If pre-checks fail without override, stop and explain. If no branch specified and not in a worktree, list options — don't guess.

> **Compliance logging and telemetry:** follow `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh`. Keys: `force-delete-branch` (critical), `silent-merge` (major), `merge-despite-failure` (major). **General rules and error handling:** follow `skills/shared/rules.md`.
