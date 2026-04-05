---
name: build
description: "TDD-enforced implementation. Reads the locked architecture doc from /architect, spawns subagents in isolated worktrees, enforces failing tests before implementation, runs 2-stage review (spec compliance + code quality), and routes to optimal models."
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

If projected total > 40,000 tokens:
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

Assign models based on task complexity:
- **Haiku**: Config files, boilerplate, simple CRUD, type definitions, straightforward tests
- **Sonnet**: Standard features, API endpoints, moderate logic, integration tests
- **Opus**: Complex algorithms, security-critical code, architectural decisions, edge case handling

## Step 4: TDD Loop (Per Task)

For each task, execute this strict loop:

### 4a. Write Failing Tests FIRST

Based on the architecture doc's test strategy:
- Write test file(s) for this task
- Tests must cover: happy path, error cases, edge cases from the architecture doc
- Tests must be runnable with the project's test framework

Run the tests:
```bash
# Detect test runner
# Node: npm test / bun test / vitest / jest
# Python: pytest
# Go: go test ./...
# Rust: cargo test
```

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
- [ ] API contracts match exactly (types, inputs, outputs, errors)
- [ ] All edge cases from architecture doc are handled
- [ ] Component boundaries respected (no logic leaking across boundaries)
- [ ] Dependencies used as specified

If any check fails, fix before proceeding.

**Stage 2 — Code Quality**

- [ ] No hardcoded secrets, credentials, or API keys
- [ ] Input validation at system boundaries
- [ ] Error handling is explicit, not swallowed
- [ ] No obvious performance issues (N+1 queries, unbounded loops)
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

After all subagents complete:
- Merge worktree changes
- Run the full test suite to catch integration issues
- Fix any conflicts or integration failures

## Step 6: Final Verification

After all tasks complete:

```bash
# Run full test suite
[project test command]
```

```
FORGE /build — Complete

Tasks: [completed]/[total]
Tests: [total passing] / [total written]
Files created: [list]
Files modified: [list]

All tests passing. Ready for /verify.
```

Update the run manifest:
```bash
scripts/manifest.sh phase "$(cat .forge/runs/latest)" build
scripts/manifest.sh status "$(cat .forge/runs/latest)" completed
```

If any tests fail, fix them before declaring complete.

## Rules

- The architecture doc is law — do not deviate without user approval
- Tests MUST fail before implementation — no exceptions
- Never skip the 2-stage review
- Never commit secrets, credentials, or API keys
- If a task reveals an architecture gap, stop and ask the user — don't improvise
- Subagents work in isolated worktrees — never modify shared state directly
- Report progress after each task, not just at the end
- **Evidence before claims** — never claim "tests passing" without showing the actual test output. Every success claim must cite the command run and its output.
