# FORGE Architecture

Design decisions and their rationale.

## Why Pure Markdown Skills (No Binary)

Claude Code discovers skills from `.claude/skills/<name>/SKILL.md` files. A SKILL.md file with YAML frontmatter and markdown instructions is all Claude needs to execute a structured workflow.

A binary would add:
- Build steps and platform-specific compilation
- A runtime dependency users must install and update
- A barrier to contribution (most Claude Code users aren't systems programmers)
- Lock-in to a single host (Claude Code only)

Pure Markdown means FORGE skills are portable in principle to any AI coding tool that reads markdown instructions. FORGE currently targets Claude Code exclusively.

## Why JSONL for Memory

The memory bank (`~/.forge/memory.jsonl`) stores one JSON object per line:

```json
{"id":"abc123","project":"myapp","date":"2026-04-01","category":"architecture","decision":"Use PostgreSQL over SQLite","rationale":"Need concurrent writes from multiple services","anti_patterns":["SQLite for multi-service writes"],"tags":["database","postgres"],"confidence":0.9}
```

Why JSONL over SQLite, JSON array, or a database:
- **Human-readable**: `cat` or `grep` the file directly
- **Append-only**: No read-modify-write cycle. Just append a line.
- **Git-trackable**: Users can optionally version their memory bank
- **No dependencies**: No database driver, no schema migrations
- **Grep-friendly**: `grep "database" ~/.forge/memory.jsonl` just works

For v1, keyword + tag matching is sufficient for recall. Vector embeddings are deferred to v2 — only worth the complexity if recall accuracy becomes a real user complaint.

## Why Playwright for Browser Testing

`/verify` uses Playwright via `npx playwright` rather than Claude Code's built-in browser MCP tools because:
- **Cross-platform**: Works on Linux CI, Windows, macOS — not just the developer's machine
- **Headless**: Runs in CI without a display server
- **Programmable**: Full control over test flows, assertions, screenshots
- **No daemon**: `npx playwright` cold-starts in ~3 seconds. Acceptable for v1.

The MCP browser tools (`mcp__claude-in-chrome__*`) require Chrome running locally and don't work in CI. FORGE targets the full workflow including automated verification.

## Skill Discovery and Installation

FORGE skills live in `skills/` in the repo. They are made available by adding FORGE as a Claude Code plugin, which auto-discovers all skills via `.claude-plugin/plugin.json`.

Why global install (not per-project):
- FORGE is a workflow framework, not a project dependency
- Skills like `/think` and `/architect` apply to any project
- Avoids polluting each project's `.claude/` directory
- Users can override globally-installed skills with project-local versions in `.claude/skills/`

## Skill Chaining

Skills invoke each other via `/skill-name` in their instructions:
- `/think` classifies complexity, then invokes `/architect` for features
- `/architect` produces a locked doc, then the user (or automation) invokes `/build`
- `/build` completes, then `/verify` runs
- `/verify` passes, then `/ship` creates the PR

Each phase produces an artifact (doc, code, test report) that the next phase consumes. This loose coupling means:
- Skills can be invoked independently
- Phases can be skipped when the user knows what they're doing
- New skills can be inserted into the chain without modifying existing ones

## Adaptive Complexity (/think)

Most frameworks force the same ceremony on every task. A one-line bug fix shouldn't require an architecture doc. An epic shouldn't skip planning.

`/think` classifies tasks into three tiers:
- **Tiny**: Direct build, no architecture phase
- **Feature**: Architecture first, then build
- **Epic**: Agent Teams with specialized roles (product, architecture, security), then build

Classification uses signals from the task description and codebase context, not arbitrary rules. The user can always override.

## Agent Teams for Epics

For epic-complexity tasks, `/think` spawns Claude Code Agent Teams with FORGE-specific roles. Each agent gets:
- A defined role (product scope, architecture, security)
- A structured prompt with specific deliverables
- An exit gate (the output format they must produce)

This is different from generic parallel agents because each agent has domain expertise encoded in its prompt, not just "help with this task."

## Artifact Schema (Phase 1)

Phase 1 introduces a formal artifact schema at `docs/artifact-schema.md`. Every skill that produces output writes to a well-defined path under `.forge/`:

- `/architect` → `.forge/architecture/[task-name].md`
- `/review` → `.forge/review/report.md`
- `/verify` → `.forge/verify/report.md`
- `/debug` → `.forge/debug/report.md`
- Run manifests → `.forge/runs/<run-id>/manifest.json`

This schema enables:
- **Blocking gates**: `/ship` reads `.forge/review/report.md` and `.forge/verify/report.md` status lines
- **Run tracking**: The manifest records which phases completed and where artifacts are
- **Test validation**: The test harness can verify artifacts exist and are well-formed

The schema is the contract between skills. Skills produce artifacts; downstream skills consume them. Adding a new skill means defining its artifact path and format in the schema.

### Artifact Freshness

Review and verify reports include two freshness fields written at report time:

- `commit_sha` — `git rev-parse HEAD`
- `tree_hash` — `git rev-parse HEAD^{tree}`

Before shipping, `/ship` validates these against the current HEAD. If the working tree has advanced since the report was written, `/ship` rejects the artifacts as stale and requires `/review` and `/verify` to be re-run. `scripts/artifact-check.sh` performs the same check and can be run manually at any point.

## Quality Gates as Infrastructure

Test detection, coverage enforcement, and path analysis are delegated to `scripts/quality-gate.sh` rather than inlined in skill Markdown. Three agents independently validated this design choice:

- **Deterministic enforcement**: A bash script that exits non-zero when coverage is below threshold is a hard gate. Claude cannot skip a failing exit code — the output is visible and unambiguous. Prompt-level delegation (a sub-skill saying "check coverage") can be skipped or paraphrased.
- **Single source of truth**: 15+ framework detection rules live in one script. Adding a new framework means editing one file, not three skills. This eliminates the DRY violation where `/build` Step 4a and `context-prune.sh` had diverging detection logic.
- **Follows existing patterns**: `context-prune.sh`, `telemetry.sh`, `manifest.sh` all use the same subcommand dispatcher pattern. Skills call scripts for detection; scripts return structured output; skills make policy decisions.

The 7 subcommands (`detect-runner`, `detect-coverage`, `coverage`, `reusability-search`, `dry-check`, `path-map`, `path-diff`) are consumed by `/build`, `/review`, and `/verify` at specific integration points. The script handles sensing; skills handle judgment.

## Evidence-Before-Claims (Phase 2)

Every success or failure claim in FORGE must cite evidence: the command run, its output, and what was asserted. This prevents hallucinated results — a persistent risk with AI-generated verification claims.

## Browser Skill Extraction (Phase 3)

/verify was doing two jobs: deciding what to test and executing browser tests. Phase 3 extracts execution into /browse, making /verify a pure report-and-gate layer. This separation means /browse can also be used standalone for browser tasks unrelated to verification.

## Guard Skills (Phase 3)

/careful and /freeze are opt-in, session-scoped guardrails. They don't persist across sessions by design — persistent file locks would break collaborative workflows. They're advisory: the user can always override.

## SessionStart Hook

FORGE uses Claude Code's hook infrastructure to inject context at session start. The `hooks/hooks.json` file registers a SessionStart event that runs `hooks/session-start`, which outputs a skill overview and suggests `/think`. This ensures users always know FORGE is active without needing to remember to invoke it manually.

Why a hook instead of relying on trigger words: trigger words in skill descriptions require Claude Code to match against user input, which is unreliable for session initialization. A SessionStart hook fires deterministically on every session, clear, and compact.

## Local Telemetry

Skill invocations are logged to `~/.forge/telemetry.jsonl` via `scripts/telemetry.sh`. Each entry records: skill name, timestamp, project path, classification (optional), and outcome (completed/aborted/error).

Why local JSONL (not a service): same rationale as the memory bank — human-readable, append-only, grep-friendly, no dependencies. Telemetry feeds into `/evolve` as an objective data source alongside subjective retro ratings, enabling data-driven skill improvement.

## Anti-Sycophancy in Review Response

`/review-response` includes a technical verification gate before implementing review feedback. Every feedback item is verified against the actual codebase — incorrect suggestions are pushed back on, subjective opinions are reclassified.

Why this matters: AI agents have a tendency toward performative agreement ("great catch!") before verifying claims. This wastes time implementing bad suggestions and can introduce bugs. The anti-sycophancy gate enforces honest technical assessment.

## Problem-Framing in Brainstorm

`/brainstorm` now starts with 5 forcing questions ("Are we solving the right problem?") before exploring solutions. This was identified as a gap vs gstack's `/office-hours` skill — FORGE was solution-oriented without questioning the problem first.

Why integrated (not a new skill): a separate problem-framing skill would add ceremony and dilute FORGE's identity. Integrating it as Step 0 in `/brainstorm` keeps the workflow lean while addressing the gap.

## Workflow Automation (`--auto` flag)

`/think --auto` chains through the full pipeline (architect → build → review → verify) without manual invocation per phase. The user can interrupt at any gate.

Why opt-in: the default manual chaining preserves user control and visibility. Auto mode is for experienced users who trust the pipeline and want less friction. It's a flag, not a mode switch — each invocation decides independently.
