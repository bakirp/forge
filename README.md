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

| Command | What it does | Phase |
|---------|-------------|-------|
| `/think` | Classifies task complexity (tiny/feature/epic), routes to right depth | Planning |
| `/architect` | Locks architecture — data flow, API contracts, test strategy | Planning |
| `/build` | TDD-enforced implementation with subagents and model routing | Build |
| `/verify` | Cross-platform QA — web (Playwright), API, data pipeline | QA |
| `/ship` | OWASP + STRIDE security audit, auto-fix, PR creation | Ship |
| `/memory` | Cross-project decision memory (`/remember`, `/recall`, `/forget`) | All |
| `/retro` | Post-ship retrospective — structured feedback for `/evolve` | Retro |
| `/evolve` | Self-rewriting skills based on retro data | Meta |

## Workflow

```
/think ── tiny ────────────────── /build ── /verify ── /ship ── /retro
  |                                  ^                             |
  ├── feature ── /architect ─────────┘                          /evolve
  |                  |                                             |
  └── epic ── Agent Teams ── /architect                    improved skills
              (product, arch, security)
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
