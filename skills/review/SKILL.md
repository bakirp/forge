---
name: review
description: "Code review gate between /build and /verify. Reads build output and architecture doc, checks spec compliance, code quality, and security surface. Produces a review report that /ship consumes. Routes to /review-request and /review-response sub-commands. Use when code needs reviewing — triggered by 'review the code', 'check the implementation', 'code review'."
argument-hint: "[optional: specific files or focus area]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

## Quick Routing

Default (no arguments, or "review the code", "code review", "check the implementation"):
→ Run the full review below.

If argument starts with "request", or user says "prepare a review", "scope the review":
→ Delegate to `/review-request`

If argument starts with "response", or user says "fix review comments", "address feedback", "respond to review":
→ Delegate to `/review-response`

If argument starts with "adversarial", or user says "red team this", "attack the code", "break this change":
→ Delegate to `/review-adversarial`

# /review — Code Review Gate

You review what `/build` produced before `/verify` runs. You never modify code — you observe, judge, and report. Your review report is consumed by `/ship`, so the format matters.

## Step 0: Context Detection (Isolated vs. Inline)

Detect whether you are running as an isolated subagent or inline in the main session:

**If running as a subagent** (no prior conversation history, spawned by `forge-reviewer` agent):
- Load the build report: `cat .forge/build/report.md`
- Load the architecture doc from `.forge/architecture/*.md`
- Run `git diff` to see all changes
- These are your ONLY inputs — you have fresh eyes, which is an advantage
- Respect any "Architecture Deviations" and "User Decisions" listed in the build report — these were approved during the build
- Skip to Step 1 (no routing needed — you are running a full review)

**If running inline** (in the main session with prior conversation context):
- Proceed normally through Routing and Step 1 below
- You benefit from conversation context but may carry self-evaluation bias from the build phase

## Routing

If `$ARGUMENTS` starts with a sub-command, delegate:

| Argument | Action |
|----------|--------|
| `request [context]` | Invoke `/review-request` with the remaining arguments |
| `response [context]` | Invoke `/review-response` with the remaining arguments |
| `adversarial [context]` | Invoke `/review-adversarial` with the remaining arguments |
| *(anything else or no argument)* | Proceed to Step 1 below (run code review) |

## Step 1: Load Context

Find the architecture doc:

```bash
ls .forge/architecture/*.md
```

If `$ARGUMENTS` specifies files or a focus area, narrow the review scope accordingly.

If an architecture doc exists, read it — this is the contract the implementation must satisfy.

If no architecture doc exists:
- Check if this was a **tiny** task (no arch doc expected) — review anyway using the git diff as the sole source of truth
- If there is no arch doc AND no git diff, there is nothing to review:

```
FORGE /review — ERROR

No architecture doc and no code changes found. Nothing to review.
```

Read the git diff to see what was actually changed:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff ${DEFAULT_BRANCH}...HEAD
git diff --name-only ${DEFAULT_BRANCH}...HEAD
```

Collect the list of changed files and their contents. This is what you are reviewing.

## Step 2: Spec Compliance Review

Compare the implementation against every section of the architecture doc. For each section, determine PASS or note the deviation:

**API Contracts**
- Do function signatures, inputs, outputs, and error types match what the doc specifies?
- Are all declared endpoints present with the correct methods and response shapes?

**Component Boundaries**
- Is each file responsible for what the architecture doc assigns to it?
- Is there logic leaking across boundaries (e.g., a route handler doing database queries directly)?

**Edge Cases**
- Is every edge case listed in the architecture doc handled in the implementation?
- Are the handling strategies correct (not just present but correct)?

**Test Strategy**
- Are the tests specified in the architecture doc present?
- Do they cover the cases the doc requires (happy path, errors, edge cases)?

**Security Considerations**
- Are the security measures noted in the architecture doc addressed?

Flag every deviation as an issue with a severity level.

For **tiny tasks** without an architecture doc, skip this step and note "N/A (tiny task)" in the report.

## Step 3: Runtime Behavior Analysis

Before checking code quality, reason about how the code **actually behaves at runtime** — not just whether it looks correct structurally. Checking file existence, syntax validity, or import correctness is not a review — those are structural properties. The review must ask: **"What happens when this code executes?"**

For each component in the diff, mentally trace its execution path:

1. **When does it initialize?** Is the environment it depends on ready at that point? (DOM rendered, data loaded, services connected, container visible, dependencies available)
2. **What assumptions does it make?** Does it assume dimensions, ordering, availability, or state that may not hold in all execution contexts?
3. **What triggers it?** Can user actions, network responses, or lifecycle events arrive in an order the code doesn't handle?
4. **What cleans up after it?** Are resources (listeners, timers, connections, subscriptions) released when the context changes?

If you identify a runtime behavior issue that is diagnosable from code reading alone, flag it — do NOT defer it to `/verify` or claim "this needs browser testing." If you can read the code and reason about the bug, that is a review finding.

## Step 4: Code Quality Review

Review all changed files for:

**Readability**
- Are names descriptive and consistent with the codebase?
- Is the structure logical — can a new reader follow the flow?
- Are comments present where the "why" is non-obvious (not everywhere)?

**Duplication**
- Are there copy-paste patterns that should be extracted into shared functions?
- Is the same logic implemented in multiple places?

Run automated duplication detection on changed files:
```bash
bash scripts/quality-gate.sh dry-check . $(git diff --name-only ${DEFAULT_BRANCH}...HEAD)
```
Include any findings in the Duplication section of the review report.

**Path Coverage Completeness**

Verify that tests cover all condition paths without duplication:
```bash
bash scripts/quality-gate.sh path-map . $(git diff --name-only ${DEFAULT_BRANCH}...HEAD | grep -vE '(test|spec|__test__|_test\.)')
```
For each path in the output, confirm a corresponding test exists. Flag:
- **Untested path** (critical): condition branch at [file:line] has no test → must add test
- **Duplicate test** (major): path [path_id] is tested by multiple test cases → consolidate into one
- **Orphaned test** (minor): test exists for a path that was removed → delete test

**Reusability**

For each new function/class in the diff, check if similar implementations already exist:
```bash
bash scripts/quality-gate.sh reusability-search . [new-function-names-from-diff]
```
If the search finds existing code that could have been reused, flag it as a major issue: "Duplicate implementation — existing function at [file:line] provides equivalent functionality."

**Complexity**
- Are there deeply nested conditionals or loops that should be flattened?
- Are there god functions doing too many things?
- Can any complex logic be broken into named steps?

**Error Handling**
- Are errors handled at system boundaries (API layer, file I/O, network calls)?
- Is error handling proportional — not paranoid internally, not absent at edges?
- Are errors swallowed silently anywhere?

**Types and Contracts**
- Are types consistent with declared interfaces?
- Are there `any` types, unchecked casts, or missing validations at entry points?

## Step 5: Security Surface Review

This is a lightweight pre-check — not the full OWASP audit that `/ship` performs. Flag anything obvious:

**Injection Risks**
- String concatenation in SQL queries, shell commands, or template rendering
- User input passed directly to `eval()`, `exec()`, `Function()`, or similar

**Auth/Authz Gaps**
- Routes or endpoints missing authentication checks
- Authorization logic that can be bypassed
- Privilege escalation paths

**Sensitive Data Exposure**
- Secrets, tokens, or credentials in code or config files committed to the repo
- PII or sensitive data in log statements or error responses
- Verbose error messages that leak internals

**Input Validation**
- User input at system boundaries that is not validated or sanitized
- Missing length limits, type checks, or format validation on external input

## Step 6: Cross-Model Second Opinion (Optional)

When working on complex or security-critical code, a second opinion from a different model can catch blind spots.

If the review scope is large (>10 files) or touches security-critical code (auth, payments, encryption):

```
FORGE /review — Recommending cross-model review

This change is [large | security-critical]. A second-opinion review from a different model may catch additional issues.

Request cross-model review? (y/n)
```

If approved, spawn a subagent with a different model for perspective diversity:

```
You are a FORGE cross-model reviewer. Review this code independently:

Changed files: [list]
Architecture doc: [path or summary]

Focus on:
1. Logic errors the primary reviewer may have missed
2. Security vulnerabilities
3. Edge cases not covered by tests

Report your findings as a numbered list of issues with severity.
```

Merge findings with the primary review. Deduplicate — if both models flag the same issue, note it with extra confidence. If the secondary model finds something the primary missed, include it with a note: "Flagged by cross-model review."

## Step 7: Write Review Report

Create the report directory and write the report:

```bash
mkdir -p .forge/review
```

Write to `.forge/review/report.md`:

Before writing, capture the current commit identity:
```bash
git rev-parse HEAD
git rev-parse HEAD^{tree}
```

```markdown
# FORGE Review Report

## Status: [PASS | FAIL | NEEDS_CHANGES]
## Date: [YYYY-MM-DD HH:MM]
## Reviewer: FORGE /review
## Architecture: [path to arch doc or "N/A (tiny task)"]
## commit_sha: [output of `git rev-parse HEAD`]
## tree_hash: [output of `git rev-parse HEAD^{tree}`]

## Summary
- Files reviewed: [count]
- Issues found: [count]
- Critical: [count]
- Major: [count]
- Minor: [count]
- Suggestions: [count]

## Spec Compliance
[For each architecture doc section, note PASS or describe the deviation]

## Runtime Behavior
[Findings from reasoning about how the code behaves at runtime — initialization order, hidden containers, race conditions, lifecycle issues. "None found" if clean, with evidence of what was checked.]

## Code Quality
[Findings organized by category: readability, duplication, complexity, error handling, types]

## Security Surface
[Pre-check findings or "No issues found"]

## Coverage
- Coverage tool: [detected or configured]
- Line coverage: [XX%]
- Threshold: [YY% or "not configured"]
- Status: [PASS | FAIL | NOT_MEASURED]

## Path Coverage
- Total paths: [N]
- Tested: [N]
- Untested: [N] (list)
- Duplicate tests: [N] (list)
- Orphaned tests: [N] (list)

## Issues

### Issue 1: [title]
- **Severity**: critical | major | minor | suggestion
- **File**: [path:line]
- **Description**: [what is wrong]
- **Suggested fix**: [brief recommendation]

### Issue 2: [title]
...

## Verdict
[PASS: No critical or major issues. Ready for /verify.]
[NEEDS_CHANGES: N major issues must be fixed. Fix them, then run /review again.]
[FAIL: Fundamental problems found. May need to revisit /architect.]
```

## Step 8: Report Result

Before claiming the review is complete, show evidence it was written:
```bash
head -6 .forge/review/report.md
```
Output must include the `## Status:` line and the `## commit_sha:` line. Do not claim the review is complete without showing this output.

```
FORGE /review — [PASS | NEEDS_CHANGES | FAIL]

Files reviewed: [N]
Issues: [N] (critical: [N], major: [N], minor: [N], suggestions: [N])
Report: .forge/review/report.md

[If PASS]: Ready for /verify.
[If NEEDS_CHANGES]: Fix [N] issues, then run /review again.
[If FAIL]: Fundamental problems found. May need to revisit /architect.
```

## Rules

- Any **critical** issue makes the review automatically **FAIL**
- Any **major** issue (with no criticals) makes the review **NEEDS_CHANGES**
- Only **minor** issues and **suggestions** allow a **PASS**
- Coverage below configured threshold is a **critical** issue (automatic FAIL)
- Any untested condition path is a **critical** issue (automatic FAIL)
- Duplicate tests covering the same path is a **major** issue (NEEDS_CHANGES)
- Never modify code — review is read-only observation
- Always check against the architecture doc when one exists
- If no architecture doc and no git diff, report an error — do not fabricate a review
- The report status line format must be parseable by `/ship` — do not deviate from it
- Do not rubber-stamp — if you find nothing wrong, say so explicitly, but verify you actually checked every category
- Severity must be honest: do not inflate minor issues to major, do not downgrade major issues to minor
- When `$ARGUMENTS` specifies a focus area, still do a full review but give extra depth to the requested area
- **Evidence before claims** — every finding must cite the specific file, line, and code. Never report "no issues" without showing what was checked.
- **Reason about runtime, not just structure** — checking file existence, syntax, and CSS coverage is not a review. Ask "what happens when this runs?" for every component. If a bug is diagnosable from reading the code, it is a review failure to miss it — do not defer to `/verify` what you can catch by reasoning.
- **Cross-model review is optional** — only recommended for large or security-critical changes, never forced

### Telemetry
After writing the review report, log the invocation and phase transition:
```bash
bash scripts/telemetry.sh review completed
bash scripts/telemetry.sh phase-transition review
```

### Error Handling
If a file cannot be read or a check cannot be completed: note it in the review report as "NOT REVIEWED: [reason]" and continue reviewing other areas. The report must reflect actual coverage — never claim full review if areas were skipped.
