---
name: build
description: "TDD-enforced implementation. Reads the locked architecture doc from /architect, spawns subagents in isolated worktrees, enforces failing tests before implementation, runs 2-stage review (spec compliance + code quality), and routes to optimal models. Use when ready to implement — triggered by 'build it', 'start coding', 'implement this', 'write the code'."
argument-hint: "[architecture doc path or 'continue']"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /build — TDD-Enforced Implementation

You execute the locked architecture doc produced by `/architect`. No freestyling — the architecture is the contract.

## Step 0: Execution Mode Detection

`/build` supports two execution modes based on task count:

- **Inline mode** (default): Runs in the main session. Required when spawning worktree subagents for 3+ independent tasks (subagents cannot spawn other subagents).
- **Subagent mode**: Can run as a subagent when there are fewer than 3 tasks (no nesting needed). The orchestrator decides based on the architecture doc's task count.

If running as a subagent:
- Load the architecture doc from `.forge/architecture/*.md`
- You have no prior conversation history — use the architecture doc and `$ARGUMENTS` as your full context
- You cannot spawn worktree subagents — execute all tasks sequentially in Step 4 (TDD Loop)
- Skip Step 5 (Subagent Execution) entirely

If running inline:
- Proceed normally through all steps

## Step 1: Load Architecture Doc

If `.forge/.gitignore` does not exist, create it with `*` to prevent artifact commits.

Find and read the architecture doc:

```bash
ls .forge/architecture/*.md
```

If `$ARGUMENTS` specifies a path, use that. Otherwise use the most recently modified doc in `.forge/architecture/`.

If no architecture doc exists:
- If the task was classified as **tiny** by `/think`, proceed without one — use the task description directly
- Otherwise, stop and tell the user: `No architecture doc found. Run /architect first.`

Parse from the doc:
- **Components** — what files to create/modify
- **API contracts** — the exact interfaces to implement
- **Test strategy** — what tests to write
- **Edge cases** — each must be handled
- **Dependencies** — what to install

## Step 2: Token Budget Check

Before spawning subagents, estimate the work:

```
Estimated tasks: [count from components list]
Avg tokens per task: ~8,000 (implementation + tests + review)
Projected total: [count × 8,000]
```

If projected total > the configured token_budget (.forge/config.json, default: 40,000):
```
FORGE /build — Token budget warning

Projected: ~[N] tokens across [count] tasks
Recommendation: All tasks use Opus by default. Model routing available for future cost optimization.

Proceed? (y/n, or 'route' to see per-task model suggestions)
```

Wait for user confirmation before proceeding.

## Step 3: Plan Task Order

Break the architecture into ordered implementation tasks. **Prefer vertical slices** — each task should deliver one user-visible behavior end-to-end (data model + logic + route + tests), not a horizontal layer.

Order by dependency within slices:
1. **Vertical slices first** — group by behavior: e.g., "user can create a task" = schema + validation + endpoint + tests, all in one task
2. **Shared foundations** — if multiple slices depend on the same base (e.g., a shared DB connection, auth middleware), implement that foundation first as its own task
3. **Edge cases last** — after core behaviors work end-to-end, add edge case handling per slice

**Anti-pattern:** Do NOT plan as "all models → all logic → all routes → all tests." This delays integration feedback and produces tests disconnected from real behavior. Each slice should be independently verifiable before starting the next.

Present the plan with section identifiers for context pruning:
```
FORGE /build — Implementation plan

[N] tasks from architecture doc:
  1. [task] — [model: opus] — sections: [API Contracts::functionName, Edge Cases::1,3, Test Strategy::unit]
  2. [task] — [model: ...] — sections: [Component Boundaries::ServiceName, Edge Cases::2,4]
  ...

Order respects dependencies. Start? (y/n, or adjust)
```

The `sections:` field identifies which architecture doc sections are relevant to each task. These are used by context pruning (Step 3.5) to build minimal context bundles for subagents.

### Model Routing

Assign models based on task complexity — use the fastest capable model for simple work:
- **Default model** (Opus): All tasks use Opus for maximum quality
- Model routing to cheaper models is available for future cost optimization

Model routing is advisory, not mandatory. If the preferred model is unavailable, use whatever model IS available and log the fallback. Never skip a task because a preferred model isn't available.

## Step 3.5: Context Pruning (For Multi-Task Builds)

When Step 3 identifies **3 or more independent tasks**, build minimal context bundles for each subagent before starting work. This reduces token waste and ensures consistent context across subagents.

If fewer than 3 tasks, skip this step entirely — use the architecture doc directly.

```bash
# Clean stale context from any previous build
bash scripts/context-prune.sh clean

# For each task, extract its context bundle using the section identifiers from Step 3
bash scripts/context-prune.sh extract .forge/architecture/[task].md .forge/context/task-1.md "API Contracts::createTask" "Edge Cases::1,3" "Test Strategy::unit"
bash scripts/context-prune.sh extract .forge/architecture/[task].md .forge/context/task-2.md "Component Boundaries::ServiceName" "Edge Cases::2,4"

# Append project conventions to each bundle
bash scripts/context-prune.sh conventions >> .forge/context/task-1.md
bash scripts/context-prune.sh conventions >> .forge/context/task-2.md

# Check token estimates (warns if any bundle exceeds 32000 tokens)
bash scripts/context-prune.sh estimate .forge/context/task-1.md
bash scripts/context-prune.sh estimate .forge/context/task-2.md
```

Each bundle follows the context bundle schema and is stored at `.forge/context/task-{n}.md`. Bundles are **not** auto-cleaned after build — they persist for debugging if a build fails. They are cleaned at the start of the **next** build.

If context pruning fails for any reason, fall back to the current approach (extract relevant sections inline when spawning subagents in Step 5).

## Step 4: TDD Loop (Per Task)

For each task, execute this strict loop:

### 4a. Write Failing Tests FIRST

Based on the architecture doc's test strategy:
- Write test file(s) for this task
- Tests must cover: happy path, error cases, edge cases from the architecture doc
- Tests must be runnable with the project's test framework
- **Mock only at system boundaries** — external APIs, databases, time, filesystem. Never mock internal collaborators or your own classes. If a test requires mocking an internal module to work, that's a design signal — consider restructuring the code to accept dependencies instead

Detect the project test runner using the shared detection script:
```bash
TEST_CMD=$(bash scripts/quality-gate.sh detect-runner)
```
This detects 15+ frameworks: Jest, Vitest, Mocha, Cypress, Playwright, pytest, Go test, Cargo test, Maven, Gradle, RSpec, Minitest, PHPUnit, dotnet test, and Bun. Config override via `.forge/config.json` `test_command` takes highest priority.
If the script returns `unknown` → ask the user for the test command. Do not guess.
For monorepos: prefer the runner closest to the files being modified.

**Path Coverage Protocol**

Before writing tests, enumerate all condition paths in the code being tested:
```bash
bash scripts/quality-gate.sh path-map . [target-source-files]
```
For each path in the output, write exactly **one test case**. Rules:
- Every path_id must have exactly one corresponding test — no untested paths, no duplicate coverage
- Name tests to reflect the path: `test_[function]_[path_description]` (e.g., `test_auth_token_missing_returns_401`)
- If modifying existing code, run change impact analysis first:
  ```bash
  DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
  bash scripts/quality-gate.sh path-diff . ${DEFAULT_BRANCH}
  ```
  - `ADD_TEST` paths → write new test cases
  - `MODIFY_TEST` paths → update the existing test (do NOT add a second test for the same path)
  - `REMOVE_TEST` paths → delete the orphaned test
  - `NO_ACTION` paths → leave existing tests untouched

Run the tests.

**Tests MUST fail.** If tests pass before implementation, something is wrong:
- The feature already exists → skip this task
- Tests are not asserting correctly → fix the tests

```
FORGE /build — TDD ✗ [task name]
Tests written: [count]
Status: FAILING (expected)
Proceeding to implementation.
```

### 4a.5 Reusability Search

Before writing implementation code, search for existing functions that may already solve part of the task:
```bash
bash scripts/quality-gate.sh reusability-search . [function-names-from-arch-doc]
```
If candidates are found, review them. Reuse existing code instead of writing new code when the existing implementation satisfies the architecture contract. Log what was reused vs. written fresh.

### 4b. Implement

Write the minimum code to make tests pass. Follow the architecture doc exactly:
- Match the API contracts (types, inputs, outputs, errors)
- Handle every edge case listed
- No extra features, no gold-plating

### 4c. Run Tests Again

```
FORGE /build — TDD ✓ [task name]
Tests: [passed]/[total] passing
```

If tests fail, fix the implementation (not the tests) until they pass.

### 4c.1 Quick Refactor

Now that tests are green, do a brief refactor pass before moving on:
- Extract any duplicated code introduced across this task
- Simplify overly complex conditionals or deeply nested logic
- Verify tests still pass after refactoring — if a refactor breaks tests, revert it

This is a **60-second pass**, not a deep rewrite. If the refactor would take more than a few minutes, note it and move on — `/review` will catch larger structural issues.

### 4c.5 Coverage Gate

If the project has a coverage threshold configured, enforce it:
```bash
bash scripts/quality-gate.sh coverage --threshold $(jq -r '.coverage_threshold // ""' .forge/config.json 2>/dev/null)
```
If coverage is below threshold, treat it like a test failure — fix before proceeding. Show the actual coverage output (evidence-before-claims). Add tests for uncovered paths identified by the coverage report.

### 4d. 2-Stage Review

**Stage 1 — Spec Compliance**

Check implementation against architecture doc:
- [ ] API contracts match: compare function signatures in the architecture doc against the actual implementation. If any parameter name, type, or return type differs → fix before proceeding
- [ ] All edge cases from architecture doc are handled: for each listed edge case, locate the code path that handles it
- [ ] Component boundaries respected: no imports crossing boundaries defined in the architecture doc
- [ ] Dependencies used as specified

If any check fails, fix before proceeding.

**Stage 2 — Code Quality**

- [ ] No hardcoded secrets: search modified files for literal credential values (strings assigned to password/secret/api_key variables that are >8 chars and not env var references). Exclude test fixtures and .env.example
- [ ] Input validation at system boundaries: for each function accepting external input (HTTP handler, CLI parser, file reader), verify the first operation validates or sanitizes the input
- [ ] Error handling is explicit — no empty catch blocks, no swallowed errors
- [ ] No obvious performance issues (N+1 queries, unbounded loops, synchronous blocking in async code)
- [ ] Code follows existing project conventions (naming, structure, patterns)

If issues found, fix them. Do not flag style opinions — only real problems.

## Step 5: Subagent Execution (For Multi-Task Builds)

When there are 3+ independent tasks, use subagents for parallel execution:

For each independent task group, spawn an Agent.

**Context Pruning**: If `.forge/context/task-{n}.md` exists (created in Step 3.5), use it as the subagent's full context. If no bundle exists (pruning was skipped or failed), fall back to extracting the relevant architecture doc sections inline.

When using a context bundle:
```
Prompt: "You are a FORGE build agent. Implement this task in an isolated worktree.

Your full context is below:

[contents of .forge/context/task-{n}.md]

Rules:
1. Write failing tests FIRST — run them, confirm they fail
2. Implement minimum code to pass tests
3. Run tests — all must pass
4. Review: check spec compliance and code quality
5. Do not modify files outside your task scope

Report back: tests written, tests passing, files created/modified."
```

When falling back (no bundle):
```
Prompt: "You are a FORGE build agent. Implement this task in an isolated worktree:

Task: [task description]
Architecture contract: [relevant section from arch doc]
Test strategy: [relevant tests to write]

Rules:
1. Write failing tests FIRST — run them, confirm they fail
2. Implement minimum code to pass tests
3. Run tests — all must pass
4. Review: check spec compliance and code quality
5. Do not modify files outside your task scope

Report back: tests written, tests passing, files created/modified."
```

In both cases, do NOT include: full session history, other tasks' details, memory bank contents, or the complete architecture doc. Less context = faster, more focused execution.

Use `isolation: "worktree"` for each subagent to prevent conflicts.

**Checkpoint after each subagent (before starting the next one):**

When a subagent reports back, pause and do not start the next subagent until this checkpoint passes:

1. Review the subagent's output — read the files it created or modified and its reported test results.
2. Verify against the architecture doc: does the output match the API contracts (types, inputs, outputs, error cases), respect the component boundaries, and implement the data flow as specified?
3. Log the result:
   - **PASS** — output matches the architecture contract and tests pass. Proceed to the next subagent.
   - **FAIL** — output deviates from the contract or tests do not pass. Stop. Fix the issue (inline or by re-running the subagent) before starting any subsequent subagent. Errors must not compound across subagents.

After all subagents complete:
- Merge worktree changes
- Run the full test suite to catch integration issues
- Fix any conflicts or integration failures

### Subagent Failure Handling

If a subagent fails (error, timeout, or produces no usable output):
1. Retry ONCE with the same task and pruned context
2. If retry also fails: execute the task inline (in the main agent, no subagent)
3. If inline execution also fails: mark the task as BLOCKED
4. Continue with remaining independent tasks
5. At the end of /build, report all blocked tasks and ask the user how to proceed

Never silently skip a task because a subagent failed.

## Step 6: Final Verification

After all tasks complete, both stages below must pass before the build is considered done. Passing tests alone is not sufficient — architecture compliance must be verified first.

**Stage 1 — Architecture Compliance (BLOCK merge if this fails)**

Compare the implemented code against the architecture doc:
- **API contracts**: For every function, endpoint, or interface defined in the architecture doc, confirm the actual implementation matches exactly — parameter names, types, return types, and error cases. Any deviation blocks merge.
- **Component boundaries**: Each component owns only what the architecture doc assigns to it. No component reaches into another's scope or imports across defined boundaries.
- **Data flow**: Trace the end-to-end data flow as specified in the architecture doc. Confirm that data enters, transforms, and exits at the points the doc defines.

If Stage 1 fails, fix the non-compliant code before running Stage 2.

**Stage 2 — Test Suite (BLOCK merge if this fails)**

```bash
# Run full test suite
[project test command]
```

If any tests fail, fix them before proceeding.

```
FORGE /build — Complete

Tasks: [completed]/[total]
Architecture compliance: PASS
Tests: [total passing] / [total written]
Files created: [list]
Files modified: [list]

Ready for /review.
```

## Step 6.5: Write Build Report (Handoff Artifact)

After final verification passes, write a structured build report that downstream phases (`/review`, `/verify`, `/ship`) can consume independently — even if running as isolated subagents with no prior conversation context.

```bash
mkdir -p .forge/build
git rev-parse HEAD
git rev-parse HEAD^{tree}
```

Write to `.forge/build/report.md`:

```markdown
# FORGE Build Report

## commit_sha: [output of git rev-parse HEAD]
## tree_hash: [output of git rev-parse HEAD^{tree}]
## Date: [YYYY-MM-DD HH:MM]
## Classification: [tiny | feature | epic]
## Architecture: [path to arch doc or "N/A (tiny task)"]

## Files Modified
- path/to/file.ts (created | modified)
- path/to/file.test.ts (created | modified)

## Test Results
- Framework: [detected test runner]
- Passed: [N]/[N]
- Coverage: [XX% or "not measured"]

## Tasks Completed
1. [Task name] — [model used] — PASS
2. [Task name] — [model used] — PASS

## Architecture Deviations
[None | list of deviations with the user's approval rationale]

## User Decisions
[Decisions made during the build that are NOT captured in the architecture doc.
These include verbal constraints, preference overrides, and runtime choices.
Example: "User chose PostgreSQL over SQLite based on production requirements"
Example: "User approved skipping edge case #3 — deferred to next sprint"]
```

This report is the primary handoff artifact for isolated post-build phases. Include every decision that would otherwise be lost if the conversation context were discarded.

Update the run manifest:
```bash
if [[ -f .forge/runs/latest ]]; then
  bash scripts/manifest.sh phase "$(cat .forge/runs/latest)" build
  bash scripts/manifest.sh status "$(cat .forge/runs/latest)" completed
fi
```

## Rules

- The architecture doc is law — do not deviate without user approval
- Tests MUST fail before implementation — no exceptions
- Never skip the 2-stage review
- Never commit secrets, credentials, or API keys
- If a task reveals an architecture gap, stop and ask the user — don't improvise
- Subagents work in isolated worktrees — never modify shared state directly
- Report progress after each task, not just at the end
- **Evidence before claims** — after running any test command, your response MUST include: (1) the exact command run, (2) the terminal output (last 30 lines minimum), (3) the exit code or pass/fail summary line. Do NOT write "Tests: N/N passing" — show the actual runner output. If a command failed to run or timed out, state that explicitly.

### Telemetry
After the build completes (or fails), log the invocation and phase transition:
```bash
bash scripts/telemetry.sh build [completed|error]
bash scripts/telemetry.sh phase-transition build
```

### Error Handling
If any step fails unexpectedly: (1) state what failed and show the error output, (2) state what has been completed so far, (3) state what remains, (4) ask the user: retry this step, skip it, or abort. Never silently continue past a failed step.
