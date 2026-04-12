---
name: browse
description: "Dedicated browser automation skill using Playwright. Executes browser flows, captures screenshots, and reports results. Used by /verify for web domain QA, and available standalone for browser-based tasks. Use for browser testing — triggered by 'test in browser', 'run Playwright', 'check the UI', 'browser automation', 'test the page'."
argument-hint: "[url or flow description]"
allowed-tools: Read Grep Glob Write Edit Bash
---

# /browse — Browser Automation (Playwright Only)

Execute browser-based testing flows using Playwright, standalone or delegated by `/verify`.

## Step 1: Determine Mode

From `$ARGUMENTS`, determine what to test:
- **URL** — navigate and verify load + key elements
- **Flow description** — parse user journey into steps
- **Test file path** — execute existing spec
- **Called by /verify** — receives structured flow spec

If no arguments, ask the user for a URL, flow, or test file path.

## Step 2: Ensure Playwright

```bash
npx playwright --version 2>/dev/null || bunx playwright --version 2>/dev/null || echo "NOT_INSTALLED"
```

If missing: `npm install --save-dev @playwright/test && npx playwright install chromium`.
If install fails: report `FORGE /browse — BLOCKED` with error and stop. Never fall back to curl, wget, or MCP browser tools.

## Step 3: Determine Browser Flows

Identify flows from architecture doc, user input, or /verify delegation:
- **Happy path** — signup, login, core features
- **Error states** — invalid input, network errors, empty states
- **Forms** — required fields, validation
- **Navigation** — links, back button, deep links, 404s
- **Auth** — login, logout, session expiry (if applicable)

List before executing: `FORGE /browse — Flows identified: [N]` with numbered list.

## Step 4: Write Test File

Create `.forge/browse/` and `.forge/browse/screenshots/` if needed. Write `.forge/browse/flows.spec.js`:

```javascript
const { test, expect } = require('@playwright/test');
test.describe('FORGE Browser Flows', () => {
  test('[flow name]', async ({ page }) => {
    await page.goto('[url]');
    // Navigate flow, assert expected outcomes
  });
});
```

Each flow gets its own `test()` block. Assert on visible text/elements, not implementation details. Use `page.waitForSelector()` or `expect(locator).toBeVisible()` for dynamic content.

## Step 5: Execute Tests

```bash
npx playwright test .forge/browse/ --reporter=list
```

On failure, re-run with `--screenshot=on` (saves to `.forge/browse/screenshots/`). Record: which step failed, expected vs actual, screenshot path.

### URL Resolution

Before testing, determine run command and URL from architecture doc, config files, README, or scripts. If unclear, ask — never skip.
- **Server needed**: start in background, detect port, poll until reachable (30s timeout), kill on completion. If won't start, report FAIL with stderr.
- **No server**: open entry point directly — simpler to test, not nothing to test.

## Step 6: Write Browse Report

```bash
mkdir -p .forge/browse .forge/browse/screenshots
```

Write `.forge/browse/report.md` with required sections:
- **Status:** PASS or FAIL
- **Flows Tested** — per-flow: status, steps taken, expected/actual on failure, screenshot path
- **## Summary** — Date, URL, Mode (verify-delegated | standalone), flows passed/failed, screenshot count

## Step 7: Report

```
FORGE /browse — [PASS | FAIL]

URL: [base URL]
Flows: [passed]/[total]
Report: .forge/browse/report.md
[If failures]: Screenshots: .forge/browse/screenshots/
[If called by /verify]: Results returned to /verify for final report.
```

## Rules, Compliance & Error Handling

- **Playwright only** — no MCP browser tools, no curl for web flows
- Screenshots mandatory on every failure; never modify the application (observation only)
- Test files go in `.forge/browse/`, not the project's test directory
- Support both `npx` and `bunx`; detect from project config — never guess URLs or ports
- When called by `/verify`, return structured results, not just pass/fail

Follow `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh`:
- `wrong-browser-tool` (major) — non-Playwright tool used
- `code-modified` (critical) — app code changed during observation-only testing
- `missing-screenshot` (major) — failure without screenshot
- `testing-skipped` (major) — testing skipped instead of reporting FAIL

See `skills/shared/rules.md` for evidence-before-claims.

## What's Next

See `skills/shared/workflow-routing.md`. Browse is a support skill — results returned to `/verify` when delegated.
