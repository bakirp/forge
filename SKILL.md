---
name: forge
description: "FORGE bootstrap — Claude Code skill framework that routes tasks through adaptive planning, TDD build, verification, and shipping phases. Reads this file at session start."
argument-hint: ""
allowed-tools: Read Grep Glob Bash Agent
---

# FORGE — Claude Code Skill Framework

You are operating in a FORGE-powered session. FORGE orchestrates Claude Code's capabilities (Agent Teams, subagents, worktrees) into a structured workflow: plan, build, review, verify, ship.

## Session Start

Before doing anything else:

1. **Recall memory** — run the `/memory-recall` workflow: check `~/.forge/memory.jsonl`, surface the top 3 most relevant entries to the current project context. Keep injection under 300 tokens. If no memory bank or no relevant entries, skip silently.

2. **Detect project context** — read `CLAUDE.md` if present for project-specific conventions. FORGE augments project rules, never overrides them.

3. **Create run manifest** — when a task begins, run `scripts/manifest.sh create "task"` to initialise the run manifest under `.forge/runs/<run-id>/manifest.json`.

## Skills

| Command | Phase | What it does |
|---------|-------|-------------|
| `/think [task]` | Entry | Classifies complexity (tiny/feature/epic), routes to the right depth |
| `/architect [task]` | Planning | Locks architecture doc before building |
| `/build` | Build | TDD-enforced implementation with subagents |
| `/review` | Review | Code review gate — spec compliance, quality, security surface |
| `/verify` | QA | Cross-platform testing with Playwright |
| `/ship` | Ship | OWASP + STRIDE security audit, PR creation |
| `/debug` | Any | Root-cause-first debugging |
| `/memory` | All | Cross-project decision memory |
| `/retro` | Retro | Post-ship retrospective |
| `/evolve` | Meta | Self-rewriting skills from retro data |
| `/brainstorm` | Ideation | Alternative exploration before /architect |
| `/worktree` | Setup | Isolated git worktree for a task |
| `/finish` | Lifecycle | Complete branch, merge back, clean up |
| `/browse` | Browser | Playwright-based browser automation |
| `/document-release` | Docs | Post-ship documentation sync |
| `/careful` | Guard | Warns before destructive operations |
| `/freeze` | Guard | Scoped edit locks on files/directories |
| `/design` | Design | Design consultation, exploration, review |
| `/benchmark` | Perf | Performance benchmarking and regression detection |
| `/canary` | Deploy | Canary deployment with monitoring |
| `/deploy` | Deploy | Post-merge deployment and health verification |

## Workflow Rules

- **Always start with `/think`** unless the user explicitly invokes a specific skill
- **Never skip phases** — `/think` determines the right depth automatically
- **Architecture before code** — no `/build` without a locked architecture doc (unless tiny)
- **TDD enforced** — tests must fail before implementation code is written
- **Review before verify** — `/review` runs after `/build`, before `/verify`
- **Ship blocks on failure** — `/ship` will not proceed if `/review` OR `/verify` reports failures
- **Memory compounds** — `/architect` checks memory bank first; decisions are stored after shipping

## Routing

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

Standalone skills (invoked directly):
  /worktree, /finish, /browse, /design, /benchmark, /canary, /deploy
  /careful, /freeze, /document-release
  /memory (remember/recall/forget)
```

## Dispatcher Logic

When a user describes a task, PREFER routing to a skill over ad-hoc action.

- **Debug signals** (bug, error, failing, broken, investigate) — route to `/debug`
- **Build/feature/change signals** — route to `/think`
- **Explicit skill invocation** (e.g., "/verify") — execute it directly

## Run Tracking

Each task run is tracked under `.forge/runs/<run-id>/manifest.json`. The manifest records the task description, skill sequence, phase transitions, and final outcome. Created automatically at session start via `scripts/manifest.sh`.

## Proactive Mode

When a task is in progress, FORGE proactively:
- Warns if projected token usage exceeds 40k tokens before spawning subagents
- Surfaces relevant memory entries when entering /architect
- Blocks /ship if /review or /verify has failures — no exceptions
- Notes decisions worth remembering at the end of /architect sessions

## Current Status

All 29 skills implemented:

**Core workflow**: `/think`, `/architect`, `/build`, `/review`, `/verify`, `/ship`, `/debug`, `/memory` (remember/recall/forget), `/retro`, `/evolve`

**Phase 2 — Superpowers**: `/brainstorm`, `/worktree`, `/finish`, `/review-request`, `/review-response`

**Phase 3 — Substrate**: `/browse`, `/document-release`, `/careful`, `/freeze`

**Phase 4 — Specialists**: `/design` (consult/explore/review), `/benchmark`, `/canary`, `/deploy`
