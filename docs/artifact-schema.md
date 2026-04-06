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
    [artifact].md                   <- /design (consult/explore/review)
  benchmark/
    report.md                       <- /benchmark
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
| `/verify` | architecture doc | verify report, screenshots | -- |
| `/debug` | source code, error output | debug report | -- |
| `/browse` | -- | screenshots, logs | -- |
| `/benchmark` | baselines | benchmark report | -- |
| `/design` | -- | design artifacts | -- |
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
