---
name: build
description: "TDD-enforced implementation. Reads the locked architecture doc from /architect, spawns subagents in isolated worktrees, enforces failing tests before implementation, runs 2-stage review (spec compliance + code quality), and routes to optimal models. Use when ready to implement — triggered by 'build it', 'start coding', 'implement this', 'write the code'."
argument-hint: "[architecture doc path or 'continue']"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /build — TDD-Enforced Implementation

Tests MUST fail before implementation — no exceptions. The architecture doc is law — do not deviate without user approval. You execute the locked architecture doc produced by `/architect`. No freestyling.

## Step 0: Execution Mode Detection

- **Inline mode** (default): Main session. Required for 3+ independent tasks (subagents cannot spawn subagents).
- **Subagent mode**: Runs as subagent for <3 tasks. Load arch doc from `.forge/architecture/*.md`, use `$ARGUMENTS` as context, execute all tasks sequentially in Step 4, skip Step 5.

## Step 1: Load Architecture Doc

If `.forge/.gitignore` does not exist, create it with `*`. Find the arch doc:
```bash
ls .forge/architecture/*.md
```
Use `$ARGUMENTS` path if specified, otherwise most recently modified doc. If none exists: tiny tasks (per `/think`) proceed without one; otherwise log `compliance-log.sh build missing-arch-doc` and **STOP**: `No architecture doc found. Run /architect first.`

Parse: **Components**, **API contracts**, **Test strategy**, **Edge cases**, **Dependencies**.

## Step 2: Token Budget Check

Estimate: `[task count] x ~8,000 tokens/task`. If projected total exceeds `token_budget` (`.forge/config.json`, default: 40,000), warn and wait for confirmation.

## Step 3: Plan Task Order

Break architecture into ordered tasks. **Prefer vertical slices** — each task delivers one behavior end-to-end (data model + logic + route + tests), not horizontal layers. Order: (1) vertical slices by behavior, (2) shared foundations, (3) edge cases last. **Anti-pattern:** "all models -> all logic -> all routes -> all tests."

Present plan: `FORGE /build — Implementation plan` with `[N] tasks`, each showing `[task] — [model: opus] — sections: [relevant arch doc sections]`. All tasks use Opus by default. If unavailable, use whatever IS available and log fallback — never skip a task.

## Step 3.5: Context Pruning (For Multi-Task Builds)

When 3+ independent tasks identified, build minimal context bundles (skip if fewer):
```bash
bash scripts/context-prune.sh clean
bash scripts/context-prune.sh extract .forge/architecture/[task].md .forge/context/task-N.md [section-ids...]
bash scripts/context-prune.sh conventions >> .forge/context/task-N.md
bash scripts/context-prune.sh estimate .forge/context/task-N.md  # warns if >32000 tokens
```
Bundles persist at `.forge/context/task-{n}.md`; cleaned at next build start. If pruning fails, extract sections inline in Step 5.

## Step 4: TDD Loop (Per Task)

### 4a. Write Failing Tests FIRST

Write tests covering happy path, error cases, edge cases per arch doc test strategy. **Mock only at system boundaries** (external APIs, databases, time, filesystem) — never mock internal collaborators; restructure code to accept dependencies instead.

Detect the project test runner:
```bash
TEST_CMD=$(bash scripts/quality-gate.sh detect-runner)
```
Config override via `.forge/config.json` `test_command`. If `unknown`, ask user. Monorepos: prefer runner closest to modified files.

**Path Coverage Protocol** — enumerate all condition paths before writing tests:
```bash
bash scripts/quality-gate.sh path-map . [target-source-files]
```
Write exactly **one test case** per path: `test_[function]_[path_description]`.

For existing code, run change impact analysis first:
```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
bash scripts/quality-gate.sh path-diff . ${DEFAULT_BRANCH}
```
Actions: `ADD_TEST` -> new test, `MODIFY_TEST` -> update existing (no duplicates), `REMOVE_TEST` -> delete orphaned, `NO_ACTION` -> skip.

Run tests. **Tests MUST fail.** If they pass: log `tdd-violation` (major) — either feature exists (skip task) or tests aren't asserting correctly (fix tests).

### 4a.5 Reusability Search

```bash
bash scripts/quality-gate.sh reusability-search . [function-names-from-arch-doc]
```
Reuse existing code satisfying the architecture contract. Log reused vs. written fresh.

### 4b. Implement

Write minimum code to make tests pass. Follow architecture doc exactly — no gold-plating.

### 4c. Run Tests Again

If tests fail, fix implementation (not tests) until green.

### 4c.1 Quick Refactor

Tests green: **60-second pass** — extract duplication, simplify complex conditionals. If refactor breaks tests, revert. Larger issues caught by `/review`.

### 4c.5 Coverage Gate

```bash
bash scripts/quality-gate.sh coverage --threshold $(jq -r '.coverage_threshold // ""' .forge/config.json 2>/dev/null)
```
Below threshold = test failure — add tests for uncovered paths. Show actual coverage output (evidence-before-claims).

### 4d. 2-Stage Review

**Stage 1 — Spec Compliance**: API contracts match (params, types, returns), all edge cases handled, component boundaries respected, dependencies as specified. Fix before proceeding.

**Stage 2 — Code Quality**: No hardcoded secrets (strings assigned to password/secret/api_key vars >8 chars, not env refs; exclude test fixtures), input validation at boundaries, explicit error handling (no empty catch/swallowed errors), no obvious perf issues (N+1, unbounded loops, sync blocking in async), follows project conventions. Fix real problems only — no style opinions.

## Step 5: Subagent Execution (For Multi-Task Builds)

Spawn Agent per task group with `isolation: "worktree"` for 3+ independent tasks. Context: use `.forge/context/task-{n}.md` if available, otherwise extract arch doc sections inline. Exclude full session history, other tasks, memory bank, complete arch doc.

Subagent rules: (1) failing tests first, (2) minimum code, (3) run tests, (4) review spec + quality, (5) no files outside scope. Report: tests written/passing, files created/modified.

**Checkpoint after each (BLOCK on failure):** Verify output against arch doc. **PASS** -> next. **FAIL** -> stop and fix. After all complete: merge worktrees, run full suite, fix conflicts.

**Failure:** (1) Retry once with pruned context, (2) execute inline, (3) mark BLOCKED, (4) continue independent tasks, (5) report blocked and ask user. Never silently skip.

## Step 6: Final Verification

Both stages MUST pass — passing tests alone is not sufficient.

**Stage 1 — Architecture Compliance (BLOCK merge if fails):** API contracts exact match (params, types, returns, errors), no cross-boundary imports, end-to-end data flow matches arch doc. Fix before Stage 2.

**Stage 2 — Test Suite (BLOCK merge if fails):** Run full test suite. Fix failures before proceeding.

## Step 6.5: Write Build Report

Write structured report to `.forge/build/${FEATURE_NAME}.md` (resolve name via `bash scripts/manifest.sh resolve-feature-name`):
- `commit_sha`, `tree_hash` — from `git rev-parse HEAD` / `HEAD^{tree}`
- `Date`, `Classification` (tiny|feature|epic), `Architecture` (path or "N/A")
- `Files Modified` — path + created/modified
- `Test Results` — framework, passed count, coverage
- `Tasks Completed` — task name, model, PASS/FAIL
- `Architecture Deviations` — none or list with approval rationale
- `User Decisions` — decisions not in arch doc

Update manifest if `.forge/runs/latest` exists:
```bash
bash scripts/manifest.sh phase "$(cat .forge/runs/latest)" build
bash scripts/manifest.sh status "$(cat .forge/runs/latest)" completed
bash scripts/manifest.sh artifact "$(cat .forge/runs/latest)" build ".forge/build/${FEATURE_NAME}.md"
```

**What's Next:** See `skills/shared/workflow-routing.md`. Recommended: `/review`.

## Rules, Compliance & Error Handling

- Tests MUST fail before implementation — no exceptions
- Architecture doc is law — no deviation without user approval
- Never skip the 2-stage review
- Architecture gap discovered? **STOP** and ask — don't improvise
- Subagents work in isolated worktrees — never modify shared state directly
- Report progress after each task, not just at end
- **Evidence before claims** — see `skills/shared/rules.md`
- Error handling: follow `skills/shared/rules.md` default protocol
- **Compliance & telemetry**: follow `skills/shared/compliance-telemetry.md`. Log phase-transition telemetry via `scripts/telemetry.sh` and compliance via `scripts/compliance-log.sh` per shared protocol. Skill-specific violations:
  - `missing-arch-doc` (major) — build without arch doc for non-tiny task
  - `tdd-violation` (major) — tests passed before implementation
  - `arch-deviation-unapproved` (major) — deviated without approval
  - `review-skipped` (major) — 2-stage review skipped
  - `secrets-committed` (critical) — secrets/credentials/API keys in code
  - `gap-improvised` (major) — arch gap improvised instead of asking
  - `shared-state-modified` (major) — subagent modified shared state
