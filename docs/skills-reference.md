# FORGE Skills Reference

Complete reference for all FORGE skills. Each skill is a Markdown file with YAML frontmatter that Claude Code reads and executes.

## Skill Chain

```
/think → /architect → /build → /verify → /ship → /retro → /evolve
                ↕                                    ↕
             /memory                              /memory
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

**Subagents**: For 3+ independent tasks, spawns agents in isolated worktrees. Merges and runs full test suite after all complete.

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

**Output**: Report at `.forge/verify/report.md` with status (PASS/FAIL), test counts, failure details.

**Rules**: Never marks FAIL as PASS. Never modifies application code. Screenshots mandatory on web failures.

---

## /ship — Security Audit + PR

**Phase**: Ship
**Usage**: `/ship [--canary] [--draft]`

Final gate. Security audit, then PR creation.

**Blocks on**: `/verify` failures — no override, no exceptions.

**OWASP Top 10 Check**: Scans all changed files for injection, broken auth, data exposure, XXE, access control issues, misconfig, XSS, insecure deserialization, known vulnerabilities, insufficient logging.

**STRIDE Threat Model**: Evaluates spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege.

**Auto-Fix**: Fixes critical security issues (hardcoded secrets, missing sanitization). Re-runs tests after each fix. Asks for approval on ambiguous fixes.

**PR Creation**: Generates human-readable release summary grouped by type (features, fixes, security). Creates PR via `gh pr create`.

**Flags**:
- `--canary` — marks PR as canary deploy
- `--draft` — creates draft PR

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
