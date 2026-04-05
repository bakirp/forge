# FORGE

**The Claude Code Skill Framework That Rewrites Itself**

FORGE is a Claude Code skill framework with three capabilities no existing tool has:

1. **Architectural decision memory** that survives across projects
2. **Adaptive phase depth** that eliminates unnecessary ceremony on simple tasks
3. **Self-evolving skills** that rewrite themselves based on your usage patterns

## Quick Start

```bash
git clone https://github.com/yourusername/forge.git
cd forge
./setup
```

Then open any project in Claude Code and type `/think` to start.

See the [Getting Started Guide](docs/getting-started.md) for a full walkthrough.

## Skills

### Core Workflow

| Command | What it does | Phase |
|---------|-------------|-------|
| `/think` | Classifies task complexity (tiny/feature/epic), routes to right depth | Planning |
| `/architect` | Locks architecture — data flow, API contracts, test strategy | Planning |
| `/build` | TDD-enforced implementation with subagents and model routing | Build |
| `/review` | Code review gate — spec compliance, quality, security surface | Review |
| `/verify` | Cross-platform QA — web (Playwright), API, data pipeline | QA |
| `/ship` | OWASP + STRIDE security audit, auto-fix, PR creation | Ship |
| `/debug` | Root-cause-first debugging with evidence collection | Debug |
| `/memory` | Cross-project decision memory (`/remember`, `/recall`, `/forget`) | All |
| `/retro` | Post-ship retrospective — structured feedback for `/evolve` | Retro |
| `/evolve` | Self-rewriting skills based on retro data | Meta |

### Extensions

| Command | What it does | Phase |
|---------|-------------|-------|
| `/brainstorm` | Ideation and alternative exploration before /architect | Ideation |
| `/worktree` | Isolated git worktree setup for tasks | Lifecycle |
| `/finish` | Branch completion, merge, and cleanup | Lifecycle |
| `/browse` | Playwright-based browser automation (standalone or from /verify) | Browser |
| `/design` | Design consultation, exploration, and review | Design |
| `/benchmark` | Performance benchmarking and regression detection | Performance |
| `/canary` | Canary deployment with monitoring and rollback | Deploy |
| `/deploy` | Post-merge deployment and health verification | Deploy |
| `/document-release` | Post-ship documentation sync | Docs |
| `/careful` | Warns before destructive operations | Guard |
| `/freeze` | Scoped edit locks on files/directories | Guard |

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

Standalone: /worktree, /finish, /browse, /design, /benchmark, /canary, /deploy
Guards:     /careful, /freeze, /document-release
Memory:     /memory (remember/recall/forget)
```

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

## Documentation

- [Getting Started](docs/getting-started.md) — install, setup, first session
- [Skills Reference](docs/skills-reference.md) — detailed docs for every skill
- [Memory Guide](docs/memory-guide.md) — how cross-project memory works
- [Evolve Guide](docs/evolve-guide.md) — how self-evolution works
- [CLAUDE.md Template](docs/CLAUDE-md-template.md) — project config template
- [Contributing](docs/contributing.md) — how to contribute
- [Architecture](ARCHITECTURE.md) — design decisions and rationale

## License

MIT
