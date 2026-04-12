---
name: review
description: "Code review gate between /build and /verify. Reads build output and architecture doc, checks spec compliance, code quality, and security surface. Produces a review report that /ship consumes. Routes to /review-request and /review-response sub-commands. Use when code needs reviewing — triggered by 'review the code', 'check the implementation', 'code review'."
argument-hint: "[optional: specific files or focus area]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /review — Code Review Gate

**Never modify code during review — read-only only.** Every finding must cite `file:line` with evidence. Reason about runtime behavior, not just structure — missing a diagnosable bug is a review failure.

> Shared rules: `skills/shared/rules.md` | Compliance & telemetry: `skills/shared/compliance-telemetry.md` | Routing: `skills/shared/workflow-routing.md`

## Sub-Command Routing

| Argument prefix | Delegate to |
|--------|-------------|
| `request [context]` | `/review-request` |
| `response [context]` | `/review-response` |
| `adversarial [context]` | `/review-adversarial` |
| *(none / other)* | Full review below |

For UI projects, also consider `/design review` for visual/UX quality.

## Step 0: Context Detection

**Subagent**: resolve feature via `bash scripts/manifest.sh resolve-feature-name`, load `.forge/build/${FEATURE_NAME}.md` + `.forge/architecture/*.md`, run `git diff`. Respect "Architecture Deviations" and "User Decisions" from build report. Skip to Step 1.
**Inline**: proceed normally.

## Step 1: Load Context

Read `.forge/architecture/*.md` (the contract). If `$ARGUMENTS` specifies files/focus, narrow scope.

No arch doc AND no git diff → halt: `bash scripts/compliance-log.sh review no-review-input critical "No architecture doc and no git diff"`

Read the diff:
```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
git diff ${DEFAULT_BRANCH}...HEAD
git diff --name-only ${DEFAULT_BRANCH}...HEAD
```

## Step 2: Spec Compliance Review

Compare implementation against every arch doc section — PASS or note deviation with severity:
- **API Contracts** — signatures, inputs, outputs, error types, response shapes match spec?
- **Component Boundaries** — no logic leaking across assigned ownership?
- **Edge Cases** — every listed edge case handled correctly?
- **Test Strategy** — specified tests present (happy path, errors, edge cases)?
- **Security Considerations** — doc security measures addressed?

Tiny tasks without arch doc: note "N/A (tiny task)".

## Step 3: Runtime Behavior Analysis

Mentally trace execution for each component — "what happens when this runs?":
1. **Initialization** — environment ready (DOM, data, services, dependencies)?
2. **Assumptions** — dimensions, ordering, availability, state that may not hold?
3. **Triggers** — events in unhandled order?
4. **Cleanup** — resources (listeners, timers, connections) released on context change?

If diagnosable from code alone, flag it — do NOT defer to `/verify`.

## Step 4: Code Quality Review

Review changed files across these dimensions:
- **Readability** — descriptive names, logical structure, "why" comments where non-obvious
- **Duplication** — `bash scripts/quality-gate.sh dry-check . $(git diff --name-only ${DEFAULT_BRANCH}...HEAD)`
- **Path Coverage** — `bash scripts/quality-gate.sh path-map . $(git diff --name-only ${DEFAULT_BRANCH}...HEAD | grep -vE '(test|spec|__test__|_test\.)')` — flag untested (critical), duplicate tests (major), orphaned (minor)
- **Reusability** — `bash scripts/quality-gate.sh reusability-search . [new-function-names]`
- **Complexity** — nested conditionals, god functions, logic needing extraction
- **Error Handling** — proportional at boundaries, no silent swallowing
- **Types and Contracts** — consistent with interfaces, no `any`/unchecked casts at entry points

## Step 5: Security Surface Pre-Check

Lightweight OWASP subset (not the full audit `/ship` performs):
- **Injection** — string concat in SQL/shell/templates, user input to eval/exec
- **Auth/Authz** — missing auth on routes, bypassable authorization
- **Data Exposure** — secrets in code, PII in logs, verbose error internals
- **Input Validation** — unvalidated user input at boundaries

## Step 6: Cross-Model Second Opinion (Optional)

For large (>10 files) or security-critical changes, recommend cross-model review. If approved, spawn subagent with different model focusing on logic errors, security, untested edge cases. Merge and deduplicate.

## Step 7: Write Review Report

```bash
mkdir -p .forge/review
FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)
git rev-parse HEAD        # commit_sha
git rev-parse HEAD^{tree} # tree_hash
```

Write `.forge/review/${FEATURE_NAME}.md` with:
- **Header**: Status (PASS|FAIL|NEEDS_CHANGES), Date, Reviewer, Architecture path, commit_sha, tree_hash
- **Summary**: files reviewed, issue counts by severity
- **Sections**: Spec Compliance, Runtime Behavior, Code Quality, Security Surface, Coverage (tool/line%/threshold/status), Path Coverage (total/tested/untested/duplicate/orphaned)
- **Issues**: severity, file:line, description, suggested fix
- **Verdict**: PASS (no critical/major) | NEEDS_CHANGES (major) | FAIL (critical)

## Step 8: Report Result

Verify: `head -6 .forge/review/${FEATURE_NAME}.md` — must include `## Status:` and `## commit_sha:`.

```
FORGE /review — [PASS | NEEDS_CHANGES | FAIL]
Files reviewed: [N]
Issues: [N] (critical: [N], major: [N], minor: [N], suggestions: [N])
Report: .forge/review/${FEATURE_NAME}.md
```

## Rules, Compliance & What's Next

**Verdict logic**: critical → FAIL; major (no criticals) → NEEDS_CHANGES; minor/suggestions only → PASS. Coverage below threshold or untested condition path → critical. Duplicate tests → major.

**Invariants**: Never modify code. Always check arch doc when present. No arch doc + no diff → error. Report status must be parseable by `/ship`. No rubber-stamps — show evidence before claims. Honest severity, no inflation or downgrading. Focus-area args get extra depth but full review still runs. Unreadable files → "NOT REVIEWED: [reason]" in report.

**Compliance keys** (protocol: `skills/shared/compliance-telemetry.md`): `code-modified` (critical), `rubber-stamp` (major), `severity-misclassified` (major), `ungrounded-finding` (major). Log phase-transition telemetry via `scripts/telemetry.sh` and compliance via `scripts/compliance-log.sh` per shared protocol.

## What's Next

If PASS → `/verify`. If NEEDS_CHANGES → fix then re-run `/review`. If FAIL → rework needed. See `skills/shared/workflow-routing.md`.
