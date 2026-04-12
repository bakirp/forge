---
name: review-adversarial
description: "Adversarial code review — challenges the implementation by actively trying to break it. Focuses on auth gaps, data loss paths, race conditions, rollback safety, and failure modes. Review-only — never modifies code. Use when you want to stress-test a change — triggered by 'adversarial review', 'red team this', 'attack the code', 'break this change', 'challenge the implementation'."
argument-hint: "[optional: focus area or --base <ref>]"
allowed-tools: Read Grep Glob Bash Write
---

# /review adversarial — Adversarial Red-Team Review

**Critical invariant**: This review is read-only and advisory. Never modify code. Every finding must pass the 4-question bar. Verdicts are SHIP/NO-SHIP/SHIP-WITH-CAVEATS, never PASS/FAIL.

## Step 0: Context Detection

**Subagent** (spawned by `forge-adversarial-reviewer`): resolve feature via `bash scripts/manifest.sh resolve-feature-name`, load `.forge/build/${FEATURE_NAME}.md` and `.forge/architecture/*.md`, run `git diff` as sole input, respect architecture deviations and user decisions.
**Inline**: Assume the code is wrong until evidence says otherwise.

## Step 1: Scope Detection

Parse `$ARGUMENTS` for focus text (scrutinize extra hard) and `--base <ref>` (diff reference).

```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
BASE_REF="${PARSED_BASE:-$DEFAULT_BRANCH}"
git diff --name-only ${BASE_REF}...HEAD
git diff ${BASE_REF}...HEAD
```

Read full content of each changed file for complete context. If no changes: `FORGE /review adversarial — ERROR: No code changes found.`

## Step 2: Attack Surface Priorities

Examine code against these 7 attack surfaces, prioritizing expensive, dangerous, or hard-to-detect failures:

| # | Attack Surface | What to look for |
|---|---------------|-----------------|
| 1 | **Auth / permissions / tenant isolation** | Missing auth checks, broken authorization, trust boundary violations, cross-tenant data leaks |
| 2 | **Data loss / corruption / irreversible state** | Writes without rollback, silent data overwrites, truncation, missing backups before destructive ops |
| 3 | **Rollback safety / retries / idempotency** | Non-idempotent operations in retry paths, partial failure leaving inconsistent state, no compensation logic |
| 4 | **Race conditions / ordering / stale state** | TOCTOU bugs, concurrent writes without locking, stale reads used for decisions, re-entrancy issues |
| 5 | **Empty-state / null / timeout / degraded deps** | Null dereferences, missing timeouts on external calls, no graceful degradation when deps are slow or down |
| 6 | **Version skew / schema drift / migration** | Breaking changes without migration, incompatible serialization formats, deploy-order dependencies |
| 7 | **Observability gaps** | Silent failures, missing error logging, unmonitored critical paths, no way to detect or recover from failure |

Actively disprove the change — trace bad inputs, retries, concurrent actions, and partial completions through code paths. If user supplied a focus area, weight it heavily but still check all surfaces.

## Step 3: Execute Review

For each surface: read relevant files, trace the attack vector through the full code path, confirm handling with evidence or record as FINDING. Never skip surfaces — if genuinely irrelevant, mark CLEAR with a one-line reason.

## Step 4: Finding Bar

**Only report material findings.** Each must answer:
1. **What can go wrong?** — Concrete failure scenario
2. **Why is this code vulnerable?** — Cite specific file and lines
3. **What is the likely impact?** — Severity and blast radius
4. **What concrete change would reduce the risk?** — Actionable recommendation

**Calibration**: Prefer one strong finding over several weak ones. A clean review with zero findings is valid.

## Step 5: Write Report

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
## commit_sha: [from git rev-parse HEAD]
## tree_hash: [from git rev-parse HEAD^{tree}]
## Summary
[1-3 sentence verdict]
## Attack Surface Coverage
| # | Surface | Result | Finding |
|---|---------|--------|---------|
[7 rows — each CLEAR or FINDING with ref]
## Findings
[Per finding: Severity, Confidence (0.0-1.0), File, Lines, 4-question answers. If none: "No material findings."]
## Verdict
[SHIP / NO-SHIP / SHIP-WITH-CAVEATS with reasoning]
```

## Step 6: Report Result

```bash
head -8 .forge/review/adversarial.md
```

Output must include `## Status:` and `## commit_sha:` lines.

```
FORGE /review adversarial — [SHIP | NO-SHIP | SHIP-WITH-CAVEATS]
Attack surfaces checked: 7
Findings: [N] (critical: [N], major: [N])
Focus: [area or "general"]
Report: .forge/review/adversarial.md
```

> **Routing**: See `skills/shared/workflow-routing.md`. After SHIP or SHIP-WITH-CAVEATS recommend `/verify`; after NO-SHIP recommend fixing then re-running.

## Rules, Compliance & Error Handling

- **Never modify code** — read-only observation only. **Evidence before claims** — cite file, line, and code. **No style feedback** — failure modes and security only. **Honest severity** — do not inflate; clean reviews are valid. **Respect user-approved deviations** — only flag if they introduce concrete risk. **Status values** — SHIP/NO-SHIP/SHIP-WITH-CAVEATS only.
- **Compliance & Telemetry**: See `skills/shared/compliance-telemetry.md`. Log via `scripts/compliance-log.sh` and `scripts/telemetry.sh`. Keys: `code-modified` (critical), `ungrounded-finding` (major), `surface-skipped` (major). Telemetry: `review-adversarial completed`, phase `review`.
- **Error handling**: If a file or check fails, mark "NOT CHECKED: [reason]" in coverage table and continue. Never claim all surfaces checked if any were skipped.
