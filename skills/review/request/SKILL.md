---
name: review-request
description: "Prepare a scoped review request for human reviewers or structured /review execution. Defines review criteria, focus areas, and context. Use instead of /review when you need custom review criteria, want to scope the review, or are preparing a review for a human teammate — triggered by 'prepare a review', 'set up code review', 'request review from', 'scope the review'."
argument-hint: "[optional: specific PR, branch, or focus area]"
allowed-tools: Read Grep Glob Bash
---

# /review-request — Formalize a Review

Define scope, criteria, and context so `/review` or a human reviewer can work from a structured request.

> **Shared protocols apply** — see `skills/shared/rules.md`, `skills/shared/compliance-telemetry.md`, `skills/shared/workflow-routing.md`.

## Step 1: Identify What to Review

Parse `$ARGUMENTS` for one of these; if none, detect default branch via `bash scripts/detect-branch.sh`:
- **PR number:** `gh pr view $PR --json files,additions,deletions,baseRefName,headRefName`
- **Branch:** `git diff --stat $BRANCH...HEAD`
- **File paths:** `git diff --stat -- $FILES`
- **No arguments:** `git diff --stat "$DEFAULT_BRANCH"..."$CURRENT_BRANCH"`

If no changes detected, stop early. Show scope: files changed, lines added/removed.

## Step 2: Gather Context

Check for architecture doc (`ls -t .forge/architecture/*.md 2>/dev/null | head -1`), read recent commits (`git log --oneline "$DEFAULT_BRANCH".."$CURRENT_BRANCH"`), and identify affected components from changed paths.

## Step 3: Define Review Criteria

Present default criteria and let the user adjust before proceeding:

```
FORGE /review-request — Review scope
Changes: [N] files, [+added/-removed] lines
Branch: [current] → [base]
Components affected: [list]
Review criteria (default):
  ☑ Spec compliance    ☑ Code quality    ☑ Security surface
  ☐ Performance (--perf)    ☐ Accessibility (--a11y)
Focus area: [from arguments, or "general"]
```

Enable Performance if `--perf`, Accessibility if `--a11y` in `$ARGUMENTS`.

## Step 4: Write Review Request

Create `.forge/review/request.md` (mkdir if needed) with fields:
- **Header:** date, branch, requested-by
- **Scope:** files, components, architecture doc path (or N/A)
- **Criteria:** checked/unchecked list from Step 3
- **Focus/Context/Commits:** attention areas, key decisions, and included commits

## Step 5: Report

Print request file path, scope stats, and next step (`/review` or share with human).

## Rules & Compliance

Always show scope before formalizing; let the user adjust criteria; include enough context that reviewers won't need to ask "why." The request is input for `/review`, not a gate.

Compliance keys for `scripts/compliance-log.sh`: `scope-not-shown` (major) — request formalized without showing scope; `empty-review-request` (minor) — request created with no changes detected.
