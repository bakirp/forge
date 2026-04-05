---
name: browse
description: "Dedicated browser automation skill using Playwright. Executes browser flows, captures screenshots, and reports results. Used by /verify for web domain QA, and available standalone for browser-based tasks."
argument-hint: "[url or flow description]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /browse — Browser Automation with Playwright

You execute browser-based testing flows using Playwright. You can be invoked standalone for ad-hoc browser tasks, or delegated to by `/verify` for web domain QA.

## Step 1: Determine Mode

From `$ARGUMENTS`, determine what to test:
- **URL**: Navigate to the URL and verify it loads, check key elements
- **Flow description**: Parse the described user journey into test steps
- **Test file path**: Execute an existing test specification
- **Called by /verify**: Receives a structured flow specification from the architecture doc

If called standalone with no arguments, ask the user:
```
FORGE /browse — What should I test?

Provide one of:
- A URL to verify (e.g., http://localhost:3000)
- A flow description (e.g., "user signs up, verifies email, logs in")
- A path to an existing test file

Or invoke via /verify for full QA.
```

## Step 2: Ensure Playwright

Check if Playwright is available:
```bash
npx playwright --version 2>/dev/null || bunx playwright --version 2>/dev/null || echo "NOT_INSTALLED"
```

If not installed:
```bash
npm install --save-dev @playwright/test
npx playwright install chromium
```

If install fails, report clearly and stop:
```
FORGE /browse — BLOCKED

Playwright installation failed.
Error: [error message]

Playwright is required for browser automation — no fallback to curl or other tools.
Fix the installation issue and re-run /browse.
```

Do NOT fall back to curl, wget, or MCP browser tools. Playwright is the only accepted browser automation tool.

## Step 3: Determine Browser Flows

From the architecture doc, user input, or /verify delegation, identify key flows to test:

- **Happy path** user journeys (signup, login, core feature usage)
- **Error states** and edge cases (invalid input, network errors, empty states)
- **Form submissions** and validation (required fields, format validation, success/error feedback)
- **Navigation and routing** (links work, back button, deep links, 404 handling)
- **Authentication flows** if applicable (login, logout, session expiry, protected routes)

List the flows before executing:
```
FORGE /browse — Flows identified: [N]

1. [Flow name] — [brief description]
2. [Flow name] — [brief description]
...

Executing...
```

## Step 4: Write Test File

Create `.forge/browse/` and `.forge/browse/screenshots/` if they don't exist.

Create `.forge/browse/flows.spec.js` with tests for each identified flow:

```javascript
const { test, expect } = require('@playwright/test');

test.describe('FORGE Browser Flows', () => {
  test('[flow name]', async ({ page }) => {
    await page.goto('[url]');
    // Navigate through the flow
    // Assert expected outcomes at each step
  });

  test('[flow name] — error case', async ({ page }) => {
    await page.goto('[url]');
    // Trigger the error condition
    // Assert error is displayed correctly
  });
});
```

Guidelines for test generation:
- Each flow gets its own `test()` block
- Use descriptive test names that explain the user journey
- Assert on visible text and elements, not implementation details
- Use `page.waitForSelector()` or `expect(locator).toBeVisible()` for dynamic content
- Set reasonable timeouts — don't wait forever for elements that won't appear
- Use `test.describe()` to group related flows

## Step 5: Execute Tests

Run the test file:
```bash
npx playwright test .forge/browse/ --reporter=list
```

On failure, re-run with screenshot capture:
```bash
npx playwright test .forge/browse/ --reporter=list --screenshot=on
```

Screenshots save to `.forge/browse/screenshots/`.

For each failure, record:
- What step in the flow failed
- What was expected vs. what happened
- The screenshot path for visual evidence

If the dev server is not running, attempt to start it:
```bash
# Detect start command from package.json scripts
# Start in background, wait for the port to be available
```

If the server won't start, report FAIL immediately — do not skip browser testing.

## Step 6: Write Browse Report

Write the report to `.forge/browse/report.md`:

```markdown
# FORGE Browse Report

## Date: [YYYY-MM-DD HH:MM]
## URL: [base URL tested]
## Mode: [verify-delegated | standalone]

## Flows Tested

### [Flow 1 name]
- Status: PASS | FAIL
- Steps: [what was done]
- [If FAIL] Expected: [expected]
- [If FAIL] Actual: [actual]
- [If FAIL] Screenshot: .forge/browse/screenshots/[name].png

### [Flow 2 name]
- Status: PASS | FAIL
- Steps: [what was done]
- [If FAIL] Expected: [expected]
- [If FAIL] Actual: [actual]
- [If FAIL] Screenshot: .forge/browse/screenshots/[name].png

## Summary
- Flows tested: [N]
- Passed: [N]
- Failed: [N]
- Screenshots: [count, if any]
```

## Step 7: Report

```
FORGE /browse — [PASS | FAIL]

URL: [base URL]
Flows: [passed]/[total]
Report: .forge/browse/report.md
[If failures]: Screenshots: .forge/browse/screenshots/

[If called by /verify]: Results returned to /verify for final report.
[If standalone]: Review the report for details.
```

## Rules

- Playwright is the ONLY browser automation tool — no MCP browser tools, no curl substitution for web flows
- Screenshots are mandatory on every failure
- Never modify the application — browser testing is observation only
- If the server isn't running, attempt to start it. If it won't start, report FAIL — don't skip browser testing
- Test file goes in `.forge/browse/`, not in the project's test directory
- Support both `npx` and `bunx` — detect available runtime
- When called by `/verify`, return structured results, not just pass/fail
- **Evidence before claims** — never claim PASS without showing actual test output
- Do not guess at URLs or ports — detect from project config or ask the user
