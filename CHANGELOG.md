# Changelog

## v2.6.0 — 2026-04-07

Quality gates: code reusability enforcement, test coverage thresholds, universal framework detection, and path coverage validation.

### `scripts/quality-gate.sh` — New Shared Detection Script
- 7 subcommands: `detect-runner`, `detect-coverage`, `coverage`, `reusability-search`, `dry-check`, `path-map`, `path-diff`
- **Universal test framework detection** — 15+ frameworks: Jest, Vitest, Mocha, Cypress, Playwright, pytest, Go test, Cargo test, Maven, Gradle, RSpec, Minitest, PHPUnit, dotnet test, Bun
- **Coverage tool detection** — Istanbul/nyc, c8, coverage.py, go cover, JaCoCo, SimpleCov, PHPUnit coverage, dotnet coverage
- **Coverage threshold enforcement** — configurable via `.forge/config.json` `coverage_threshold`, exit code 1 on failure (hard gate)
- **Path coverage mapping** — extracts all condition paths (if/else, switch/case, loops, try/catch, ternary, guards) across 7 language families
- **Change impact analysis** — `path-diff` classifies changes as ADD_TEST, MODIFY_TEST, REMOVE_TEST, or NO_ACTION
- **Reusability search** — finds existing functions/classes matching patterns before writing new code
- **DRY check** — detects duplicate multi-line code blocks across files

### `/build` — Quality Gate Integration
- Replaced inline 9-item test runner detection with `quality-gate.sh detect-runner`
- New Step 4a.5: Reusability Search — searches for existing code before implementing
- New Path Coverage Protocol: enumerates paths before writing tests, one test per path, change impact analysis for modifications
- New Step 4c.5: Coverage Gate — blocks build if coverage below configured threshold

### `/review` — Path Coverage and Reusability Audit
- Added automated DRY check via `quality-gate.sh dry-check`
- New Path Coverage Completeness audit: flags untested paths (critical), duplicate tests (major), orphaned tests (minor)
- New Reusability audit: flags duplicate implementations when existing code could be reused
- Added Coverage and Path Coverage sections to review report template
- Updated FAIL rules: untested path = critical, duplicate tests = major

### `/verify` — Coverage Gate
- Added coverage threshold check in prerequisites — blocks verification if below threshold
- Added Coverage Metrics section to verification report

### Infrastructure
- `context-prune.sh` now delegates test runner detection to `quality-gate.sh` (eliminates duplication)
- New `tests/test-quality-gate.sh` with 40+ test cases across all 7 subcommands
- Updated `docs/artifact-schema.md` with Coverage and Path Coverage report sections

## v2.5.0 — 2026-04-07

Design skill system rebuild with anti-pattern enforcement and aesthetic direction.

### `/design` — Rebuilt Design Skill Suite
- Complete rewrite of `/design consult`, `/design explore`, `/design review`
- New `references/principles.md`: 10 design principles, 12 named aesthetic directions, 32-item anti-pattern blocklist across 8 dimensions, WCAG AA accessibility baseline with cognitive a11y, component state coverage checklist
- Anti-pattern blocklist: explicit "AI slop" signatures banned by dimension (typography, color, layout, motion, content, interaction, images, forms)
- Quality gate inlined in every sub-skill's Rules section — measurable, references blocklist
- Aesthetic direction catalog: 12 named directions offered (not mandated) during consultation
- Accessibility elevated from afterthought to design driver — shapes choices, not just checks them
- Stack-adaptive approach: web-first baseline, adapts to detected project stack
- Pipeline integration: `/design consult` -> `/architect` -> `/build` -> `/design review`
- Implementation Notes in consult output — bridges design decisions to `/build`

### Testing
- New `tests/test-design.sh` with 9 structural compliance tests
- Updated `tests/test-completeness.sh` with design evidence requirements
- 5 design eval scenarios in `evals/tasks/design/`

### Documentation
- Updated `docs/skills-reference.md` with new `/design` documentation
- Updated `docs/artifact-schema.md` with design artifact contracts

## v2.4.0 — 2026-04-06

Autonomous product builder and context pruning for build subagents.

### `/autopilot` — Fully Autonomous Product Builder
- New `/autopilot` skill: takes a one-line product description and runs the entire FORGE pipeline (brainstorm → architect → build → review → verify → ship) with zero user prompts
- Guard-enforced iteration limits via `scripts/autopilot-guard.sh` with real state file (`.forge/autopilot/state.json`)
- Inner loop (build-review): default max 3 cycles. Outer loop (verify retries): default max 2. Total phases: max 15
- Repeated failure detection: halts if the same issue hash appears twice
- Flags: `--max-iterations N`, `--skip-brainstorm`
- Generates `.forge/autopilot/future-enhancements.md` with deferred items, suggested improvements, tech debt, and security hardening
- Debug tasks are auto-detected and rejected (directs user to `/debug`)
- Added `tests/test-autopilot-guard.sh` with guard state management tests

### Context Pruning in `/build`
- Added `scripts/context-prune.sh` with subcommands: `extract`, `conventions`, `estimate`, `clean`
- Section extraction uses state machine with code block immunity and case-insensitive header matching
- Falls back to full architecture doc when sections not found (never produces empty bundles)
- Token warning when a bundle exceeds 8,000 tokens (per-task budget)
- New Step 3 output: section identifiers per task (e.g., `sections: [API Contracts::createTask, Edge Cases::1,3]`)
- New Step 3.5: builds `.forge/context/task-{n}.md` bundles from section identifiers
- Step 5 subagent prompt reads from context bundles when available, falls back to inline extraction
- Bundles persist between builds for debugging; cleaned at start of next build

### Test Coverage
- Added `tests/test-context-prune.sh` with 10 tests covering extraction, case-insensitivity, code block immunity, missing sections, conventions detection, token estimation, and cleanup
- Added `tests/fixtures/sample-architecture.md` test fixture
- Updated `tests/test-artifacts.sh` to recognize `.forge/context/` as a known artifact path

### Documentation
- Updated `docs/artifact-schema.md` with context bundle schema and lifecycle

## v2.3.0 — 2026-04-06

Competitive analysis-driven improvements: SessionStart hook, local telemetry, anti-sycophancy review, problem-framing brainstorm, and workflow automation.

### SessionStart Hook
- Added `hooks/hooks.json` with SessionStart event that injects FORGE context at session start
- `hooks/session-start` script outputs skill overview and suggests `/think`
- Claude Code only — auto-discovers available skills on every session

### Local Telemetry
- Added `scripts/telemetry.sh` — appends skill invocations to `~/.forge/telemetry.jsonl`
- Fields: skill name, timestamp, project path, classification (optional), outcome
- No external services — local JSONL only, feeds into `/evolve` for data-driven skill improvement
- Telemetry logging added to `/think`, `/build`, `/review`, `/ship`

### Anti-Sycophancy in `/review-response`
- Added Step 2: Technical Verification Gate before accepting review feedback
- Verifies each feedback item against actual code before implementing
- Pushes back on incorrect suggestions, reclassifies subjective opinions
- New rules: never implement unverified feedback, no performative agreement

### Problem-Framing in `/brainstorm`
- Added Step 0: "Are we solving the right problem?" with 5 forcing questions
- Questions: Who benefits? What if we don't build this? What does success look like? Simplest version? Solving a symptom?
- Respects user's "just build it" override — notes reasoning and proceeds

### Workflow Automation in `/think`
- Added `--auto` flag: auto-chains through pipeline (architect → build → review → verify) after classification
- User can interrupt at any gate by declining the continue prompt
- Default behavior (manual chaining) unchanged — opt-in automation only

### `/evolve` Enhanced with Telemetry
- `/evolve` now reads `~/.forge/telemetry.jsonl` alongside retro data
- Telemetry provides objective usage patterns: invocation counts, completion rates, abort frequency
- Can run telemetry-only analysis when no retro data exists

### New Test Suites
- `tests/test-hooks.sh` — 9 tests: hook directory, JSON validity, SessionStart event, script execution, output format
- `tests/test-telemetry.sh` — 13 tests: script execution, JSONL format, required fields, optional fields, append behavior, skill references

## v2.2.0 — 2026-04-06

Adopted superpowers execution discipline: artifact freshness, evidence-before-claims, and stronger subagent gates.

### Artifact Freshness Protocol
- `/review` and `/verify` now stamp `commit_sha` + `tree_hash` into their reports
- `/ship` validates both reports against current HEAD before shipping; blocks with `STALE:` on mismatch
- After any auto-fix, both `/review` and `/verify` reports must be regenerated before `/ship` proceeds

### Evidence-Before-Claims Consistency
- `/ship` requires PR URL as evidence before claiming ship is complete
- `/architect` requires doc header as evidence before claiming architecture is locked
- `/review` requires report header as evidence before claiming review is complete

### Subagent Checkpoints in `/build`
- Explicit checkpoint after each subagent: output verified against architecture doc before next subagent starts
- Prevents cascading failures from undetected contract violations mid-build

### Two-Stage Final Verification in `/build`
- Stage 1: architecture compliance (API contracts, component boundaries, data flow)
- Stage 2: test suite
- Both stages must pass; tests alone are not sufficient to complete the build gate

### Red Flags Table in `/forge`
- Added explicit rationalization-pattern table to the root dispatcher
- Lists patterns agents use to skip ceremony (e.g., "tests pass so it must be fine", "I'll verify later")
- Agents must check themselves against this table before claiming any phase complete

## v2.1.0 — 2026-04-06

Complete roadmap test plan coverage. Version bumped across plugin manifests.

### Test Suites Added
- **test-memory.sh** — Memory append, dedup, ranking, prune safety, invalid JSON handling (12 tests)
- **test-browser.sh** — /browse and /verify web mode skill contract validation (9 tests)
- **test-setup.sh** — Claude/Codex/Cursor host detection, directory creation, skill installation (13 tests)
- **test-evolution.sh** — /evolve risk classification, test harness gate, revert safety, guardrail protection (10 tests)

### Test Fixtures Added
- `tests/fixtures/memory-valid.jsonl` — Valid memory entries
- `tests/fixtures/memory-duplicates.jsonl` — Entries with intentional duplicates for dedup testing
- `tests/fixtures/memory-invalid.jsonl` — Malformed JSON lines for error handling
- `tests/fixtures/retro-sample.json` — Sample retrospective data for evolve testing

### CI Updated
- All 9 test suites now run in GitHub Actions

### Documentation & Manifests
- Fixed clone URL in README and getting-started.md (was placeholder)
- Added Testing section to README with test suite overview
- Added missing doc links in README and getting-started.md: artifact-schema, troubleshooting
- Bumped plugin.json and marketplace.json to 2.1.0
- Updated skills-reference.md: added /review:request, /review:response sub-skills, /forge overview skill, fixed /ship blocking description
- Updated contributing.md: expanded skill directory tree to include all 30 skills
- Updated memory-guide.md: fixed stale "deferred to v2" references
- Updated artifact-schema.md: added brainstorm, design, benchmark directories; expanded cross-artifact dependency table with all skills

## v2.0.0 — 2026-04-05

Full 4-phase roadmap implementation. FORGE now has 29 skills across the complete workflow.

### Phase 2: Superpowers-Style Execution
- **/brainstorm** — Ideation and alternative exploration before /architect
- **/worktree** — Isolated git worktree setup for tasks
- **/finish** — Branch completion, merge, and cleanup
- **/review-request** + **/review-response** — Dedicated review request/response sub-flows
- Evidence-before-claims rules enforced across /build, /review, /verify, /ship
- Context-pruned subagent dispatch in /build
- Run manifest tracking at `.forge/runs/`

### Phase 3: Operational Substrate
- **/browse** — Dedicated Playwright browser automation (extracted from /verify)
- **/document-release** — Post-ship documentation sync
- **/careful** — Destructive operation guardrails
- **/freeze** — Scoped edit locks
- Strengthened /ship: version bump, changelog generation, release artifacts, secrets archaeology
- Multi-host setup: Claude Code (primary), Codex, Cursor
- Helper scripts: memory-rank, memory-dedup, host-detect, artifact-discover

### Phase 4: Specialist Workflows
- **/design** suite — consult, explore, review sub-skills
- **/benchmark** — Performance testing with baseline comparison
- **/canary** — Canary deployment with monitoring and rollback
- **/deploy** — Post-merge deployment and health verification
- Cross-model second-opinion review in /review
- Trend analysis in /retro (project and cross-project)
- /evolve re-enabled with test-harness validation gate

## v1.1.0 — 2026-04-05

Phase 1: Make the core workflow trustworthy.

### New Skills

- **/review** — Code review gate between /build and /verify. Checks spec compliance against architecture doc, code quality, and security surface. Produces PASS/NEEDS_CHANGES/FAIL report at `.forge/review/report.md`.
- **/debug** — Root-cause-first debugging. Structured reproduction, evidence collection, hypothesis testing, targeted fix. Produces report at `.forge/debug/report.md`.

### Changes

- **/ship** now blocks on both `/review` AND `/verify` (previously only /verify)
- **/think** now detects debugging tasks and routes to `/debug`
- **/evolve** frozen to proposal-only mode until test harness validates skill integrity
- Root dispatcher upgraded to prefer skill invocation over ad-hoc action

### Infrastructure

- Artifact schema doc defining all `.forge/` contracts (`docs/artifact-schema.md`)
- Run manifest tracking at `.forge/runs/<run-id>/manifest.json`
- Test harness: `tests/test-routing.sh`, `tests/test-blocking.sh`, `tests/test-artifacts.sh`
- Helper scripts: `scripts/manifest.sh`, `scripts/artifact-check.sh`

## v1.0.0 — 2026-04-05

First public release. All 7 core skills implemented.

### Skills

- **/think** — Adaptive entry point. Classifies tasks as tiny/feature/epic and routes to the right workflow depth. Epic tasks spawn Agent Teams with product, architecture, and security agents.
- **/architect** — Locks architecture before build. Queries memory bank for past decisions, produces structured architecture doc with data flow, API contracts, edge cases, and test strategy.
- **/build** — TDD-enforced implementation. Failing tests before code, 2-stage review (spec compliance + code quality), subagent execution in isolated worktrees, smart model routing (Haiku/Sonnet/Opus), token budget warnings.
- **/verify** — Cross-platform QA. Auto-detects project domain (web/API/pipeline). Playwright for browser testing, contract validation for APIs, output diffing for pipelines. Produces pass/fail report.
- **/ship** — Security audit + PR creation. OWASP Top 10 and STRIDE threat model checks. Auto-fixes critical issues. Creates PR with release summary. Blocks on /verify failures.
- **/memory** — Cross-project decision memory (remember/recall/forget). JSONL storage at ~/.forge/memory.jsonl. Keyword + tag matching for recall. Auto-prune for stale entries.
- **/retro** — Post-ship retrospective. Three structured questions + per-skill ratings. Stores JSON data that /evolve consumes.
- **/evolve** — Self-rewriting skills. Reads retro data, scores skill effectiveness, proposes targeted diffs. Low-risk changes auto-apply; high-risk changes require approval.

### Infrastructure

- Setup script: `git clone && ./setup` installs 12 skills in under 60 seconds
- GitHub Actions CI: validates SKILL.md frontmatter on every push
- Pure Markdown — no binary, no runtime dependencies

### Documentation

- Getting Started guide
- Skills Reference (all 7 skills with examples)
- Memory Guide
- Evolve Guide
- Contributing guidelines
- CLAUDE.md template for projects
- Architecture decision records
