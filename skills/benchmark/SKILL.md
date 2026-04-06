---
name: benchmark
description: "Performance benchmarking. Runs performance tests, compares against baselines, identifies regressions, and produces a benchmark report. Use before /ship for performance-critical changes. Use before shipping perf-critical changes — triggered by 'benchmark this', 'check performance', 'run perf tests', 'is this fast enough', 'performance regression'."
argument-hint: "[optional: specific test or component to benchmark]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /benchmark — Performance Benchmarking

You measure performance, compare against baselines, and flag regressions. You produce a benchmark report that helps the team decide whether performance is acceptable before shipping.

## Step 1: Identify What to Benchmark

From `$ARGUMENTS` or auto-detect by scanning the codebase:

### API Endpoints
Signals: route handlers, HTTP framework (Express, Fastify, Hono, Flask, Go net/http, etc.).
Measure: response time (p50, p95, p99), throughput (requests/sec), error rate under load.

### Database Queries
Signals: ORM usage, raw SQL files, migration files, query builders.
Measure: execution time, row count, query plan efficiency.

### Algorithms / Business Logic
Signals: compute-heavy functions, data processing, sorting, searching, transformation.
Measure: runtime complexity (wall clock across input sizes), memory usage, allocation count.

### Build / Bundle
Signals: `package.json` with build script, bundler config (webpack, vite, esbuild, turbopack).
Measure: build time, bundle size (total and per-chunk), tree-shaking effectiveness.

### Page Load
Signals: web framework with SSR/CSR, HTML entry points, static assets.
Measure: Lighthouse score, core web vitals (LCP, FID, CLS), time to interactive.

Present detection:
```
FORGE /benchmark — Targets identified

Benchmark targets:
- [target 1]: [metric type]
- [target 2]: [metric type]

Proceed? (y/n, or specify targets manually)
```

## Step 2: Check for Existing Baselines

Look for `.forge/benchmark/baseline.json`. If it exists, this run will compare against it.

```bash
# Check for baseline
cat .forge/benchmark/baseline.json 2>/dev/null
```

If no baseline exists, inform the user that this run will establish the initial baseline:
```
FORGE /benchmark — No baseline found

This run will establish the initial baseline.
Future runs will compare against these results.
```

## Step 3: Run Benchmarks

Execute appropriate benchmarking tools. Always run a minimum of 3 iterations for timing-based benchmarks to reduce noise.

### HTTP Load Testing
```bash
# Prefer wrk, fall back to ab or autocannon
wrk -t4 -c100 -d10s http://localhost:PORT/endpoint
# or
ab -n 1000 -c 50 http://localhost:PORT/endpoint
# or
npx autocannon -c 100 -d 10 http://localhost:PORT/endpoint
```

### Code Benchmarks
```bash
# Go
go test -bench=. -benchmem -count=3 ./...

# Rust
cargo bench

# Node.js
node --expose-gc benchmark.js
# or use the project's existing bench script
npm run bench
```

### Bundle Size
```bash
# Measure build output
npm run build
# Measure output directory size and individual chunks
du -sh dist/
find dist/ -name "*.js" -exec ls -lh {} \;
```

### Page Performance
Use Playwright with performance timing APIs, or Lighthouse CLI if available:
```bash
npx lighthouse http://localhost:PORT --output=json --quiet
```

Collect raw results for every target. Record each iteration separately so variance can be calculated.

## Step 4: Compare Against Baseline

If a baseline exists, compare current results against it.

```
FORGE /benchmark — Results

Metric              Baseline    Current     Change    Status
────────           ─────────   ────────    ──────    ──────
API /users (p95)   45ms        52ms        +15%      REGRESSION
API /auth (p95)    12ms        11ms        -8%       OK
Bundle size        142kb       145kb       +2%       OK
Build time         8.2s        8.5s        +3%       OK
DB query (avg)     3.2ms       3.1ms       -3%       OK
```

### Regression Thresholds

Apply these default thresholds (user can override):

| Metric | Warning | Regression |
|--------|---------|------------|
| Response time (p95) | > 10% increase | > 20% increase |
| Throughput | > 10% decrease | > 20% decrease |
| Bundle size | > 5% increase | > 10% increase |
| Build time | > 15% increase | > 30% increase |
| Memory usage | > 15% increase | > 25% increase |
| Lighthouse score | > 5 point drop | > 10 point drop |

Mark each metric clearly: `OK`, `WARNING`, or `REGRESSION`.

## Step 5: Write Report

Create `.forge/benchmark/` if it doesn't exist.

Save the full report to `.forge/benchmark/report.md`:

```markdown
# FORGE Benchmark Report

## Status: [PASS | REGRESSION]
## Date: [timestamp]

## Summary
- Targets benchmarked: [count]
- Passing: [count]
- Warnings: [count]
- Regressions: [count]

## Results

### [Target name]
- Metric: [what was measured]
- Baseline: [value] | Current: [value] | Change: [+/-X%]
- Status: OK | WARNING | REGRESSION
- Raw data: [iteration 1, iteration 2, iteration 3]
- Variance: [standard deviation or range]

## Regressions (if any)

### [Regression 1]
- Target: [name]
- Metric: [what regressed]
- Baseline: [value] → Current: [value] (+X%)
- Threshold: [what the limit is]
- Possible causes: [brief analysis]
- Recommendation: [optimize / acceptable / investigate]

## Environment
- OS: [detected]
- Runtime: [language version]
- Hardware: [CPU/memory if available]
```

## Step 6: Update Baseline

Use the same `.forge/benchmark/` directory for any new baseline file.

If the user approves, write current results to `.forge/benchmark/baseline.json`:

```
FORGE /benchmark — Save as new baseline?

This will replace the current baseline with today's results.
Future runs will compare against these numbers.

Save baseline? (y/n)
```

Only write the baseline file if the user explicitly confirms.

## Step 7: Report

```
FORGE /benchmark — [PASS | REGRESSION]

Targets: [benchmarked count]
Regressions: [count]
Warnings: [count]
Report: .forge/benchmark/report.md

[If PASS]: No regressions detected. Ready for /ship.
[If REGRESSION]:
  - [regression 1 summary]
  - [regression 2 summary]
  Regressions are warnings — review and decide whether to proceed.
```

## Rules

- Never modify application code during benchmarking
- Regressions are warnings, not blockers — user decides if they are acceptable
- Always compare against baseline when one exists
- Run benchmarks multiple times to reduce noise (3 runs minimum for timing)
- Save the baseline only when user explicitly approves
- Record the environment (OS, runtime version) so results are reproducible
- If a benchmarking tool is not installed, suggest installation but do not auto-install
- Do not run destructive load tests against production — always target local or staging
- Report raw numbers and variance, not just averages — outliers matter
