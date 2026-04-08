# FORGE Artifact Schema

Canonical specification for all artifacts produced and consumed by FORGE skills. Every skill that reads or writes to `.forge/` must conform to these contracts.

---

## Directory Structure

```
.forge/
  architecture/
    [task-name-slugified].md        <- /architect
    [task-name]-brainstorm.md       <- /brainstorm
  review/
    report.md                       <- /review
    adversarial.md                  <- /review adversarial
  verify/
    report.md                       <- /verify
    screenshots/
      [test-name].png               <- /verify (on failure)
  debug/
    report.md                       <- /debug
  browse/
    report.md                       <- /browse
    screenshots/                    <- /browse
  design/
    consult-[topic].md              <- /design consult
    explore-[topic].md              <- /design explore
    review-[topic].md               <- /design review
  benchmark/
    report.md                       <- /benchmark
  build/
    report.md                       <- /build Step 6.5 (handoff artifact)
  context/
    task-{n}.md                     <- /build Step 3.5 (ephemeral)
  runs/
    [run-id]/
      manifest.json                 <- root dispatcher
  releases/
    [version]/
      summary.md                    <- /ship
```

All paths are relative to the project root. Skills must create directories as needed before writing.

---

## Architecture Doc

**Produced by:** `/architect`
**Consumed by:** `/build`, `/review`, `/verify`, `/ship`
**Path:** `.forge/architecture/[task-name-slugified].md`

```markdown
# Architecture: [Task Name]

## Status: LOCKED
> This document was produced by FORGE /architect. Changes require re-running /architect.

## Overview
[1-2 sentences: what we're building and why]

## Data Flow
[How data moves through the system. Text diagrams encouraged.]

Input -> [Step 1] -> [Step 2] -> Output

## API Contracts
[Every new or modified API surface]

### [Endpoint/Function Name]
- Input: [types]
- Output: [types]
- Errors: [error cases]
- Auth: [requirements]

## Component Boundaries
[Modules/files created or modified and their responsibilities]

| Component | Responsibility | Creates/Modifies |
|-----------|---------------|-----------------|
| ... | ... | ... |

## Edge Cases
[Every edge case identified. Each must have a handling strategy.]

1. [Edge case] -> [How it's handled]
2. ...

## Test Strategy
[What gets tested and how]

- Unit tests: [what]
- Integration tests: [what]
- Edge case tests: [which edge cases from above get explicit tests]

## Dependencies
[New packages, services, or infrastructure required]

## Security Considerations
[Auth, data handling, input validation, OWASP relevance]

## Deferred
[What was explicitly decided NOT to build now, and why]
```

### Field Rules

| Field | Required | Notes |
|-------|----------|-------|
| Status | Yes | Always `LOCKED` after /architect completes |
| Overview | Yes | Max 2 sentences |
| Data Flow | Yes | Text diagrams preferred over prose |
| API Contracts | If applicable | Every endpoint must define errors |
| Component Boundaries | Yes | Table format required |
| Edge Cases | Yes | Each must have a handling strategy |
| Test Strategy | Yes | Must reference edge cases |
| Dependencies | If applicable | Omit section if none |
| Security Considerations | Yes | Even if minimal |
| Deferred | Yes | Even if empty, state "Nothing deferred" |

---

## Review Report

**Produced by:** `/review`
**Consumed by:** `/build` (for fixes), `/ship` (for audit trail)
**Path:** `.forge/review/report.md`

```markdown
# FORGE Review Report

## Status: [PASS | FAIL | NEEDS_CHANGES]
## Date: [ISO 8601 timestamp]
## Reviewer: FORGE /review
## commit_sha: [output of `git rev-parse HEAD`]
## tree_hash: [output of `git rev-parse HEAD^{tree}`]

## Summary
- Files reviewed: [count]
- Issues found: [count]
- Critical: [count]
- Suggestions: [count]

## Spec Compliance
[Architecture doc adherence check -- each component boundary verified]

## Code Quality
[Readability, naming, structure, duplication, complexity]

## Security Surface
[Injection, auth, data exposure -- lightweight pre-check before /ship's full audit]

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

### [Issue 1]
- Severity: critical | major | minor | suggestion
- File: [path:line]
- Description: [what's wrong]
- Suggested fix: [brief]

## Verdict
[PASS: ready for /verify | NEEDS_CHANGES: list what to fix | FAIL: fundamental problems]
```

### Required Fields

| Field | Required | Notes |
|-------|----------|-------|
| `commit_sha` | Yes | `git rev-parse HEAD` at write time |
| `tree_hash` | Yes | `git rev-parse HEAD^{tree}` at write time |

### Status Values

| Status | Meaning | Next Step |
|--------|---------|-----------|
| `PASS` | No blocking issues | Proceed to `/verify` |
| `NEEDS_CHANGES` | Fixable issues found | Fix listed items, re-run `/review` |
| `FAIL` | Fundamental problems | Return to `/architect` or `/build` |

### Severity Levels

| Severity | Definition |
|----------|-----------|
| `critical` | Blocks shipping. Security vulnerability, data loss risk, broken contract. |
| `major` | Should fix before shipping. Logic errors, missing error handling. |
| `minor` | Improve if time allows. Style, naming, minor duplication. |
| `suggestion` | Non-blocking recommendation for future improvement. |

---

## Adversarial Review Report

**Produced by:** `/review adversarial`
**Consumed by:** `/ship` (advisory — included in PR if present), human review
**Path:** `.forge/review/adversarial.md`

```markdown
# FORGE Adversarial Review

## Status: [SHIP | NO-SHIP | SHIP-WITH-CAVEATS]
## Date: [ISO 8601 timestamp]
## Reviewer: FORGE /review adversarial
## Focus: [user focus area or "general"]
## commit_sha: [output of `git rev-parse HEAD`]
## tree_hash: [output of `git rev-parse HEAD^{tree}`]

## Summary
[Terse ship/no-ship assessment. 1-3 sentences max.]

## Attack Surface Coverage

| # | Surface | Result | Finding |
|---|---------|--------|---------|
| 1 | Auth / permissions / tenant isolation | [CLEAR / FINDING] | [ref or "—"] |
| 2 | Data loss / corruption / irreversible state | [CLEAR / FINDING] | [ref or "—"] |
| 3 | Rollback safety / retries / idempotency | [CLEAR / FINDING] | [ref or "—"] |
| 4 | Race conditions / ordering / stale state | [CLEAR / FINDING] | [ref or "—"] |
| 5 | Empty-state / null / timeout / degraded deps | [CLEAR / FINDING] | [ref or "—"] |
| 6 | Version skew / schema drift / migration | [CLEAR / FINDING] | [ref or "—"] |
| 7 | Observability gaps | [CLEAR / FINDING] | [ref or "—"] |

## Findings

### Finding 1: [title]
- Severity: critical | major
- Confidence: [0.0 - 1.0]
- File: [path]
- Lines: [start - end]
- What can go wrong: [scenario]
- Why vulnerable: [code-level explanation]
- Likely impact: [blast radius]
- Recommendation: [concrete fix]

## Verdict
[SHIP | NO-SHIP | SHIP-WITH-CAVEATS with rationale]
```

### Status Values

| Status | Meaning |
|--------|---------|
| `SHIP` | No material findings. Change is defensible against adversarial scrutiny. |
| `NO-SHIP` | Material findings require attention before shipping. |
| `SHIP-WITH-CAVEATS` | Findings noted but potentially acceptable. Engineer judgment required. |

### Required Fields

| Field | Required | Notes |
|-------|----------|-------|
| `commit_sha` | Yes | `git rev-parse HEAD` at write time |
| `tree_hash` | Yes | `git rev-parse HEAD^{tree}` at write time |
| Attack Surface Coverage | Yes | All 7 surfaces must have a result |
| Confidence | Per finding | Float 0.0 to 1.0 |

**Note:** Status values (SHIP/NO-SHIP/SHIP-WITH-CAVEATS) are intentionally distinct from `/review`'s (PASS/FAIL/NEEDS_CHANGES) to prevent parser confusion in `/ship`. The adversarial review is advisory — it does not block the pipeline.

---

## Verify Report

**Produced by:** `/verify`
**Consumed by:** `/ship` (blocks on FAIL)
**Path:** `.forge/verify/report.md`
**Screenshots:** `.forge/verify/screenshots/[test-name].png`

```markdown
# FORGE Verification Report

## Status: [PASS | FAIL]
## Date: [ISO 8601 timestamp]
## Domain: [WEB | API | PIPELINE]
## commit_sha: [output of `git rev-parse HEAD`]
## tree_hash: [output of `git rev-parse HEAD^{tree}`]

## Summary
- Tests run: [count]
- Passed: [count]
- Failed: [count]
- Skipped: [count]

## Results

### [Test name]
- Status: PASS | FAIL
- Details: [what was tested]
- [If FAIL] Expected: [expected]
- [If FAIL] Actual: [actual]
- [If FAIL] Screenshot: [path, if web domain]

## Failures

### [Failure 1]
- Test: [name]
- Component: [which architecture component]
- Severity: critical | major | minor
- Details: [what went wrong]
- Suggested fix: [brief suggestion]

## Coverage Notes
- Architecture components verified: [list]
- Components NOT verified: [list, with reason]
- Edge cases tested: [count from architecture doc]

## Coverage Metrics
- Line coverage: [XX%]
- Threshold: [YY% or "not configured"]
- Coverage status: [PASS | FAIL | NOT_MEASURED]
```

### Required Fields

| Field | Required | Notes |
|-------|----------|-------|
| `commit_sha` | Yes | `git rev-parse HEAD` at write time |
| `tree_hash` | Yes | `git rev-parse HEAD^{tree}` at write time |

### Status Rules

- `PASS` -- all tests passed, no critical or major failures.
- `FAIL` -- any test failed. `/ship` will refuse to proceed.

No `NEEDS_CHANGES` status exists for verify. It either passes or it does not.

---

## Debug Report

**Produced by:** `/debug`
**Consumed by:** `/build` (for applying fixes)
**Path:** `.forge/debug/report.md`

```markdown
# FORGE Debug Report

## Date: [ISO 8601 timestamp]
## Bug: [description]

## Root Cause
[What actually caused the issue -- evidence-based]

## Evidence
- [observation 1]
- [observation 2]

## Reproduction
[Steps to reproduce]

## Fix
[Proposed or applied fix]

## Verification
[How the fix was verified]
```

### Field Rules

| Field | Required | Notes |
|-------|----------|-------|
| Bug | Yes | One-line description of the symptom |
| Root Cause | Yes | Must cite evidence, not speculation |
| Evidence | Yes | At least one observation |
| Reproduction | Yes | Numbered steps preferred |
| Fix | Yes | State "proposed" or "applied" |
| Verification | Yes | How correctness was confirmed |

---

## Build Report

**Produced by:** `/build` Step 6.5
**Consumed by:** `/review` (Step 0), `/verify` (Step 0), `/ship` (Step 0), `/autopilot`
**Path:** `.forge/build/report.md`
**Purpose:** Structured handoff artifact for post-build phases. Captures all context that downstream phases need to operate independently — especially when running as isolated subagents with no prior conversation history.

```markdown
# FORGE Build Report

## commit_sha: [git rev-parse HEAD]
## tree_hash: [git rev-parse HEAD^{tree}]
## Date: [YYYY-MM-DD HH:MM]
## Classification: [tiny | feature | epic]
## Architecture: [path to arch doc or "N/A (tiny task)"]

## Files Modified
- path/to/file.ts (created | modified)
- path/to/file.test.ts (created | modified)

## Test Results
- Framework: [detected test runner]
- Passed: [N]/[N]
- Coverage: [XX% or "not measured"]

## Tasks Completed
1. [Task name] — [model used] — PASS
2. [Task name] — [model used] — PASS

## Architecture Deviations
[None | list of deviations with the user's approval rationale]

## User Decisions
[Decisions made during the build that are NOT captured in the architecture doc]
```

**Required fields:** `commit_sha`, `tree_hash`, `Files Modified`, `Test Results`, `Architecture Deviations`, `User Decisions`

**Critical:** The `Architecture Deviations` and `User Decisions` sections capture verbal context that would otherwise be lost when post-build phases run as isolated subagents. If a deviation was user-approved during the build, the reviewer must respect it.

---

## Context Bundle

**Produced by:** `/build` Step 3.5 (Context Pruning)
**Consumed by:** `/build` Step 5 (Subagent Execution)
**Path:** `.forge/context/task-{n}.md`
**Lifecycle:** Ephemeral — created during `/build` when 3+ tasks exist, cleaned at the start of the next `/build` run. Persists between builds for debugging failed builds.

```markdown
# Context Bundle: [Task Name]
> Source: [architecture doc path] | Task: [n]/[total]

## Task
[Task description]

## API Contracts
[Only the contracts this task implements]

## Component Boundaries
[Only the rows relevant to this task]

## Edge Cases
[Only the edge cases this task must handle]

## Test Strategy
[Only the tests this task must write]

## Dependencies
[Only the deps this task needs]

## Security Considerations
[Only security items relevant to this task's scope]

## Project Conventions
- Test runner: [command]
- Framework: [name/version]
- File naming: [pattern]

## Estimated Tokens: [count]
```

**Assembly:** `scripts/context-prune.sh extract` produces the raw section content. `/build` Step 3.5 assembles the full bundle by: (1) writing the header and task description, (2) appending extracted sections, (3) appending `scripts/context-prune.sh conventions` output, (4) appending the token estimate. The schema above shows the final assembled output, not the raw script output.

---

## Run Manifest

**Produced by:** Root dispatcher
**Consumed by:** All skills (for context and state tracking)
**Path:** `.forge/runs/[run-id]/manifest.json`

```json
{
  "id": "run-YYYYMMDD-HHmmss",
  "task": "description of what was requested",
  "started": "ISO 8601 timestamp",
  "status": "active | completed | failed | blocked",
  "phase": "think | brainstorm | architect | build | review | verify | ship | retro | evolve",
  "artifacts": {
    "architecture": ".forge/architecture/task-name.md",
    "review": ".forge/review/report.md",
    "verify": ".forge/verify/report.md",
    "debug": ".forge/debug/report.md"
  },
  "blockers": [],
  "history": [
    { "phase": "think", "status": "completed", "timestamp": "..." },
    { "phase": "architect", "status": "completed", "timestamp": "..." }
  ]
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Format: `run-YYYYMMDD-HHmmss` |
| `task` | string | Original user request, verbatim |
| `started` | string | ISO 8601 timestamp of run start |
| `status` | enum | `active`, `completed`, `failed`, `blocked` |
| `phase` | enum | Current phase the run is in |
| `artifacts` | object | Paths to produced artifacts (relative to project root) |
| `blockers` | array | Strings describing what is blocking progress |
| `history` | array | Ordered log of phase transitions |

### Status Transitions

```
active -> completed    (normal completion)
active -> failed       (unrecoverable error)
active -> blocked      (waiting on external input or failed prerequisite)
blocked -> active      (blocker resolved)
```

---

## Brainstorm Artifact

**Produced by:** `/think` (for feature/epic tasks when multiple approaches exist)
**Consumed by:** `/architect`
**Path:** `.forge/architecture/[task-name-slugified]-brainstorm.md`

```markdown
# FORGE Brainstorm: [Task Name]

## Date: [ISO 8601 timestamp]

## Approaches

### Approach 1: [name]
- Description: [what]
- Tradeoffs: [pros/cons]
- Effort: [low | medium | high]

### Approach 2: [name]
- Description: [what]
- Tradeoffs: [pros/cons]
- Effort: [low | medium | high]

## Selected: [approach name or combination]
## Rationale: [why this was chosen]
```

### Brainstorm Artifact (Grill Mode)

When `/brainstorm --grill` is used, the artifact format captures interrogation results instead of approaches:

```markdown
# FORGE Brainstorm (Grill): [Task Name]

## Date: [ISO 8601 timestamp]
## Mode: Grill
## Plan: [1-2 sentence summary of the plan that was interrogated]

## Decisions Confirmed
- [Decision 1]: [what was confirmed and why]
- [Decision 2]: [what was confirmed and why]

## Risks Identified
- [Risk 1]: [description and severity — low|medium|high]
- [Risk 2]: [description and severity]

## Plan Changes
[List any changes the user agreed to during interrogation. If none: "No changes — plan validated as-is."]

## Open Questions
[Any questions that were not resolved. If none: "All questions resolved."]

## Constraints Discovered
- [any constraints surfaced during grilling]

## Next: /architect
```

| Field | Required | Notes |
|-------|----------|-------|
| Mode | Yes | Always `Grill` for grill artifacts |
| Plan | Yes | Summary of the interrogated plan |
| Decisions Confirmed | Yes | At least one confirmed decision |
| Risks Identified | Yes | Even if empty, state "No risks identified" |
| Plan Changes | Yes | Even if empty, state "No changes" |
| Open Questions | Yes | Even if empty, state "All questions resolved" |

---

## Release Summary

**Produced by:** `/ship`
**Consumed by:** PR description, changelog tooling
**Path:** `.forge/releases/[version]/summary.md`

```markdown
## Summary
- [1-3 bullet points describing the change at a high level]

## Changes

### Features
- [feature descriptions from commits]

### Fixes
- [fix descriptions from commits]

### Security
- [security fixes applied by /ship]

## Verification
- Domain: [from verify report]
- Tests: [pass count from verify report]
- Security audit: [PASS with N warnings | N critical fixed]

## Test Plan
- [ ] [Key scenarios to verify in review]
```

---

## Cross-Artifact Dependencies

Skills read artifacts from prior phases. The dependency chain is strict.

| Skill | Reads | Writes | Blocks if missing |
|-------|-------|--------|-------------------|
| `/think` | -- | run manifest | -- |
| `/brainstorm` | codebase | brainstorm doc | -- |
| `/architect` | memory bank, brainstorm doc | architecture doc | -- |
| `/build` | architecture doc | source code, tests | architecture doc |
| `/review` | architecture doc, source code | review report | -- |
| `/review adversarial` | architecture doc, build report, source code | adversarial review report | -- |
| `/verify` | architecture doc | verify report, screenshots | -- |
| `/debug` | source code, error output | debug report | -- |
| `/browse` | -- | screenshots, logs | -- |
| `/benchmark` | baselines | benchmark report | -- |
| `/design` | codebase, principles.md | design artifacts | -- (recommends `/design review` before `/ship` for frontend) |
| `/ship` | review report, verify report | release summary, PR | review report, verify report |
| `/canary` | build output | canary report | -- |
| `/deploy` | merged PR | deploy report | -- |
| `/retro` | -- | retro data | -- |
| `/evolve` | retro data | updated skill files | -- |

---

## Conventions

- **Timestamps:** Always ISO 8601 (`2026-04-05T14:30:00Z`).
- **Slugification:** Lowercase, hyphens for spaces, strip non-alphanumeric (`Add User Auth` becomes `add-user-auth`).
- **Paths:** Always relative to project root when stored in artifacts.
- **Overwriting:** Skills overwrite their own artifacts on re-run. Previous versions are not preserved unless the user commits between runs.
- **Encoding:** UTF-8, LF line endings.
