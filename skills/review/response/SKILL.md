---
name: review-response
description: "Process and act on review feedback from /review or human reviewers. Extracts action items, prioritizes fixes (blocking/recommended/suggestions), and tracks resolution. Use when review feedback needs triaging and systematic resolution — triggered by 'fix review comments', 'address feedback', 'process review findings', 'respond to review', 'triage review items'."
argument-hint: "[optional: path to review feedback or PR comment URL]"
allowed-tools: Read Grep Glob Write Edit Bash
---

# /review-response — Process Review Feedback

You take review feedback, extract actionable items, prioritize them, and optionally apply fixes.

## Step 1: Load Feedback

Locate the feedback source using this priority:

1. If `$ARGUMENTS` contains a file path: read that file.
2. If `$ARGUMENTS` contains a PR URL or number: `gh pr view $PR --comments --json comments`
3. If `.forge/review/report.md` exists: read it.
4. If none of the above: ask the user for the feedback source. Do not guess.

Confirm the source before proceeding:
```
FORGE /review-response — Loading feedback from: [source]
```

## Step 2: Verify Feedback Technically (Anti-Sycophancy Gate)

Before accepting any feedback item, verify it is technically correct:

1. **Read the actual code** referenced by the feedback — do not assume the reviewer is right
2. **Check each claim against the codebase**: Does the issue actually exist? Is the line number correct? Is the described behavior real?
3. **Push back on incorrect feedback**: If a suggestion is factually wrong, technically unnecessary, or would introduce a regression — say so explicitly. Do not implement bad suggestions to be agreeable.
4. **Flag subjective opinions**: If feedback is a style preference rather than a correctness issue, classify it as a suggestion, not a blocker — regardless of how the reviewer framed it.
5. **Verify against architecture doc**: If feedback contradicts the architecture doc, the architecture doc wins unless the user explicitly overrides.

```
FORGE /review-response — Technical verification

Feedback items: [N] total
Verified correct: [N]
Incorrect/rejected: [N] (with reasons)
Reclassified: [N] (e.g., "blocking" → "suggestion")
```

Do NOT skip this step. Implementing wrong suggestions wastes time and can introduce bugs. Being helpful means being honest, not agreeable.

## Step 3: Extract Action Items

Parse the **verified** feedback into three priority tiers:

```
FORGE /review-response — Action items extracted

From: [source]

Must fix (blocking):
  1. [Issue] — [file:line] — [what to do]
  2. ...

Should fix (recommended):
  3. [Issue] — [file:line] — [what to do]

Consider (suggestions):
  4. [Issue] — [description]

Total: [N] items ([N] blocking, [N] recommended, [N] suggestions)
```

Classification rules:
- **Blocking**: security vulnerabilities, spec violations, broken functionality, data loss risks
- **Recommended**: code quality issues, missing error handling, poor naming, duplication
- **Suggestions**: style preferences, alternative approaches, minor optimizations

## Step 4: Prioritize and Plan

Order blocking items by dependency — fix foundations before things that depend on them.

For each item, note:
- Estimated scope (one-liner, small change, significant refactor)
- Whether it overlaps or conflicts with other items
- Whether it contradicts the architecture doc (flag these explicitly)

```
FORGE /review-response — Execution plan

Order of fixes:
  1. [item] — [scope estimate]
  2. [item] — [scope estimate]
  ...

Conflicts: [any contradictions with architecture doc, or "none"]
```

Present the plan and wait for user approval before applying fixes.

## Step 5: Execute Fixes

Only proceed if the user approves.

For each **blocking** item:
1. Apply the fix
2. Run tests: `npm test`, `pytest`, or whatever test runner the project uses
3. Mark as resolved

For each **recommended** item:
- If the fix is straightforward (< 10 lines changed): apply it
- If ambiguous or large: note it as deferred and explain why

For **suggestions**: note them but do not apply unless the user specifically asks.

After each fix, verify no regressions:
```bash
# Run the project's test suite
```

## Step 6: Update Review Status

If `.forge/review/report.md` exists and contains a `NEEDS_CHANGES` verdict:
- After all blocking items are resolved, update the status section to reflect progress
- Do not change the verdict to `APPROVED` — that requires a re-review

Create `.forge/review/` if it doesn't exist.

Write a resolution log to `.forge/review/response.md`:
```markdown
# FORGE Review Response

## Date: [YYYY-MM-DD]
## Source: [feedback source]

## Resolved
- [item]: [what was done]

## Deferred
- [item]: [reason for deferral]

## Notes
[Any context for the next review pass]
```

## Step 7: Report

```
FORGE /review-response — Complete

Action items: [N] total
Resolved: [N]
Deferred: [N]
Remaining blockers: [N]

[If no blockers remain]: Ready to re-run /review for fresh assessment.
[If blockers remain]: [N] blocking items still need attention.
```

## Rules

- Never skip blocking items — they must be resolved before re-review
- Run tests after each fix to catch regressions early
- Don't auto-fix ambiguous issues — ask the user for clarification
- Track what was fixed and what was deferred with reasons
- If feedback contradicts the architecture doc, flag the conflict — don't silently choose one side
- Never change a review verdict yourself — only `/review` can issue a new verdict
- **Never implement feedback you haven't verified** — read the code, check the claim, then act
- **Push back on wrong suggestions** — being helpful means being honest. A polite "this suggestion is incorrect because..." is better than silently introducing a bug
- **Do not agree performatively** — phrases like "great catch!" or "absolutely right!" before even checking the code are anti-patterns. Verify first, then respond.
