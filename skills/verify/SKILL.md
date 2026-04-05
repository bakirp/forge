---
name: verify
description: "Cross-platform QA using Playwright. Detects project domain (web app, API, data pipeline) and runs appropriate verification: browser flows, contract validation, or output diffing. Produces a pass/fail report that /ship consumes."
argument-hint: "[optional: web|api|pipeline to override domain detection]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /verify — Cross-Platform QA

You verify that `/build` output actually works. You produce a pass/fail report that `/ship` reads — if you report failures, `/ship` will block.

## Step 1: Check Prerequisites

Verify the build completed:
```bash
# Check that tests pass
# Detect test runner and run it
```

If tests are failing, stop immediately:
```
FORGE /verify — Blocked

Unit tests are failing. Run /build to fix before verifying.
Failing tests: [list]
```

## Step 2: Detect Domain

Determine the project type to choose the right verification strategy. Check `$ARGUMENTS` first — if the user specified a domain, use it.

Otherwise, auto-detect:

### Web App
Signals: `package.json` with a framework (Next.js, React, Vue, Svelte, etc.), HTML templates, `public/` or `static/` directory, CSS/SCSS files, routes that serve pages.

### API
Signals: Route handlers returning JSON, OpenAPI/Swagger spec, no HTML templates, framework is Express/Fastify/Hono/Flask/Django REST/Go net/http/etc.

### Data Pipeline
Signals: ETL scripts, data processing files, `.sql` files, pandas/polars/dbt usage, input/output file patterns, no HTTP server.

### Hybrid
If multiple signals present, run all applicable strategies.

Present detection:
```
FORGE /verify — Domain detected: [WEB | API | PIPELINE | HYBRID]

Verification strategy:
- [strategy 1]
- [strategy 2]

Proceed? (y/n, or override with: /verify web|api|pipeline)
```

## Step 3: Ensure Playwright

If verification needs browser testing (web domain):

```bash
# Check if Playwright is available (use npx or bunx depending on runtime)
npx playwright --version 2>/dev/null || bunx playwright --version 2>/dev/null || echo "NOT_INSTALLED"
```

If not installed:
```bash
# Install @playwright/test (not just playwright) — the test specs import from it
npm install --save-dev @playwright/test
npx playwright install chromium
```

For API and pipeline domains, Playwright is not required — skip this step.

## Step 4: Run Verification

### Web App Verification

Create a Playwright test file for the key user flows from the architecture doc:

```javascript
// .forge/verify/web-flows.spec.js
const { test, expect } = require('@playwright/test');

test.describe('FORGE Verification', () => {
  // Generate tests based on:
  // 1. Key user flows from the architecture doc
  // 2. Edge cases that affect UI
  // 3. Error states and their display
});
```

Run with (use `npx` if Node is available, `bunx` if only Bun is installed):
```bash
npx playwright test .forge/verify/ --reporter=list
```

On failure, capture screenshots:
```bash
npx playwright test .forge/verify/ --reporter=list --screenshot=on
```

Screenshots save to `.forge/verify/screenshots/`. For each failure, note:
- What was expected
- What happened
- Screenshot path

### API Verification

Test every endpoint defined in the architecture doc:

```bash
# Start the server if not running
# For each endpoint:
curl -s -w "\n%{http_code}" -X [METHOD] [URL] \
  -H "Content-Type: application/json" \
  -d '[request body]'
```

Verify for each endpoint:
- **Status code** matches expected
- **Response shape** matches the API contract (all fields present, correct types)
- **Error cases** return proper error responses
- **Auth** is enforced where specified

If an OpenAPI/Swagger spec exists, validate responses against it.

### Data Pipeline Verification

For pipeline projects:
- Run the pipeline with test input data
- Diff the output against expected output
- Check row counts, schema, and data types
- Verify error handling for malformed input

```bash
# Run pipeline with test data
# Diff output
diff <(actual_output) <(expected_output)
```

## Step 5: Compile Report

Write the verification report to `.forge/verify/report.md`:

```markdown
# FORGE Verification Report

## Status: [PASS | FAIL]
## Date: [timestamp]
## Domain: [WEB | API | PIPELINE]

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
- [If FAIL] Screenshot: [path, if applicable]

## Failures (if any)

### [Failure 1]
- Test: [name]
- Component: [which architecture component]
- Severity: [critical | major | minor]
- Details: [what went wrong]
- Suggested fix: [brief suggestion]

## Coverage Notes
- Architecture components verified: [list]
- Components NOT verified: [list, with reason]
- Edge cases tested: [count from architecture doc]
```

## Step 6: Report Result

```
FORGE /verify — [PASS ✓ | FAIL ✗]

Tests: [passed]/[total]
Domain: [detected domain]
Report: .forge/verify/report.md
[If failures]:
  Critical: [count]
  Major: [count]
  Minor: [count]

[If PASS]: Ready for /ship.
[If FAIL]: Fix failures before /ship. Run /build to address issues, then /verify again.
```

## Rules

- Never mark FAIL as PASS — /ship trusts this report
- Always test against the architecture doc contracts, not just "does it run"
- Screenshots are mandatory on every web test failure
- If the server won't start, that's a FAIL — don't skip verification
- If Playwright install fails, report it clearly — don't fall back to curl for web testing
- The report must be machine-readable enough for /ship to parse the status
- Do not modify application code — verification is read-only observation
