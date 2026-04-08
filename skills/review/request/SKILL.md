---
name: review-request
description: "Prepare a scoped review request for human reviewers or structured /review execution. Defines review criteria, focus areas, and context. Use instead of /review when you need custom review criteria, want to scope the review, or are preparing a review for a human teammate — triggered by 'prepare a review', 'set up code review', 'request review from', 'scope the review'."
argument-hint: "[optional: specific PR, branch, or focus area]"
allowed-tools: Read Grep Glob Bash
---

# /review-request — Formalize a Review

You define the scope, criteria, and context for a code review so that `/review` or a human reviewer can work from a structured request.

## Step 1: Identify What to Review

Parse `$ARGUMENTS` for a PR number, branch name, or file paths.

If arguments are provided:
- PR number: `gh pr view $PR --json files,additions,deletions,baseRefName,headRefName`
- Branch: `git diff --stat $BRANCH...HEAD`
- File paths: `git diff --stat -- $FILES`

If no arguments:
```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
CURRENT_BRANCH=$(git branch --show-current)
git diff --stat "$DEFAULT_BRANCH"..."$CURRENT_BRANCH"
```

Show the scope: files changed, lines added/removed.

## Step 2: Gather Context

1. Check for an architecture doc:
   ```bash
   ls -t .forge/architecture/*.md 2>/dev/null | head -1
   ```
   If found, read it to understand design intent.

2. Read recent commit messages for the changes:
   ```bash
   git log --oneline "$DEFAULT_BRANCH".."$CURRENT_BRANCH"
   ```

3. Identify which components or modules are affected based on directory structure of changed files.

## Step 3: Define Review Criteria

Present the default criteria and let the user adjust:

```
FORGE /review-request — Review scope

Changes: [N] files, [+added/-removed] lines
Branch: [current] → [base]
Components affected: [list]

Review criteria (default):
  ☑ Spec compliance (architecture doc adherence)
  ☑ Code quality (readability, duplication, complexity)
  ☑ Security surface (injection, auth, data exposure)
  ☐ Performance (optional — enable with --perf)
  ☐ Accessibility (optional — enable with --a11y)

Focus area: [from arguments, or "general"]

Adjust criteria? (y/n, or specify focus)
```

If `$ARGUMENTS` contains `--perf`, enable Performance. If `--a11y`, enable Accessibility.

Wait for user confirmation before proceeding.

## Step 4: Write Review Request

Create `.forge/review/` if it doesn't exist.

Write to `.forge/review/request.md`:

```markdown
# FORGE Review Request

## Date: [YYYY-MM-DD]
## Branch: [branch] → [base]
## Requested by: FORGE /review-request

## Scope
- Files: [list]
- Components: [list]
- Architecture doc: [path or N/A]

## Criteria
- [x] Spec compliance
- [x] Code quality
- [x] Security surface
- [ ] Performance
- [ ] Accessibility

## Focus Area
[What deserves extra attention and why]

## Context
[Key decisions, constraints, or tradeoffs the reviewer should know about]

## Commits
[List of commits included in this review]
```

## Step 5: Report

```
FORGE /review-request — Ready

Review request written to .forge/review/request.md
Scope: [N] files across [N] components
Next: Run /review to execute, or share the request with a human reviewer.
```

## Rules

- Always show scope before formalizing the request
- Let the user adjust criteria — don't assume all defaults are correct
- Include enough context that the reviewer doesn't need to ask "why"
- The request is input for `/review`, not a gate — reviews can run without a formal request
- If no changes are detected, stop early and tell the user there is nothing to review
