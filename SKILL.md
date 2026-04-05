---
name: forge
description: "FORGE bootstrap — Claude Code skill framework that routes tasks through adaptive planning, TDD build, verification, and shipping phases. Reads this file at session start."
argument-hint: ""
allowed-tools: Read Grep Glob Bash Agent
---

# FORGE — Claude Code Skill Framework

You are operating in a FORGE-powered session. FORGE orchestrates Claude Code's capabilities (Agent Teams, subagents, worktrees) into a structured workflow: plan, build, verify, ship.

## Session Start

Before doing anything else:

1. **Recall memory** — run the `/memory-recall` workflow: check `~/.forge/memory.jsonl`, surface the top 3 most relevant entries to the current project context. Keep injection under 300 tokens. If no memory bank or no relevant entries, skip silently.

2. **Detect project context** — read `CLAUDE.md` if present for project-specific conventions. FORGE augments project rules, never overrides them.

## Skills

| Command | Phase | What it does |
|---------|-------|-------------|
| `/think [task]` | Entry | Classifies complexity (tiny/feature/epic), routes to the right depth |
| `/architect [task]` | Planning | Produces locked architecture doc: data flow, API contracts, test strategy |
| `/build` | Build | TDD-enforced implementation via subagents in isolated worktrees |
| `/verify` | QA | Cross-platform testing with Playwright (web, API, data pipeline modes) |
| `/ship` | Ship | OWASP + STRIDE security audit, PR creation, deploy |
| `/memory` | All | Cross-project decision memory: /remember, /recall, /forget |
| `/evolve` | Retro | Meta-agent that rewrites skills based on retrospective data |

## Workflow Rules

- **Always start with `/think`** unless the user explicitly invokes a specific skill
- **Never skip phases** — `/think` determines the right depth automatically
- **Architecture before code** — no `/build` without a locked architecture doc (unless tiny)
- **TDD enforced** — tests must fail before implementation code is written
- **Ship blocks on failure** — `/ship` will not proceed if `/verify` reports failures
- **Memory compounds** — `/architect` checks memory bank first; decisions are stored after shipping

## Routing

```
User task
  │
  ▼
/think ── tiny ──────────────── /build ── /verify ── /ship ── /retro ── /evolve
  │                                ▲
  ├── feature ── /architect ───────┘
  │
  └── epic ── Agent Teams ── /architect ── /build ── /verify ── /ship ── /retro ── /evolve
              (product, arch, security agents)
```

## Proactive Mode

When a task is in progress, FORGE proactively:
- Warns if projected token usage exceeds 40k tokens before spawning subagents
- Surfaces relevant memory entries when entering /architect
- Blocks /ship if /verify has failures — no exceptions
- Notes decisions worth remembering at the end of /architect sessions

## Current Status

All skills implemented: `/think`, `/architect`, `/build`, `/verify`, `/ship`, `/memory` (remember/recall/forget), `/retro`, `/evolve`
