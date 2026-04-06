---
name: build
description: "TDD-enforced implementation. Reads the locked architecture doc from /architect, spawns subagents in isolated worktrees, enforces failing tests before implementation, runs 2-stage review (spec compliance + code quality), and routes to optimal models. Use when ready to implement — triggered by 'build it', 'start coding', 'implement this', 'write the code'."
argument-hint: "[architecture doc path or 'continue']"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /build — TDD-Enforced Implementation

You execute the locked architecture doc produced by `/architect`. No freestyling — the architecture is the contract.

## Step 1: Load Architecture Doc

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
Recommendation: Route simple tasks to Haiku, complex to Opus

Proceed? (y/n, or 'route' to see per-task model suggestions)
```

Wait for user confirmation before proceeding.

## Step 3: Plan Task Order

Break the architecture into ordered implementation tasks. Each task is one logical unit (a function, endpoint, component, or test suite).

Order by dependency — implement foundations first:
1. Data models / types
2. Core logic / business rules
3. API layer / routes
4. Integration points
5. Edge case handling

Present the plan:
```
FORGE /build — Implementation plan

[N] tasks from architecture doc:
  1. [task] — [model: haiku|sonnet|opus] — [estimated complexity]
  2. ...

Order respects dependencies. Start? (y/n, or adjust)
```

### Model Routing

Assign models based on task complexity — use the fastest capable model for simple work:
- **Fast model** (e.g., Haiku): Config files, boilerplate, simple CRUD, type definitions, straightforward tests
- **Balanced model** (e.g., Sonnet): Standard features, API endpoints, moderate logic, integration tests
- **Most capable model** (e.g., Opus): Complex algorithms, security-critical code, architectural decisions, edge cases

Model routing is advisory, not mandatory. If the preferred model is unavailable, use whatever model IS available and log the fallback. Never skip a task because a preferred model isn't available.

## Step 4: TDD Loop (Per Task)

For each task, execute this strict loop:

### 4a. Write Failing Tests FIRST

Based on the architecture doc's test strategy:
- Write test file(s) for this task
- Tests must cover: happy path, error cases, edge cases from the architecture doc
- Tests must be runnable with the project's test framework

Detect the project test runner using this priority order:
1. If .forge/config.json has "test_command" → use that
2. Read package.json "scripts.test" if it exists → use that exact command
3. If bun.lockb exists → bun test
4. If vitest.config.* exists → npx vitest run
5. If jest.config.* exists or jest is in package.json dependencies → npx jest
6. If pytest.ini exists or pyproject.toml has [tool.pytest] → pytest
7. If go.mod exists → go test ./...
8. If Cargo.toml exists → cargo test
9. If none detected → ask the user for the test command. Do not guess.
For monorepos: prefer the runner closest to the files being modified.

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

For each independent task group, spawn an Agent:
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

**Context Pruning**: Each subagent receives ONLY:
- Its specific task description from the architecture doc
- The relevant API contracts and test strategy for that task
- Project conventions (test runner, framework, file patterns)
- Dependencies it needs to install

Do NOT include: full session history, other tasks' details, memory bank contents, or the complete architecture doc. Less context = faster, more focused execution.

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

Ready for /verify.
```

Update the run manifest:
```bash
scripts/manifest.sh phase "$(cat .forge/runs/latest)" build
scripts/manifest.sh status "$(cat .forge/runs/latest)" completed
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
After the build completes (or fails), log the invocation:
```bash
bash scripts/telemetry.sh build [completed|error]
```

### Error Handling
If any step fails unexpectedly: (1) state what failed and show the error output, (2) state what has been completed so far, (3) state what remains, (4) ask the user: retry this step, skip it, or abort. Never silently continue past a failed step.
