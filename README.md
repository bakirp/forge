# FORGE

**The Claude Code Skill Framework That Rewrites Itself**

FORGE is a Claude Code skill framework with three capabilities no existing tool has:

1. **Architectural decision memory** that survives across projects
2. **Adaptive phase depth** that eliminates unnecessary ceremony on simple tasks
3. **Self-evolving skills** that rewrite themselves based on your usage patterns

## Quick Start

```bash
git clone https://github.com/bakirp/Forge.git
cd Forge
./setup
```

Then open any project in Claude Code. FORGE's SessionStart hook will auto-inject a skill overview. Type `/think` to start any task.

See the [Getting Started Guide](docs/getting-started.md) for a full walkthrough.

## Skills

### Core Workflow

| Command | What it does | Phase |
|---------|-------------|-------|
| `/think` | Classifies task complexity (tiny/feature/epic), routes to right depth. `--auto` chains the full pipeline. | Planning |
| `/architect` | Locks architecture — data flow, API contracts, test strategy | Planning |
| `/build` | TDD-enforced implementation with subagents, model routing, reusability search, and path coverage | Build |
| `/review` | Code review gate — spec compliance, quality, security, DRY check, path coverage audit, coverage enforcement | Review |
| `/verify` | Cross-platform QA — web (Playwright), API, data pipeline, coverage threshold gate | QA |
| `/ship` | OWASP + STRIDE security audit, auto-fix, PR creation | Ship |
| `/debug` | Root-cause-first debugging with evidence collection | Debug |
| `/memory` | Cross-project decision memory (`/remember`, `/recall`, `/forget`) | All |
| `/retro` | Post-ship retrospective — structured feedback for `/evolve` | Retro |
| `/evolve` | Self-rewriting skills based on retro data | Meta |

### Extensions

| Command | What it does | Phase |
|---------|-------------|-------|
| `/brainstorm` | Problem-framing + ideation before /architect (5 forcing questions, then alternatives) | Ideation |
| `/worktree` | Isolated git worktree setup for tasks | Lifecycle |
| `/finish` | Branch completion, merge, and cleanup | Lifecycle |
| `/browse` | Playwright-based browser automation (standalone or from /verify) | Browser |
| `/design` | Design with anti-pattern enforcement, aesthetic direction, and accessibility | Design |
| `/benchmark` | Performance benchmarking and regression detection | Performance |
| `/canary` | Canary deployment with monitoring and rollback | Deploy |
| `/deploy` | Post-merge deployment and health verification | Deploy |
| `/document-release` | Post-ship documentation sync | Docs |
| `/careful` | Warns before destructive operations | Guard |
| `/freeze` | Scoped edit locks on files/directories | Guard |
| `/autopilot` | Fully autonomous product builder — runs the entire pipeline with self-healing loops | Automation |
| `/forge` | FORGE workflow overview, skill listing, and red-flags table | Meta |

## Workflow

```
User task
  │
  ▼
/think ── tiny ───────── /build ── /review ── /verify ── /ship ── /retro ── /evolve
  │                         ▲
  ├── needs ideation ── /brainstorm ── /architect ── /build ...
  │
  ├── feature ── /architect ┘
  │
  ├── debug task ── /debug
  │
  └── epic ── Agent Teams ── /architect ── /build ── /review ── /verify ── /ship ...

Standalone:  /worktree, /finish, /browse, /design, /benchmark, /canary, /deploy
Guards:      /careful, /freeze, /document-release
Memory:      /memory (remember/recall/forget)
Automation:  /autopilot (full pipeline, zero prompts)
Meta:        /forge (overview + red-flags table)
```

## Common Scenarios

| Scenario | Commands | Notes |
|----------|----------|-------|
| New greenfield project | `/think --auto` or `/autopilot` | Epic; spawns Agent Teams |
| Add a feature | `/think` → `/architect` → `/build` → `/review` → `/verify` → `/ship` | Use `/worktree` for isolation |
| Fix a bug | `/debug` or `/think` (auto-routes on bug signals) | Evidence-first, minimal fix |
| Enhance / refactor | `/think` → `/build` → `/review` → `/verify` → `/ship` | Tiny or feature classification |
| Production incident | `/debug [error or stack trace]` | Urgent root-cause-first |
| Performance issue | `/benchmark [target]` | Baseline + regression detection |
| Review a PR | `/review request` / `/review` / `/review response` | Anti-sycophancy guardrails |
| Deploy to production | `/ship` → `/deploy` or `/canary` | Security audit gates deployment |

See the [Recipes Guide](docs/recipes.md) for step-by-step walkthroughs of each scenario.

## How It Works

- **Claude Code provides the engine. FORGE provides the process.**
- Agent Teams = generic parallel execution. FORGE gives each agent a role, checklist, and exit gate.
- Auto-Memory = shallow preference recall. FORGE memory = architectural decisions and anti-patterns across projects.
- `/evolve` = no equivalent anywhere. Skills rewrite themselves from your retro data.

## Philosophy

- Pure Markdown skills — no binary, portable across AI coding tools
- Ship the simplest thing that works, then let `/evolve` improve it
- Memory compounds — decisions from project A inform project B
- Process scales down for tiny tasks and up for epics

## Quality and Reliability

- **Quality gates** — `scripts/quality-gate.sh` provides centralized test detection (15+ frameworks), coverage enforcement, reusability search, DRY checking, and path coverage analysis. Used by `/build`, `/review`, and `/verify`.
- **Coverage enforcement** — configurable threshold in `.forge/config.json` that acts as a hard gate across `/build`, `/review`, `/verify`, and `/ship`. Coverage below threshold = automatic FAIL.
- **Path coverage validation** — every condition path (if/else, switch/case, loops, try/catch) must have exactly one test. No untested paths, no duplicate test coverage. Change impact analysis (`path-diff`) guides whether to add, modify, or remove tests.
- **Code reusability** — `/build` searches for existing functions before writing new code; `/review` flags duplicate implementations as major issues.
- **Artifact freshness protocol** — `/review` and `/verify` stamp `commit_sha` + `tree_hash` into their reports. `/ship` validates both against current HEAD before shipping, blocking with `STALE:` on mismatch. After any auto-fix, both reports must be regenerated.
- **Subagent checkpoints in `/build`** — explicit checkpoint after each subagent verifies output against the architecture doc before the next subagent starts. Final verification is two-stage: architecture compliance first, then the test suite. Tests alone are not sufficient to pass the gate.
- **Phase isolation** — post-build phases (`/review`, `/verify`, `/ship`) can run as isolated foreground subagents with fresh context, eliminating self-evaluation bias and context rot. `/build` writes a structured handoff artifact (`.forge/build/report.md`) that captures files modified, test results, architecture deviations, and user decisions for downstream phases.
- **Evidence-before-claims** — `/ship`, `/architect`, and `/review` require showing actual output as evidence before claiming work is complete.
- **Anti-sycophancy in `/review response`** — review feedback is technically verified against the actual codebase before implementation. Incorrect suggestions are pushed back on, not blindly applied.
- **Local telemetry** — skill invocations are logged to `~/.forge/telemetry.jsonl` for data-driven improvement via `/evolve`.

## Testing

FORGE includes 16 test suites covering routing, blocking gates, artifacts, memory, browser automation, evolution, setup, completeness, manifest tracking, hooks, telemetry, autopilot-guard, context-prune, quality-gate, design, and handover.

```bash
# Run all tests
for t in tests/test-*.sh; do bash "$t"; done
```

Tests run automatically in GitHub Actions CI on every push.

## Documentation

- [Getting Started](docs/getting-started.md) — install, setup, first session
- [Recipes](docs/recipes.md) — step-by-step workflows for common scenarios
- [Skills Reference](docs/skills-reference.md) — detailed docs for every skill
- [Memory Guide](docs/memory-guide.md) — how cross-project memory works
- [Evolve Guide](docs/evolve-guide.md) — how self-evolution works
- [Artifact Schema](docs/artifact-schema.md) — `.forge/` artifact contracts
- [Troubleshooting](docs/troubleshooting.md) — common issues and solutions
- [CLAUDE.md Template](docs/CLAUDE-md-template.md) — project config template
- [Contributing](docs/contributing.md) — how to contribute
- [Architecture](ARCHITECTURE.md) — design decisions and rationale

## License

MIT
