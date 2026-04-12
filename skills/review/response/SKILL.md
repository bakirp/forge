---
name: review-response
description: "Process and act on review feedback from /review or human reviewers. Extracts action items, prioritizes fixes (blocking/recommended/suggestions), and tracks resolution. Use when review feedback needs triaging and systematic resolution — triggered by 'fix review comments', 'address feedback', 'process review findings', 'respond to review', 'triage review items'."
argument-hint: "[optional: path to review feedback or PR comment URL]"
allowed-tools: Read Grep Glob Write Edit Bash
---

# /review-response — Process Review Feedback

Read the actual code before implementing any suggestion. Never implement feedback you haven't verified against the codebase — being helpful means being honest, not agreeable.

> **Shared rules apply** — see `skills/shared/rules.md` for evidence-before-claims, no-secrets, scope discipline, artifact integrity.
> **Compliance & telemetry** — see `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh`. Skill-specific keys below.
> **Workflow routing** — see `skills/shared/workflow-routing.md`.

## Step 1: Load Feedback

Locate feedback by priority:
- `$ARGUMENTS` file path — read it directly
- `$ARGUMENTS` PR URL/number — `gh pr view $PR --comments --json comments`
- Resolve `FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)`, check `.forge/review/${FEATURE_NAME}.md`
- None found — ask the user (do not guess)

## Step 2: Verify Feedback Technically (Anti-Sycophancy Gate)

Before accepting any item, verify it is technically correct:
- **Read the actual code** — do not assume the reviewer is right
- **Check each claim**: Does the issue exist? Is the line/behavior real?
- **Push back on incorrect feedback**: If wrong or would cause regression — say so
- **Flag subjective opinions**: Style preferences become suggestions, not blockers
- **Architecture doc wins**: Contradicting feedback needs user override

```
FORGE /review-response — Verified: [N] | Rejected: [N] | Reclassified: [N]
```

Do NOT skip this step.

## Step 3: Extract Action Items

Parse **verified** feedback into three tiers:

```
Must fix (blocking):    1. [Issue] — [file:line] — [action]
Should fix (recommended): 2. [Issue] — [file:line] — [action]
Consider (suggestions): 3. [Issue] — [description]
Total: [N] items ([N] blocking, [N] recommended, [N] suggestions)
```

**Classification**: Blocking = security, spec violations, broken functionality, data loss. Recommended = code quality, error handling, naming, duplication. Suggestions = style, alternatives, minor optimizations.

## Step 4: Prioritize and Plan

Order blocking items by dependency (foundations first). Note scope, overlaps, and architecture-doc contradictions. Present plan and **wait for user approval** before applying fixes.

## Step 5: Execute Fixes

Only proceed if user approves.
- **Blocking**: Apply fix, run tests, mark resolved
- **Recommended** (< 10 lines): Apply; if ambiguous or large, defer with reason
- **Suggestions**: Note only; do not apply unless user asks

Run the project's test suite after each fix.

## Step 6: Update Review Status

If `.forge/review/${FEATURE_NAME}.md` has `NEEDS_CHANGES` — update after all blockers resolved; do NOT change verdict to `APPROVED` (requires `/review`). Write resolution log to `.forge/review/response.md`:

```markdown
# FORGE Review Response — [YYYY-MM-DD] — [source]
## Resolved: [item]: [what was done]
## Deferred: [item]: [reason]
## Notes: [context for next review pass]
```

## Step 7: Report

```
FORGE /review-response — Complete
Resolved: [N] | Deferred: [N] | Remaining blockers: [N]
[No blockers]: Ready for /review. [Blockers remain]: [N] items need attention.
```

## Rules & Compliance

Never skip blocking items. Run tests after each fix. Don't auto-fix ambiguous issues — ask. Track fixes/deferrals with reasons. Flag architecture-doc conflicts explicitly. Never change a review verdict yourself. Verify before responding — no performative agreement.

| Rule Key | Severity | Trigger |
|----------|----------|---------|
| `blocking-items-skipped` | critical | Blocking items skipped without resolution |
| `unverified-feedback` | major | Feedback implemented without reading code |
| `verdict-changed` | critical | Verdict changed instead of re-running /review |
| `tests-not-run-after-fix` | major | Fix applied without running tests |
