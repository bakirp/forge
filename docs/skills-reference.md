# FORGE Skills Reference

Complete reference for all FORGE skills. Each skill is a Markdown file with YAML frontmatter that Claude Code reads and executes.

## Skill Chain

```
/think → /architect → /build → /review → /verify → /ship → /retro → /evolve
                ↕                                      ↕
             /memory                                /memory

Standalone: /debug, /browse, /design, /benchmark
Lifecycle:  /worktree, /finish, /document-release
Guards:     /careful, /freeze
Deploy:     /canary, /deploy
Ideation:   /brainstorm → /architect
```

---

## /think — Adaptive Entry Point

**Phase**: Planning
**Usage**: `/think [task description]`

Classifies task complexity and routes to the right workflow depth.

| Classification | Signals | Route |
|---------------|---------|-------|
| **Tiny** | 1-2 files, bug fix, config tweak, "just", "quick" | Direct to `/build` |
| **Feature** | 3-10 files, new endpoint/component, has edge cases | `/architect` then `/build` |
| **Epic** | 10+ files, new system, migration, multi-concern | Agent Teams then `/architect` then `/build` |

**Epic Agent Teams**: For epic tasks, spawns three specialized agents:
- **Product Agent** — defines scope, deferred items, acceptance criteria
- **Architecture Agent** — designs data flow, API contracts, component boundaries
- **Security Agent** — STRIDE analysis, OWASP mapping, security requirements

Each agent has a FORGE checklist and required output format. Their outputs are synthesized into a unified architecture doc.

**Rules**: Always shows reasoning. User can override classification. When uncertain, picks the higher level.

---

## /architect — Lock Architecture

**Phase**: Planning
**Usage**: `/architect [task description]`

Produces a locked architecture document that `/build` must follow exactly.

**Steps**:
1. Recalls relevant past decisions from memory bank via `/memory-recall`
2. Analyzes existing codebase (structure, patterns, stack)
3. Produces architecture doc with: data flow, API contracts, component boundaries, edge cases, test strategy, dependencies, security considerations, deferred items
4. Saves doc to `.forge/architecture/[task-name].md`
5. Presents for user approval
6. Stores key decisions to memory via `/memory-remember`

**Output**: Locked Markdown doc at `.forge/architecture/`. Changes require re-running `/architect`.

**Rules**: Never writes implementation code. Every edge case must have a handling strategy. Every API must have defined error cases.

---

## /build — TDD Implementation

**Phase**: Build
**Usage**: `/build [architecture doc path or 'continue']`

Implements the architecture doc with strict TDD enforcement.

**Token Budget**: Before spawning subagents, estimates token cost. Warns if projected >40k tokens. Suggests Haiku routing for simple tasks.

**Model Routing**:
- **Haiku**: Config, boilerplate, simple CRUD, type definitions
- **Sonnet**: Standard features, API endpoints, integration tests
- **Opus**: Complex algorithms, security-critical code, edge cases

**TDD Loop** (per task):
1. Write failing tests first — tests MUST fail
2. Implement minimum code to pass
3. Run tests — all must pass
4. 2-stage review: spec compliance, then code quality

**Subagents**: For 3+ independent tasks, spawns agents in isolated worktrees. After each subagent completes, a checkpoint pauses execution to verify output against the architecture doc (API contracts, component boundaries, data flow) and logs PASS/FAIL — the next subagent only starts on PASS. Merges and runs full test suite after all complete.

**Final Verification**: Two-stage gate before declaring done. Stage 1: architecture compliance check (BLOCK merge on failure). Stage 2: full test suite (BLOCK merge on failure). Passing tests alone is not sufficient — both stages must pass.

**Rules**: Architecture doc is law. Tests must fail before implementation. Never skips review. Reports progress per task.

---

## /verify — Cross-Platform QA

**Phase**: QA
**Usage**: `/verify [optional: web|api|pipeline]`

Verifies build output actually works. Produces a pass/fail report for `/ship`.

**Domain Detection**:
- **Web App**: Playwright browser tests for key user flows
- **API**: Endpoint contract validation (status codes, response shapes, error cases, auth)
- **Data Pipeline**: Output diffing, schema validation, error handling
- **Hybrid**: Runs all applicable strategies

**On Failure**: Captures annotated screenshots (web), detailed error info. Each failure includes expected vs actual.

**Output**: Report at `.forge/verify/report.md` with status (PASS/FAIL), test counts, failure details. `commit_sha` and `tree_hash` are stamped into the report at write time for freshness tracking by `/ship`.

**Rules**: Never marks FAIL as PASS. Never modifies application code. Screenshots mandatory on web failures.

---

## /ship — Security Audit + PR

**Phase**: Ship
**Usage**: `/ship [--canary] [--draft]`

Final gate. Security audit, then PR creation.

**Blocks on**: `/review` and `/verify` failures — no override, no exceptions.

**Freshness Validation**: Extracts `commit_sha` from each report and compares it to the current `HEAD`. If either report was produced against a different commit, ship halts with a `STALE:` error and requires re-running `/review` and `/verify`. Auto-fix (see below) always invalidates both reports — they must be regenerated before proceeding even when the fix is minor.

**OWASP Top 10 Check**: Scans all changed files for injection, broken auth, data exposure, XXE, access control issues, misconfig, XSS, insecure deserialization, known vulnerabilities, insufficient logging.

**STRIDE Threat Model**: Evaluates spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege.

**Auto-Fix**: Fixes critical security issues (hardcoded secrets, missing sanitization). Re-runs tests after each fix. Asks for approval on ambiguous fixes.

**PR Creation**: Generates human-readable release summary grouped by type (features, fixes, security). Creates PR via `gh pr create`.

**Flags**:
- `--canary` — marks PR as canary deploy
- `--draft` — creates draft PR

---

## /review — Code Review Gate

**Phase**: Review  
**Usage**: `/review [optional: specific files or focus area]`

Code review gate between `/build` and `/verify`. Checks spec compliance, code quality, and security surface.

**Steps**:
1. Loads architecture doc and git diff
2. Spec compliance review (API contracts, component boundaries, edge cases, test strategy)
3. Code quality review (readability, duplication, complexity, error handling)
4. Security surface review (lightweight pre-check — not the full /ship audit)
5. Writes report to `.forge/review/report.md`, stamping `commit_sha` (`git rev-parse HEAD`) and `tree_hash` (`git rev-parse HEAD^{tree}`) into the report at write time

**Verdicts**:
- **PASS**: Only minor issues or suggestions. Ready for `/verify`.
- **NEEDS_CHANGES**: Major issues found. Fix and re-run `/review`.
- **FAIL**: Critical issues or fundamental problems. May need `/architect` revisit.

**Rules**: Critical issues = automatic FAIL. Never modifies code. Report must be machine-parseable by `/ship`.

### /review request — Prepare Review Request

**Usage**: `/review request [scope or context]`

Prepares a scoped review request for human reviewers or `/review` execution. Defines review criteria, focus areas, and context so reviewers know what to look at.

### /review response — Process Review Feedback

**Usage**: `/review response [feedback source]`

Processes and acts on review feedback. Extracts action items from review comments and prioritizes them as blocking, recommended, or suggestions.

---

## /debug — Root-Cause Debugging

**Phase**: Any  
**Usage**: `/debug [bug description, error message, or failing test]`

Root-cause-first debugging. Invoked by `/think` for debug tasks, or directly by user.

**Steps**:
1. Understand the bug from arguments or user input
2. Reproduce the error
3. Collect evidence (source files, git log, grep)
4. Form hypotheses ranked by likelihood
5. Test hypotheses systematically
6. Apply minimal fix, verify with tests
7. Write report to `.forge/debug/report.md`

**Rules**: Evidence before claims. Test hypotheses systematically. Minimal fix only. Never fabricate root cause.

---

## /memory — Decision Memory

**Phase**: All
**Usage**: `/memory [remember|recall|forget] [args]`

Cross-project architectural decision memory stored at `~/.forge/memory.jsonl`.

### Sub-commands

**`/memory recall [terms]`** — Retrieve relevant past decisions. Ranks by: project match > tag overlap > category relevance > recency. Returns top 5. Read-only.

**`/memory remember [decision]`** — Store a decision. Extracts from session context or explicit argument. Deduplicates before appending. Always confirms with user.

**`/memory forget [terms]`** — Search and selectively delete entries. `--prune` auto-removes entries older than 6 months with confidence < 0.5.

**`/memory`** (no args) — Shows memory bank status (entry count, projects, latest entry).

**Schema**: See [Memory Guide](memory-guide.md) for the full schema and usage details.

---

## /retro — Retrospective

**Phase**: Post-ship
**Usage**: `/retro [optional: project context]`

Collects structured feedback after a `/ship` cycle.

**Three Questions**:
1. What slowed us down?
2. What would we do differently?
3. What should FORGE remember?

**Skill Ratings**: Rates each skill used in the cycle (1-5). Low-rated skills get follow-up questions.

**Output**: Structured JSON at `~/.forge/retros/[date]_[project].json`. Feeds into `/evolve`. Question 3 answers are stored to memory via `/memory-remember`.

---

## /evolve — Self-Evolution

**Phase**: Meta
**Usage**: `/evolve [optional: specific skill name]`

Reads retrospective data and rewrites FORGE skills to improve them.

**Process**:
1. Loads all retro files, aggregates skill ratings
2. Scores each skill: healthy (>=3.5), ok (2.5-3.4), needs work (<2.5)
3. Analyzes feedback for low-scoring skills
4. Proposes changes classified by risk level
5. Applies approved changes, validates skill files
6. Logs evolution history

**Risk Levels**:
- **Low** (auto-apply): Wording, formatting, examples, typo fixes
- **Medium** (recommend + ask): Threshold changes, optional steps, verbosity adjustments
- **High** (explicit approval only): Removing safety checks, changing skill chain, modifying schema

**Output**: Evolution log at `~/.forge/retros/evolve_[date].json`. Key changes stored to memory.

**Rules**: Never removes safety guardrails without explicit approval. Needs at least 2 retros for meaningful proposals.

---

## /brainstorm — Ideation Before Architecture

**Phase**: Ideation
**Usage**: `/brainstorm [task description]`

Generates 3-5 alternative approaches before committing to architecture. Invoked by `/think` when a task has ambiguous solution paths, or directly by the user.

**Steps**:
1. Analyzes the task and existing codebase for constraints
2. Generates 3-5 distinct approaches with trade-offs
3. Scores each on effort, risk, maintainability, and performance
4. Recommends one approach with rationale
5. Produces artifact for `/architect` to consume

**Output**: Brainstorm doc at `.forge/brainstorm/[task-name].md`.

**Rules**: Never commits to a single approach without showing alternatives. Each approach must have clear trade-offs. Recommended approach must cite evidence from the codebase.

---

## /worktree — Isolated Workspace Setup

**Phase**: Lifecycle
**Usage**: `/worktree [branch-name]`

Creates an isolated git worktree for a task. Used by `/build` for subagent isolation, or directly by the user for parallel work.

**Steps**:
1. Creates a new branch from the current HEAD
2. Sets up a git worktree at `.forge/worktrees/[branch-name]`
3. Copies necessary configuration files
4. Reports the worktree path for use

**Output**: Worktree ready at `.forge/worktrees/[branch-name]`.

**Rules**: Always checks for existing worktrees before creating. Warns if uncommitted changes exist on the current branch. Pairs with `/finish` for cleanup.

---

## /finish — Branch Completion and Merge

**Phase**: Lifecycle
**Usage**: `/finish [branch-name]`

Completes work in a worktree: merges the branch back, runs tests, and cleans up the worktree.

**Steps**:
1. Switches to the worktree and verifies all tests pass
2. Merges the branch into the parent branch
3. Resolves conflicts if any (prompts user for ambiguous cases)
4. Removes the worktree and prunes the branch
5. Runs the full test suite on the merged result

**Output**: Merged branch, cleaned up worktree.

**Rules**: Never merges with failing tests. Always cleans up the worktree after merge. Warns before deleting branches with unmerged commits.

---

## /browse — Playwright Browser Automation

**Phase**: Browser
**Usage**: `/browse [url or flow description]`

Dedicated Playwright browser automation. Extracted from `/verify` in Phase 3 to separate test execution from test orchestration. Also usable standalone for any browser task.

**Steps**:
1. Launches Playwright in headless mode (or headed if requested)
2. Navigates to the target URL or executes the described flow
3. Captures screenshots at key steps
4. Reports results with evidence (screenshots, console output, network requests)

**Output**: Screenshots and logs at `.forge/browse/`.

**Rules**: Always captures screenshots on failure. Never modifies application state unless explicitly instructed. Headless by default for CI compatibility.

---

## /design — Design Consultation Suite

**Phase**: Design
**Usage**: `/design [consult|explore|review] [context]`

Design hub with three sub-skills for different design needs.

### /design consult
Open-ended design consultation. Analyzes requirements, proposes design directions, discusses trade-offs. Good for early-stage "how should we approach this?" questions.

### /design explore
Generates design variants. Given a design direction, produces 2-4 concrete alternatives with mockup descriptions, component breakdowns, and interaction flows.

### /design review
Reviews existing design artifacts (mockups, component trees, style guides) against usability heuristics and consistency criteria. Produces actionable feedback.

**Output**: Design artifacts at `.forge/design/`.

**Rules**: Always cites design rationale. Explore mode must produce at least 2 variants. Review mode must reference specific heuristics.

---

## /document-release — Post-Ship Documentation Sync

**Phase**: Post-ship
**Usage**: `/document-release [PR number or version]`

Synchronizes documentation after shipping. Reads the PR diff and release summary, then updates relevant docs.

**Steps**:
1. Reads the shipped PR diff and release notes
2. Identifies docs that need updating (README, API docs, guides)
3. Proposes documentation changes
4. Applies approved changes
5. Creates a follow-up PR if needed

**Output**: Updated documentation, optional follow-up PR.

**Rules**: Never overwrites docs without showing the diff first. Focuses on user-facing documentation. Skips internal-only changes.

---

## /careful — Destructive Operation Guard

**Phase**: Guard
**Usage**: `/careful [on|off]`

Session-scoped guardrail that warns before destructive operations. When enabled, intercepts commands like `git reset --hard`, `rm -rf`, `DROP TABLE`, force pushes, and similar.

**Behavior**: When `/careful on` is active, any destructive operation triggers a warning with the specific risk and asks for confirmation before proceeding.

**Rules**: Session-scoped only — does not persist across sessions. Advisory — the user can always override. Does not block non-destructive operations.

---

## /freeze — Scoped Edit Locks

**Phase**: Guard
**Usage**: `/freeze [patterns|off|list]`

Prevents edits to specified files or directories during a session. Useful for protecting stable code while working on related changes.

**Examples**:
- `/freeze src/core/**` — locks all files under src/core/
- `/freeze *.config.js` — locks all config files
- `/freeze list` — shows current locks
- `/freeze off` — removes all locks

**Rules**: Session-scoped only. Pattern-based using glob syntax. Shows a warning and refuses the edit when a frozen file is targeted. User can `/freeze off` at any time.

---

## /benchmark — Performance Benchmarking

**Phase**: Performance
**Usage**: `/benchmark [target function, endpoint, or module]`

Runs performance benchmarks and compares against baselines. Detects regressions before they ship.

**Steps**:
1. Identifies the target (function, endpoint, or module)
2. Runs baseline measurement (or loads saved baseline)
3. Runs current measurement with statistical rigor (multiple iterations)
4. Compares against baseline with threshold detection
5. Reports results with flamegraph-style analysis if regression detected

**Output**: Benchmark report at `.forge/benchmark/`.

**Rules**: Always runs multiple iterations for statistical significance. Regression threshold is configurable (default: 10% degradation). Saves baselines for future comparison.

---

## /canary — Canary Deployment

**Phase**: Deploy
**Usage**: `/canary [percentage]`

Gradual rollout with monitoring. Deploys to a small percentage of traffic, monitors for errors, and either promotes or rolls back.

**Steps**:
1. Deploys the build to canary infrastructure (configurable percentage, default 5%)
2. Monitors error rates, latency, and key metrics for a configurable window
3. Compares canary metrics against baseline
4. Promotes to full deployment if healthy, or rolls back if degraded
5. Reports deployment outcome

**Output**: Canary report at `.forge/releases/`.

**Rules**: Always monitors before promoting. Automatic rollback on error rate spike. Never promotes without baseline comparison.

---

## /deploy — Post-Merge Deployment

**Phase**: Deploy
**Usage**: `/deploy [environment]`

Post-merge deployment and health verification. Runs after a PR is merged to deploy and verify the release in the target environment.

**Steps**:
1. Verifies the PR is merged and CI is green
2. Triggers deployment to the target environment
3. Runs health checks against the deployed service
4. Verifies key functionality with smoke tests
5. Reports deployment status

**Output**: Deploy report at `.forge/releases/`.

**Rules**: Never deploys from an unmerged branch. Health checks must pass before marking deployment as successful. Supports rollback if health checks fail.

---

## /forge — FORGE Overview

**Phase**: Any
**Usage**: `/forge`

FORGE workflow overview and help. Lists all available skills, routing rules, and phase dependencies. Use as a quick reference or starting point. Includes a **Red Flags** table of rationalization patterns agents use to skip ceremony (e.g. "I'll skip `/verify`, it looks fine") — agents and reviewers should treat any such pattern as a process violation.
