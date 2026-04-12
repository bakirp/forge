---
name: benchmark
description: "Performance benchmarking. Runs performance tests, compares against baselines, identifies regressions, and produces a benchmark report. Use before /ship for performance-critical changes. Use before shipping perf-critical changes — triggered by 'benchmark this', 'check performance', 'run perf tests', 'is this fast enough', 'performance regression'."
argument-hint: "[optional: specific test or component to benchmark]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /benchmark — Performance Benchmarking

You measure performance, compare against baselines, and flag regressions before shipping. Never modify application code during benchmarking — observation only.

> **Shared protocols apply** — see `skills/shared/rules.md`, `skills/shared/compliance-telemetry.md`, `skills/shared/workflow-routing.md`.

## Step 1: Identify Targets

From `$ARGUMENTS` or auto-detect by scanning the codebase. Confirm targets with user before proceeding.

| Target Type | Signals | Key Metrics |
|-------------|---------|-------------|
| API Endpoints | Route handlers, HTTP frameworks | p50/p95/p99 response time, req/sec, error rate |
| Database Queries | ORM, raw SQL, migrations | Execution time, row count, query plan |
| Algorithms / Logic | Compute-heavy functions, data processing | Wall clock across input sizes, memory, allocations |
| Build / Bundle | Build scripts, bundler configs | Build time, bundle size (total + per-chunk) |
| Page Load | SSR/CSR frameworks, static assets | Lighthouse score, LCP, FID, CLS, TTI |

## Step 2: Check for Existing Baselines

Look for `.forge/benchmark/baseline.json`. If present, this run compares against it; otherwise this run establishes the initial baseline.

## Step 3: Run Benchmarks

Minimum 3 iterations for timing benchmarks to reduce noise. Tools: `wrk`/`ab`/`autocannon` (HTTP), `go test -bench`/`cargo bench`/`npm run bench` (code), `du -sh dist/` (bundle), `lighthouse` CLI or Playwright (page perf). Collect raw results per iteration for variance calculation. If a tool is missing, suggest installation but do not auto-install.

## Step 4: Compare Against Baseline

If a baseline exists, compare every metric and mark each `OK`, `WARNING`, or `REGRESSION`.

| Metric | Warning | Regression |
|--------|---------|------------|
| Response time (p95) | > 10% increase | > 20% increase |
| Throughput | > 10% decrease | > 20% decrease |
| Bundle size | > 5% increase | > 10% increase |
| Build time | > 15% increase | > 30% increase |
| Memory usage | > 15% increase | > 25% increase |
| Lighthouse score | > 5 point drop | > 10 point drop |

## Step 5: Write Report

Save to `.forge/benchmark/report.md`:
- **Status**: PASS or REGRESSION | **Date**: timestamp
- **Summary**: targets benchmarked, passing, warnings, regressions counts
- **Per-target**: metric, baseline vs current, change %, status, raw data per iteration, variance
- **Regressions**: target, metric, baseline -> current, threshold, possible causes, recommendation
- **Environment**: OS, runtime version, hardware info

## Step 6: Update Baseline

Write current results to `.forge/benchmark/baseline.json` only when user explicitly approves.

## Step 7: Final Output

Report status (PASS/REGRESSION), target count, regression count, warnings, and report path. Regressions are warnings, not blockers — user decides acceptability.

## What's Next

- **If PASS** — recommend `/ship`; alternative `/review` if not done.
- **If REGRESSION** — list summaries; recommend `/build` to optimize then re-benchmark.

## Rules & Compliance

Never run destructive load tests against production — local/staging only. Always compare against baseline when one exists. Report raw numbers and variance, not just averages. Record environment for reproducibility.

Compliance keys for `scripts/compliance-log.sh benchmark <key> <severity>`: `code-modified`/`critical` — app code modified during benchmarking; `insufficient-runs`/`minor` — fewer than 3 timing runs; `baseline-saved-unapproved`/`major` — baseline saved without approval.
