# Changelog

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
