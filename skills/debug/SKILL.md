---
name: debug
description: "Root-cause-first debugging. Structured reproduction, evidence collection, hypothesis testing, and targeted fix. Produces a debug report with verified root cause and fix. Use when something is broken — triggered by 'error', 'bug', 'broken', 'failing', 'crash', 'not working', 'investigate', 'why does', 'fix this bug'."
argument-hint: "[bug description, error message, or failing test]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /debug — Root-Cause-First Debugging

**Never assert a root cause without supporting evidence.** Evidence first, hypotheses second, targeted fix last. Every session produces a self-contained debug report.

## Step 1: Understand the Bug

Read `$ARGUMENTS` for the bug description, error, or failing test. If no arguments, ask the user what is broken. Gather context: error logs, `git log --oneline -10`, and files mentioned in the error.
```
FORGE /debug — Investigating: [1-line bug summary]
```

## Step 2: Reproduce

Try to trigger the bug before analyzing: run the failing test, execute the error-producing steps, or trigger the described code path. Capture actual error output and stack trace.

If it reproduces, record the exact output. If not:
```
FORGE /debug — Cannot reproduce
Attempted: [what was tried] | Result: [what happened]
Proceeding with static analysis.
```

## Step 3: Collect Evidence

Gather facts BEFORE forming hypotheses:
- **Stack trace**: Read every file mentioned
- **Recent changes**: `git log --oneline -20 -- [files]` and `git diff HEAD~5 -- [files]`
- **Related code**: Grep for function name, error message, similar patterns
- **Test coverage**: Check existing tests for affected code
- **Configuration**: Env vars, config files, dependency versions if relevant

## Step 4: Form Hypotheses

Form 1-3 hypotheses ranked by likelihood. Each must cite specific evidence — unsupported claims are guesses, not hypotheses.
```
FORGE /debug — Hypotheses
1. [Most likely] Description — supported by [evidence]
2. [Possible] Description — supported by [evidence]
3. [Less likely] Description — would explain [symptom] but contradicts [evidence]
```

## Step 5: Test Hypotheses

For each hypothesis (most likely first), design a minimal confirming/ruling-out test, run it, and record the result. If all ruled out, return to Step 3.
```
Hypothesis 1: [description]
Test: [what was done] | Result: [CONFIRMED | RULED OUT]
```

## Step 6: Fix

Propose the minimal fix, show the diff before applying, apply it, then verify: failing test must pass, full suite must pass with no regressions.
```
FORGE /debug — Fix applied
Failing test: now PASSING | Full suite: [passed]/[total] | Regressions: none
```

## Step 7: Write Debug Report

Create `.forge/debug/` if needed. Write `.forge/debug/report.md` with: Date, Bug, Status (RESOLVED|UNRESOLVED|PARTIAL), Symptoms, Root Cause (file+line+mechanism), Evidence, Hypotheses Tested (CONFIRMED/RULED OUT), Reproduction Steps, Fix Applied (file+change+diff), Verification.
If UNRESOLVED, the report still captures all evidence and ruled-out hypotheses.

## Step 8: Report Result

```
FORGE /debug — [RESOLVED | UNRESOLVED]
Bug: [summary] | Root cause: [1-line] | Fix: [1-line]
Report: .forge/debug/report.md
```
If the fix touches security-sensitive code: `Security note: Fix modifies [auth/crypto/etc.]. Flag for /ship review.`

## What's Next

See `skills/shared/workflow-routing.md` and `skills/shared/rules.md` for routing guidance.

## Rules

Reproduce before analyzing. Test hypotheses systematically — no shotgun fixes. Minimal fix only — no refactoring during debug. Run tests after fixing — no assumptions. Never modify tests to pass — fix the implementation. Debug report must be self-contained. If root cause eludes investigation, say so honestly. Architecture gaps go to /architect.

**Compliance:** Follow `skills/shared/compliance-telemetry.md`; log via `scripts/compliance-log.sh`.
Rule keys: `ungrounded-root-cause` (major), `no-reproduction` (major), `scope-creep` (minor).
