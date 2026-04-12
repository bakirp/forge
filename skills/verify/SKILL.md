---
name: verify
description: "Cross-platform QA using Playwright. Detects project domain (web app, API, data pipeline) and runs appropriate verification: browser flows, contract validation, or output diffing. Produces a pass/fail report that /ship consumes. Use when testing the build output — triggered by 'verify it works', 'run QA', 'test the endpoints', 'check if it works'."
argument-hint: "[optional: web|api|pipeline to override domain detection]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /verify — Cross-Platform QA

You verify that `/build` output actually works and produce a pass/fail report that `/ship` reads — if you report failures, `/ship` will block. **Show terminal output for all test commands.** Do not modify application code — verification is read-only observation.

> **Shared rules apply** — see `skills/shared/rules.md`.

## Step 0: Context Detection

**If subagent**: resolve feature via `bash scripts/manifest.sh resolve-feature-name`, load build report `.forge/build/${FEATURE_NAME}.md` and `.forge/architecture/*.md`. **If inline**: proceed.

## Step 1: Prerequisites Gate

Run the project's test suite. If tests fail, block immediately:
```bash
bash scripts/compliance-log.sh verify tests-failing critical "Tests failing before verification — build is not clean"
```
```
FORGE /verify — Blocked. Unit tests failing. Run /build to fix before verifying.
```
Check coverage threshold if configured (`bash scripts/quality-gate.sh coverage`). Block if below.

## Step 2: Detect Domain

Use `$ARGUMENTS` if provided, otherwise auto-detect:

| Domain | Signal | What to look for |
|--------|--------|-------------------|
| **Web App** | Browser output | HTML files, GUI, web server — MUST browser-test via `/browse` |
| **API** | Endpoint definitions | Routes, request/response handling, API specs |
| **Pipeline** | Data transformation | ETL logic, processing scripts, input-to-output flow |
| **CLI** | Terminal program | Argument parsing, stdin/stdout, compiled binaries |
| **Hybrid** | Multiple signals | Run all applicable strategies |

Confirm detection with user before proceeding:
```
FORGE /verify — Domain detected: [WEB | API | PIPELINE | CLI | HYBRID]
Verification strategy: [list strategies]. Proceed? (y/n)
```

## Step 3: Runtime Behavior Pre-Check

Before running tests, trace execution paths in source code. Structural checks (file existence, syntax) confirm well-formedness, not correctness. Flag issues diagnosable from code reading alone; include findings under "Runtime Analysis" in the report.

## Step 4: Browser Delegation

**Web domain only** — delegate to `/browse` with key user flows. Results go to `.forge/browse/report.md`. Skip for API, pipeline, CLI.

## Step 5: Run Verification

### Web App
Delegated to `/browse`. Incorporate results from `.forge/browse/report.md` (flow statuses, failure screenshots).

### API
Test every endpoint from the architecture doc with `curl -s -w "\n%{http_code}"`. Verify: status codes, response shape vs contract, error cases, auth enforcement. Validate against OpenAPI spec if present.

Detect auth mechanism (JWT/API key/session) from codebase; if no test credentials exist, flag and skip auth-required tests.

### Pipeline
Locate test data from fixtures or architecture doc. Use dry-run mode if available; never fabricate data. Run pipeline, diff actual vs expected, check schema and error handling.

### CLI
Build project, run with documented inputs, verify exit codes and stdout/stderr. Test error cases (invalid args, missing files). Diff outputs against expected; check `--help` accuracy.

## Step 6: Compile Report

```bash
FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)
mkdir -p .forge/verify
```

Write `.forge/verify/${FEATURE_NAME}.md` with required sections:
- **Header**: `## Status: PASS|FAIL`, Date, Domain, `commit_sha`, `tree_hash`
- **Summary**: tests run / passed / failed / skipped
- **Results** (per test): Status, details, expected vs actual on FAIL
- **Failures** (if any): test name, component, severity (critical/major/minor), suggested fix
- **Coverage Notes**: verified components, unverified (with reason), edge cases
- **Coverage Metrics**: line coverage %, threshold, PASS/FAIL/NOT_MEASURED

## Step 7: Report Result

```
FORGE /verify — [PASS | FAIL]
Tests: [passed]/[total] | Domain: [domain]
Report: .forge/verify/${FEATURE_NAME}.md
[If failures]: Critical: [n] | Major: [n] | Minor: [n]
```

## Rules, Error Handling & Compliance

- Never mark FAIL as PASS — `/ship` trusts this report.
- Test against architecture doc contracts, not just "does it run."
- Screenshots mandatory on every web test failure; Playwright failure is not a reason to fall back to curl.
- If a step fails to execute (server won't start, curl times out): mark as **FAIL** with details. Distinguish "tested and failed" from "NOT TESTED" (with reason). Continue other checks.
- Functional testing is never optional — unfamiliar structure is not a reason to skip.
- Reason about runtime, not just structure — missing a code-diagnosable bug is a verification failure.
- Evidence before claims — show actual output, not summaries.

## What's Next

If PASS: next is `/ship`. If FAIL: fix via `/build` then re-run `/verify`. See `skills/shared/workflow-routing.md`.

**Compliance** — follow `skills/shared/compliance-telemetry.md`. Log phase-transition telemetry via `scripts/telemetry.sh` per shared protocol. Keys:
- `verify / code-modified / critical` — code modified during read-only verification
- `verify / false-pass / critical` — failing verification marked as PASS
- `verify / browser-testing-skipped / major` — browser testing skipped for web domain
- `verify / no-evidence / major` — results claimed without showing runner output
