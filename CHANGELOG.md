# Changelog

## v0.0.2 — 2026-04-09

Enforcement hardening for the autonomous autopilot skill. Added structural barriers to prevent inline implementation, designed conditional design step routing for UI tasks, and clarified auto-proceed scope to eliminate ambiguity in skill invocation decisions.

### Autopilot Enforcement

- **Hard rule enforcement** — Added HARD RULE that inline implementation is forbidden. Every phase MUST be invoked using the Skill tool. Added per-step enforcement reminders at Steps 1–4 to keep the rule salient during execution.
- **Artifact verification gates** — Added `test -f` checks after Brainstorm, Design, and Architect phases to halt the pipeline if skill output artifacts are missing. Reflects that skill invocation failures must stop the pipeline, not degrade it.
- **Failure handling rule** — New FAILURE HANDLING section clarifies that missing artifacts halt the pipeline immediately — no silent degradation, no substitution with inline code.
- **Step 5 inline fix anti-pattern** — Fixed review loop inner cycle: now invokes `/forge:build` with targeted prompt instead of "apply fixes directly." Inline code changes in the orchestrator are a contract violation.

### Conditional Design Step for UI Tasks

- **Step 2b: Design** — Added new optional step between Brainstorm and Architect. If task has UI (pages, views, components, layouts, flows, forms, dashboards, settings screens), invoke `/forge:design` to inform architecture direction.
- **UI detection in Step 1 (Think)** — Expanded Think step to detect `HAS_UI` flag, which controls whether Step 2b is inserted into the pipeline.
- **TINY+UI user approval** — For TINY tasks with UI, autopilot pauses and asks user whether to include design (HIGH-RISK decision point, no auto-proceed).
- **Updated routing table** — Think step routing now specifies 5 pipeline variants: TINY (no UI), TINY (with UI), FEATURE (no UI), FEATURE (with UI), EPIC (all have design).

### Auto-Proceed Scope Clarification

- **Explicit negative statement** — Updated AUTOPILOT MODE context block with "AUTO-PROCEED does NOT mean: choosing to skip a skill invocation. Invoking each skill is not a decision — it is mandatory."
- **Duplicated in orchestrator preamble** — Added the same rule to Steps 1–4 preamble in the orchestrator's own instructions, not just the context passed to sub-skills, to prevent decay of rule salience over time.

### Quality & Verification

- All 16 test suites pass with 0 failures
- autopilot-guard.sh tests: 15/15 passing
- No regressions in artifact schema, blocking logic, completion rules, or evolution guardrails

## v0.0.1 — 2026-04-09

Initial release. FORGE is a structured Claude Code skill framework: plan, build, review, verify, ship — with TDD enforcement, quality gates, coverage enforcement, and adaptive complexity routing.

### Core Workflow (11 skills)

- **/think** — Adaptive entry point. Classifies tasks as tiny/feature/epic and routes to the right workflow depth. `--auto` chains the full pipeline.
- **/architect** — Locks architecture before build — data flow, API contracts, test strategy. Reads brainstorm artifacts when available.
- **/build** — TDD-enforced implementation with subagents, model routing, vertical slice ordering, mocking discipline, reusability search, path coverage, and coverage gate. Writes structured handoff artifact for downstream phases.
- **/review** — Code review gate — spec compliance, quality, security, DRY check, path coverage audit, coverage enforcement, runtime behavior analysis. Stamps `commit_sha` + `tree_hash` for freshness.
- **/review adversarial** — Red-team review — challenges implementations against 7 attack surfaces (auth, data loss, race conditions, rollback, degraded deps, schema drift, observability gaps).
- **/verify** — Cross-platform QA — web (Playwright), API, data pipeline. Coverage threshold gate. Runtime behavior pre-check.
- **/ship** — OWASP + STRIDE security audit, artifact freshness validation, auto-fix, PR creation with release artifacts.
- **/debug** — Root-cause-first debugging with evidence collection and hypothesis testing.
- **/memory** — Cross-project decision memory (remember/recall/forget). JSONL storage with keyword + tag matching.
- **/retro** — Post-ship retrospective — structured feedback for `/evolve`.
- **/evolve** — Self-rewriting skills based on retro data and telemetry, with test-harness validation gate.

### Extensions (17 skills)

- **/brainstorm** — Problem-framing + ideation with 5 forcing questions. `--grill` mode for stress-testing existing plans.
- **/worktree** — Isolated git worktree setup for tasks.
- **/finish** — Branch completion, merge, and cleanup. Gate enforcement on review/verify reports.
- **/browse** — Playwright-based browser automation with adaptive URL resolution.
- **/design** — Design suite: consult, explore, review, audit, polish. Anti-pattern enforcement, AI slop detection, accessibility, WCAG AA baseline, 5 domain reference files.
- **/benchmark** — Performance benchmarking and regression detection.
- **/canary** — Canary deployment with monitoring and rollback.
- **/deploy** — Post-merge deployment and health verification.
- **/document-release** — Post-ship documentation sync.
- **/careful** — Warns before destructive operations (advisory, session-scoped).
- **/freeze** — Scoped edit locks on files/directories (advisory, session-scoped).
- **/autopilot** — Fully autonomous product builder — runs the entire pipeline with guard-enforced iteration limits and self-healing loops.
- **/review request** / **/review response** — Dedicated review request/response sub-flows with anti-sycophancy guardrails.
- **/forge** — FORGE workflow overview, skill listing, and red-flags table.

### Agents

- **forge-reviewer** — Isolated code review subagent (fresh context, no build-phase bias)
- **forge-verifier** — Isolated verification subagent
- **forge-shipper** — Isolated shipping subagent
- **forge-builder** — Build execution subagent
- **forge-adversarial-reviewer** — Red-team review subagent
- **product-agent**, **architecture-agent**, **security-agent** — Agent Team roles for epic tasks

### Infrastructure

- **Quality gates** — `scripts/quality-gate.sh` with 7 subcommands: detect-runner, detect-coverage, coverage, reusability-search, dry-check, path-map, path-diff. Supports 15+ test frameworks.
- **Phase isolation** — Post-build phases run as isolated subagents with structured handoff artifacts.
- **Artifact freshness protocol** — `commit_sha` + `tree_hash` stamped into review/verify reports, validated by `/ship`.
- **Local telemetry** — Skill invocations logged to `~/.forge/telemetry.jsonl` for data-driven improvement.
- **SessionStart hook** — Auto-injects FORGE context at session start.
- **Context pruning** — `scripts/context-prune.sh` builds focused context bundles for subagents.
- **Run manifests** — `.forge/runs/` tracks execution history.
- **Helper scripts** — memory-rank, memory-dedup, artifact-discover, artifact-check, manifest, autopilot-guard, telemetry, detect-branch.

### Testing

- 16 test suites covering: routing, blocking gates, artifacts, memory, browser automation, evolution, hooks, telemetry, autopilot-guard, context-prune, quality-gate, manifest, completeness, design, handover, adversarial review.
- 50 evaluation task scenarios across ambiguous, debug, feature, tiny, and design categories.
- Test fixtures for memory, retro data, and architecture templates.

### Documentation

- Getting Started guide, Recipes, Skills Reference, Memory Guide, Evolve Guide, Artifact Schema, Troubleshooting, CLAUDE.md Template, Skill Trigger Map, Contributing guidelines, Architecture decisions.

### Design Reference Library

- `typography.md` — modular scales, fluid type, font selection
- `color-and-contrast.md` — OKLCH, WCAG AA, dark mode
- `interaction-design.md` — 8-state model, form patterns, focus management
- `motion-design.md` — easing curves, duration ranges, reduced-motion
- `responsive-design.md` — fluid grids, container queries, mobile-first
- `principles.md` — 10 design principles, 12 aesthetic directions, 32-item anti-pattern blocklist, Nielsen's 10 heuristics
