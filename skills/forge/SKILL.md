---
name: forge
description: "FORGE workflow overview — lists all available skills, routing rules, and phase dependencies. Use when asking about available commands, workflow order, or how FORGE works — triggered by 'what skills', 'available commands', 'workflow', 'how does forge work', 'what can you do'."
argument-hint: "[optional: skill name or 'help']"
allowed-tools: Read Grep Glob Bash Agent
---

# FORGE — Workflow Overview

FORGE orchestrates Claude Code into a structured workflow: plan → build → review → verify → ship. Run `/forge` for this overview at any time.

## Skills

| Command | Phase | What it does |
|---------|-------|-------------|
| `/think [task]` | Entry | Classifies complexity (tiny/feature/epic), routes to the right depth |
| `/autopilot [desc]` | All | Fully autonomous pipeline with self-healing loops and future enhancements |
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
  ├── /autopilot ── brainstorm → architect → [build ⟷ review]* → [verify]* → ship → future
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

- **Debug signals** (bug, error, failing, broken, investigate) → route to `/debug`
- **Build/feature/change signals** → route to `/think`
- **Explicit skill invocation** (e.g., "/verify") → execute it directly

## Red Flags

These thoughts are rationalizations — if you catch yourself thinking one, that's the signal to stop and run the skipped skill.

| Thought | Reality |
|---------|---------|
| "This is just a tiny task, I'll skip /think" | /think classifies complexity — skipping it means guessing. Use it. |
| "I know the architecture, I don't need /architect" | Architecture decisions must be locked in a doc. Memory is not a contract. |
| "I'll just build this quickly without a worktree" | Worktrees prevent polluting main. No exceptions for "quick" work. |
| "The tests pass, I don't need /review" | Tests prove behavior, not correctness or spec compliance. |
| "I'll skip /verify, it looks fine" | Looking fine is not evidence. /verify produces the artifact /ship requires. |
| "I already reviewed this, /ship can trust the old report" | Reports are only valid for the exact commit they were generated against. |
| "I'll remember this decision for next time" | Memory is session-scoped. Use /memory to persist it. |

## Proactive Mode

When a task is in progress, FORGE proactively:
- Warns if projected token usage exceeds 40k tokens before spawning subagents
- Surfaces relevant memory entries when entering /architect
- Blocks /ship if /review or /verify has failures — no exceptions
- Notes decisions worth remembering at the end of /architect sessions
- Tracks each session's phases and artifacts in the run manifest at `.forge/runs/`

## Project Configuration

FORGE reads optional overrides from `.forge/config.json` if present:

| Field | Default | Purpose |
|-------|---------|---------|
| `token_budget` | 40000 | Token warning threshold for /build |
| `test_command` | auto-detect | Explicit test runner command (15+ frameworks supported) |
| `coverage_command` | auto-detect | Explicit coverage tool command |
| `coverage_threshold` | none | Minimum coverage % — hard gate blocking /build, /review, /verify, /ship |
| `default_branch` | auto-detect | Override git default branch |

All fields optional. Precedence: explicit user arguments > .forge/config.json > FORGE defaults. Project CLAUDE.md governs coding conventions separately.

## Helper Scripts

| Script | Purpose |
|--------|---------|
| `quality-gate.sh` | Test/coverage detection, threshold enforcement, reusability search, DRY check, path coverage |
| `context-prune.sh` | Architecture doc section extraction, project conventions |
| `telemetry.sh` | Skill invocation logging |
| `artifact-check.sh` | Artifact freshness validation |
| `manifest.sh` | Run manifest tracking |
| `autopilot-guard.sh` | Iteration limits for /autopilot |
