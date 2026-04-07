# FORGE Recipes

Step-by-step workflows for common development scenarios. Each recipe shows the exact FORGE commands and what happens at each step.

> **First time?** See the [Getting Started Guide](getting-started.md) for install and setup.

---

## 1. New Greenfield Project

**When:** Starting a project from scratch — new app, new service, new system.

**Commands:**

1. `/think Build a REST API for task management with user auth` — classifies as **epic**, plans Agent Teams
2. `/architect` — spawns Product, Architecture, and Security agents; locks architecture doc
3. `/build` — TDD implementation with subagents, each verified against the architecture
4. `/review` → `/verify` → `/ship` — standard quality gates
5. `/retro` → `/evolve` — capture learnings for next time

**Shortcut:** `/autopilot Build a REST API for task management with user auth` runs the entire pipeline autonomously with self-healing loops.

**Tip:** Use `/brainstorm` before `/think` if you're still exploring what to build.

---

## 2. Adding a Feature

**When:** Adding a new capability to an existing codebase — new endpoint, component, integration.

**Commands:**

1. `/worktree feature/user-notifications` — isolate work in a git worktree
2. `/think Add email notifications when tasks are assigned` — classifies as **feature**, routes to `/architect`
3. `/architect` — checks memory for past decisions, analyzes codebase, locks architecture
4. `/build` — writes failing tests first, implements until they pass, checks reusability
5. `/review` — spec compliance, quality, security, DRY check
6. `/verify` — runs project-appropriate tests (web/API/pipeline)
7. `/ship` — security audit + PR creation
8. `/finish` — merge branch and clean up worktree

**Tip:** `/memory recall notifications` checks if you've made notification-related decisions in past projects.

For a detailed walkthrough of this flow, see the [Getting Started guide](getting-started.md#full-workflow-example).

---

## 3. Fixing a Bug

**When:** Something is broken — test failure, user-reported bug, unexpected behavior.

**Commands:**

1. `/debug Users report 500 error on /api/tasks when filtering by date` — collects evidence, forms ranked hypotheses, tests systematically
2. `/build` — implements the minimal fix with tests (if non-trivial)
3. `/review` → `/verify` → `/ship` — standard gates

**Alternative:** `/think Fix the date filter 500 error` auto-detects bug signals and routes to `/debug`.

**Tip:** Paste the error message or stack trace directly — `/debug` uses it as evidence.

---

## 4. Enhancement / Refactoring

**When:** Improving existing code — better performance, cleaner structure, updated patterns.

**Commands:**

1. `/think Refactor the task service to use the repository pattern` — classifies as **tiny** (1-2 files) or **feature** (broader change)
2. `/build` — TDD ensures refactoring doesn't break existing behavior
3. `/review` — specifically checks DRY compliance and reusability
4. `/verify` → `/ship` — standard gates

**Tip:** `/brainstorm --grill` stress-tests your refactoring plan before you commit to it. Useful for large refactors where the approach matters.

---

## 5. Production Incident

**When:** Something is broken in production and needs urgent attention.

**Commands:**

1. `/debug Production: connection pool exhaustion on task-service, 504s on all endpoints` — root-cause-first investigation with evidence collection
2. `/build` — minimal fix, tested
3. `/review` → `/verify` → `/ship` — fast-track through gates
4. `/deploy production` — deploy the fix immediately
5. `/retro` — capture what happened for future prevention

**Tip:** `/debug` produces a report at `.forge/debug/` with the full investigation trail — useful for post-incident reviews.

---

## 6. Performance Issue

**When:** Something is slow — endpoint latency, build time, query performance.

**Commands:**

1. `/benchmark GET /api/tasks?limit=1000` — measures baseline performance
2. Fix the bottleneck (use `/think` or `/build` as needed)
3. `/benchmark GET /api/tasks?limit=1000` — compare against baseline
4. `/review` → `/verify` → `/ship` — standard gates if code changed

**Tip:** `/benchmark` saves baselines for future regression detection. Run it periodically on critical paths.

---

## 7. Reviewing a PR

**When:** You need to review code — your own or a teammate's.

**Commands:**

- `/review` — automated review against architecture doc, checks spec compliance, quality, security, DRY, path coverage
- `/review request` — prepare a structured review request for others
- `/review response [feedback]` — process incoming review feedback; verifies suggestions against the actual codebase before implementing

**Tip:** `/review response` has anti-sycophancy guardrails — it pushes back on incorrect suggestions rather than blindly applying them.

---

## 8. Deploying to Production

**When:** Code is merged and ready to ship.

### Standard Deploy

1. `/ship` — runs OWASP + STRIDE security audit, creates PR
2. `/deploy production` — deploys and verifies health

### Gradual Rollout

1. `/ship` — security audit + PR
2. `/canary 10` — deploy to 10% of traffic with monitoring
3. Promote to full rollout or rollback based on metrics

**Post-deploy:**

- `/document-release` — syncs documentation with the shipped changes
- `/retro` → `/evolve` — capture learnings, improve FORGE itself

**Tip:** `/ship` blocks if `/review` or `/verify` reports are stale (wrong commit SHA). Re-run them if needed.

---

## Quick Reference

| Scenario | Start with | Full chain |
|----------|-----------|------------|
| New project | `/think --auto` or `/autopilot` | think → architect → build → review → verify → ship |
| New feature | `/think` | think → architect → build → review → verify → ship → finish |
| Bug fix | `/debug` | debug → build → review → verify → ship |
| Enhancement | `/think` | think → build → review → verify → ship |
| Incident | `/debug` | debug → build → ship → deploy |
| Performance | `/benchmark` | benchmark → fix → benchmark → ship |
| Code review | `/review` | review (or review request / review response) |
| Deploy | `/ship` | ship → deploy (or ship → canary) |
