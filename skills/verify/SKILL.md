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

## Step 3: Delegate Browser Testing

If verification needs browser testing (web domain), delegate to `/browse`:

```
Invoke /browse with the key user flows from the architecture doc.
/browse handles Playwright setup, test execution, and screenshot capture.
```

/browse writes its report to `.forge/browse/report.md`. Read that report and incorporate its results into the verification report.

For API and pipeline domains, /browse is not needed — skip this step.

## Step 4: Run Verification

### Web App Verification

Delegated to `/browse`. The browse report at `.forge/browse/report.md` contains:
- Each flow tested with PASS/FAIL status
- Screenshots for any failures at `.forge/browse/screenshots/`

Incorporate the browse results into the verification report below.

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

Create `.forge/verify/` if it doesn't exist.

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
- **Evidence before claims** — never claim PASS without showing actual test output. Every verification must cite the command run, its output, and what was asserted.
- Web domain browser testing is delegated to /browse — /verify is the report-and-gate layer, not the execution layer
