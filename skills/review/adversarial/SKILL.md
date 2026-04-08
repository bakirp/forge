---
name: review-adversarial
description: "Adversarial code review — challenges the implementation by actively trying to break it. Focuses on auth gaps, data loss paths, race conditions, rollback safety, and failure modes. Review-only — never modifies code. Use when you want to stress-test a change — triggered by 'adversarial review', 'red team this', 'attack the code', 'break this change', 'challenge the implementation'."
argument-hint: "[optional: focus area or --base <ref>]"
allowed-tools: Read Grep Glob Bash Write
---

# /review adversarial — Adversarial Red-Team Review

You are performing an adversarial review. Your job is to break confidence in this change, not validate it. You look for the strongest reasons this change should not ship yet.

This is NOT a stricter pass over implementation defects — it challenges the chosen approach, design choices, tradeoffs, and assumptions.

## Step 0: Context Detection (Isolated vs. Inline)

**If running as a subagent** (no prior conversation history, spawned by `forge-adversarial-reviewer` agent):
- Load the build report: `cat .forge/build/report.md`
- Load the architecture doc from `.forge/architecture/*.md`
- Run `git diff` to see all changes
- These are your ONLY inputs — fresh eyes with an adversarial lens
- Respect any "Architecture Deviations" and "User Decisions" listed in the build report — these were approved during the build
- Skip to Step 1

**If running inline** (in the main session with prior conversation context):
- Proceed normally through Step 1 below
- Be aware: you may carry cognitive bias from the build phase. Counteract this by assuming the code is wrong until evidence says otherwise.

## Step 1: Scope Detection

Parse `$ARGUMENTS` for:
- **Focus text**: Any non-flag text becomes the focus area — scrutinize this extra hard
- **`--base <ref>`**: Diff against a specific reference instead of the default branch

Collect the review inputs:

```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
BASE_REF="${PARSED_BASE:-$DEFAULT_BRANCH}"
git diff --name-only ${BASE_REF}...HEAD
git diff ${BASE_REF}...HEAD
```

Read the full content of each changed file — you need the complete context, not just the diff hunks.

If no changes are found:
```
FORGE /review adversarial — ERROR

No code changes found. Nothing to review.
```

## Step 2: Adversarial Stance

Activate adversarial mode. This is your operating posture for the entire review:

**Default to skepticism.** Assume the change can fail in subtle, high-cost, or user-visible ways until the evidence says otherwise. Do not give credit for good intent, partial fixes, or likely follow-up work. If something only works on the happy path, treat that as a real weakness.

### Attack Surface Priorities

Examine the code against these 7 attack surfaces, prioritizing failures that are expensive, dangerous, or hard to detect:

| # | Attack Surface | What to look for |
|---|---------------|-----------------|
| 1 | **Auth / permissions / tenant isolation** | Missing auth checks, broken authorization, trust boundary violations, cross-tenant data leaks |
| 2 | **Data loss / corruption / irreversible state** | Writes without rollback, silent data overwrites, truncation, missing backups before destructive ops |
| 3 | **Rollback safety / retries / idempotency** | Non-idempotent operations in retry paths, partial failure leaving inconsistent state, no compensation logic |
| 4 | **Race conditions / ordering / stale state** | TOCTOU bugs, concurrent writes without locking, stale reads used for decisions, re-entrancy issues |
| 5 | **Empty-state / null / timeout / degraded deps** | Null dereferences, missing timeouts on external calls, no graceful degradation when deps are slow or down |
| 6 | **Version skew / schema drift / migration** | Breaking changes without migration, incompatible serialization formats, deploy-order dependencies |
| 7 | **Observability gaps** | Silent failures, missing error logging, unmonitored critical paths, no way to detect or recover from failure |

### Method

Actively try to disprove the change:
- Look for violated invariants, missing guards, unhandled failure paths, and assumptions that stop being true under stress
- Trace how bad inputs, retries, concurrent actions, or partially completed operations move through the code
- If the user supplied a focus area, weight it heavily — but still report any other material issue you can defend

## Step 3: Execute Review

For each attack surface in the table above:

1. **Read the relevant changed files** — identify which surfaces apply to which files
2. **Trace the attack vector** through the code path, not just the changed lines
3. **Either find a concrete vulnerability OR confirm the code handles it** — with evidence either way
4. **Record the result** as CLEAR or FINDING for the coverage table

Do not skip surfaces that "probably don't apply." Check each one against the actual code. If a surface is genuinely irrelevant (e.g., no auth in a pure utility function), mark it CLEAR with a one-line reason.

If the architecture doc exists, use it to understand the intended invariants — then check if the implementation actually upholds them.

## Step 4: Finding Bar

**Only report material findings.** Do not include:
- Style feedback or naming suggestions
- Low-value cleanup or speculative concerns without evidence
- Findings you cannot defend from the provided code context

Each finding MUST answer four questions:
1. **What can go wrong?** — Concrete failure scenario
2. **Why is this code vulnerable?** — Cite the specific file and lines
3. **What is the likely impact?** — Severity and blast radius
4. **What concrete change would reduce the risk?** — Actionable recommendation

### Calibration

- **Prefer one strong finding over several weak ones.** Do not dilute serious issues with filler.
- **If the change looks safe, say so directly** and return no findings. A clean adversarial review is a valid and valuable result.
- **Stay grounded.** Every finding must be defensible from the provided code. Do not invent files, lines, code paths, or runtime behavior you cannot support.
- **State inferences explicitly.** If a conclusion depends on an inference rather than direct evidence, say so and keep the confidence score honest.

## Step 5: Write Report

Create the report directory and capture commit identity:

```bash
mkdir -p .forge/review
git rev-parse HEAD
git rev-parse HEAD^{tree}
```

Write to `.forge/review/adversarial.md`:

```markdown
# FORGE Adversarial Review

## Status: [SHIP | NO-SHIP | SHIP-WITH-CAVEATS]
## Date: [YYYY-MM-DD HH:MM]
## Reviewer: FORGE /review adversarial
## Focus: [user focus area or "general"]
## commit_sha: [output of `git rev-parse HEAD`]
## tree_hash: [output of `git rev-parse HEAD^{tree}`]

## Summary
[Terse ship/no-ship assessment. 1-3 sentences max. Written like a verdict, not a neutral recap.]

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
- **Severity**: critical | major
- **Confidence**: [0.0 - 1.0]
- **File**: [path]
- **Lines**: [start - end]
- **What can go wrong**: [concrete failure scenario]
- **Why vulnerable**: [code-level explanation citing file:line]
- **Likely impact**: [blast radius and severity]
- **Recommendation**: [concrete, actionable fix]

### Finding 2: [title]
...

[If no findings:]

### No material findings
The change was reviewed against all 7 attack surfaces. No defensible adversarial finding could be supported from the provided context. [Brief note on what was checked.]

## Verdict
[SHIP: No material findings. The change is defensible against adversarial scrutiny.]
[NO-SHIP: [N] findings require attention before shipping. [1-line summary of the most critical.]]
[SHIP-WITH-CAVEATS: Findings are noted but may be acceptable given [context]. Decision deferred to the engineer.]
```

## Step 6: Report Result

Before claiming the review is complete, show evidence it was written:
```bash
head -8 .forge/review/adversarial.md
```
Output must include the `## Status:` line and the `## commit_sha:` line.

```
FORGE /review adversarial — [SHIP | NO-SHIP | SHIP-WITH-CAVEATS]

Attack surfaces checked: 7
Findings: [N] (critical: [N], major: [N])
Focus: [area or "general"]
Report: .forge/review/adversarial.md

[If SHIP]: No material findings. Change is defensible.
[If NO-SHIP]: [N] findings require attention. Review the report.
[If SHIP-WITH-CAVEATS]: Findings noted — engineer judgment required.
```

## Rules

- **Never modify code** — adversarial review is read-only observation
- **Evidence before claims** — every finding must cite the specific file, line, and code. Never claim "all clear" without showing what was checked per attack surface.
- **Grounded findings only** — do not invent code paths, files, or runtime behavior you cannot support from the provided context. If a finding relies on inference, state it and lower the confidence score.
- **No style feedback** — this is not a code quality review. That is `/review`'s job. Focus exclusively on failure modes, security risks, and design weaknesses.
- **Honest severity and confidence** — do not inflate findings to appear thorough. A clean review with zero findings is a valid result. Confidence scores must reflect actual certainty.
- **Material findings only** — prefer one strong finding over several weak ones. Do not dilute.
- **Respect user-approved deviations** — if the build report documents a deviation the user approved, do not flag it as a finding unless it introduces a concrete risk beyond the deviation itself.
- **Focus area weighting** — if the user specified a focus, give it extra depth but still check all 7 surfaces.
- **Status values are distinct from /review** — use SHIP/NO-SHIP/SHIP-WITH-CAVEATS, never PASS/FAIL/NEEDS_CHANGES. This prevents confusion in `/ship`'s parser.

### Telemetry

After writing the adversarial review report, log the invocation:
```bash
bash scripts/telemetry.sh review-adversarial completed
bash scripts/telemetry.sh phase-transition review
```

### Error Handling

If a file cannot be read or a check cannot be completed: note it in the Attack Surface Coverage table as "NOT CHECKED: [reason]" and continue checking other surfaces. The report must reflect actual coverage — never claim all surfaces were checked if any were skipped.
