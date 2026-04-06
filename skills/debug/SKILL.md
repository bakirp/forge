---
name: debug
description: "Root-cause-first debugging. Structured reproduction, evidence collection, hypothesis testing, and targeted fix. Produces a debug report with verified root cause and fix. Use when something is broken — triggered by 'error', 'bug', 'broken', 'failing', 'crash', 'not working', 'investigate', 'why does', 'fix this bug'."
argument-hint: "[bug description, error message, or failing test]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /debug — Root-Cause-First Debugging

You find and fix bugs through structured investigation. No shotgun fixes, no guessing — evidence first, then hypotheses, then a targeted fix. Every debug session produces a self-contained report.

## Step 1: Understand the Bug

Read `$ARGUMENTS` for the bug description, error message, or failing test name.

If no arguments provided, ask the user what is broken.

Gather initial context:
- Read error logs or failing test output
- Check recent git changes: `git log --oneline -10`
- Scan relevant files mentioned in the error

```
FORGE /debug — Investigating: [1-line bug summary]
```

## Step 2: Reproduce

Before analyzing anything, try to trigger the bug:
- Run the failing test, or
- Execute the steps that produce the error, or
- Trigger the code path described in the report

Capture the actual error output and stack trace.

```bash
# Run the failing test or trigger the error
[project test command] [specific test or script]
```

If the bug reproduces, record the exact output. If it does not reproduce:
```
FORGE /debug — Cannot reproduce

Attempted: [what was tried]
Result: [what happened instead]
Proceeding with static analysis.
```

## Step 3: Collect Evidence

**Do this BEFORE forming any hypotheses.** This is the key discipline.

Gather facts systematically:
- **Stack trace**: Read every file mentioned in the stack trace
- **Recent changes**: `git log --oneline -20 -- [affected files]` and `git diff HEAD~5 -- [affected files]`
- **Related code**: Grep for the function name, error message, and similar patterns
- **Test coverage**: Check what tests exist for the affected code
- **Configuration**: Check env vars, config files, and dependency versions if relevant

Record what you find — each piece of evidence is a fact, not an interpretation.

## Step 4: Form Hypotheses

Based on the evidence collected, form 1-3 hypotheses ranked by likelihood:

```
FORGE /debug — Hypotheses

Based on evidence collected:

1. [Most likely] Description — supported by [evidence]
2. [Possible] Description — supported by [evidence]
3. [Less likely] Description — would explain [symptom] but contradicts [evidence]
```

Each hypothesis must cite specific evidence. If you cannot cite evidence, it is a guess, not a hypothesis.

## Step 5: Test Hypotheses

For each hypothesis, starting with the most likely:

1. Design a minimal test that would confirm or rule it out
2. Run the test
3. Record the result: CONFIRMED or RULED OUT

```
Hypothesis 1: [description]
Test: [what was done to verify]
Result: [CONFIRMED | RULED OUT]
```

If the first hypothesis is ruled out, proceed to the next. If all are ruled out, return to Step 3 and collect more evidence.

## Step 6: Fix

Once the root cause is confirmed:

1. **Propose** the fix — describe the minimal change that addresses the root cause
2. **Show the diff** before applying — let the user see what will change
3. **Apply** the fix
4. **Run the failing test** — it must now pass
5. **Run the full test suite** — no regressions

```bash
# Run the originally failing test
[project test command] [specific test]

# Run full suite
[project test command]
```

```
FORGE /debug — Fix applied

Failing test: now PASSING
Full suite: [passed]/[total] passing
Regressions: none
```

If the fix introduces regressions, address them before proceeding.

## Step 7: Write Debug Report

Create `.forge/debug/` if it doesn't exist.

Write to `.forge/debug/report.md`:

```markdown
# FORGE Debug Report

## Date: [timestamp]
## Bug: [1-line description]
## Status: [RESOLVED | UNRESOLVED | PARTIAL]

## Symptoms
[What was observed — error messages, failing tests, unexpected behavior]

## Root Cause
[What actually caused the issue — specific file, line, and mechanism]

## Evidence
- [Evidence 1: what was observed and where]
- [Evidence 2: what was observed and where]

## Hypotheses Tested
1. [Hypothesis] — [CONFIRMED | RULED OUT] — [how tested]

## Reproduction Steps
1. [Step 1]
2. [Step 2]

## Fix Applied
- File: [path]
- Change: [description]
- Diff: [before/after or reference to git diff]

## Verification
- Failing test now passes: [yes/no]
- Full test suite: [pass/fail]
- No regressions: [yes/no]
```

If the bug is UNRESOLVED, the report still captures all evidence and ruled-out hypotheses — this is valuable for the next attempt.

## Step 8: Report Result

```
FORGE /debug — [RESOLVED | UNRESOLVED]

Bug: [summary]
Root cause: [1-line explanation]
Fix: [1-line description]
Report: .forge/debug/report.md

[If RESOLVED]: Fix applied and verified. Resume workflow.
[If UNRESOLVED]: Could not identify root cause. Evidence collected in report.
```

If the fix touches security-sensitive code, flag it:
```
Security note: Fix modifies [auth/crypto/input validation/etc.]. Flag for /ship review.
```

## Rules

- Evidence before claims — never assert a root cause without supporting evidence
- Always try to reproduce before analyzing
- Test hypotheses systematically — do not shotgun fixes at the problem
- Minimal fix only — do not refactor surrounding code during debugging
- Run tests after fixing — no "it should work" without proof
- If the fix touches security-sensitive code, note it for /ship
- The debug report must be self-contained — someone reading it cold should understand the full story
- If you cannot find the root cause after thorough investigation, say so honestly — do not fabricate
- Never modify tests to make them pass — fix the implementation, not the assertions
- If the bug reveals an architecture gap, note it but do not fix it here — that is /architect work
