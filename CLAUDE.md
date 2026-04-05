# FORGE — Claude Code Skill Framework

You are operating within a FORGE-powered project. FORGE provides structured skills that guide your workflow from planning through shipping.

## Core Skills

| Skill | Purpose | When to use |
|-------|---------|-------------|
| `/think` | Classify task complexity and route to the right workflow | **Start every task here** |
| `/architect` | Lock architecture before building (data flow, API contracts, test strategy) | Called by /think for feature+ tasks |
| `/build` | TDD-enforced implementation with subagents | After architecture is locked |
| `/review` | Code review gate — spec compliance, quality, security surface | After build completes |
| `/verify` | Cross-platform QA with Playwright | After review passes |
| `/ship` | Security audit + PR creation + deploy | After verification passes |
| `/debug` | Root-cause-first debugging | When bug/error/failure is reported |
| `/memory` | Cross-project decision memory | Automatic at /architect start |
| `/retro` | Post-ship retrospective | After shipping |
| `/evolve` | Self-rewriting skills from retro data | After sprint retrospectives |
| `/brainstorm` | Ideation before architecture | When /think routes to ideation |

## Workflow Extensions

| Skill | Purpose | When to use |
|-------|---------|-------------|
| `/worktree` | Isolated workspace setup | Before starting isolated work |
| `/finish` | Branch completion and merge | After work in a worktree |
| `/browse` | Playwright browser automation | Web testing, delegated from /verify |
| `/design` | Design consultation/exploration/review | UI/UX or system design work |
| `/benchmark` | Performance benchmarking | Before shipping perf-critical changes |
| `/canary` | Canary deployment | Gradual rollout after /ship |
| `/deploy` | Post-merge deployment | After PR is merged |
| `/document-release` | Documentation sync | After shipping |
| `/careful` | Destructive operation guard | Enable for safety-critical sessions |
| `/freeze` | Scoped edit locks | Protect files during focused work |

## Workflow

1. User describes a task
2. `/think` classifies complexity: **tiny** (direct build), **feature** (/architect → /build), **epic** (Agent Teams → /architect → /build)
3. `/review` runs after `/build`, before `/verify`
4. Each phase produces an artifact the next phase consumes
5. Never skip phases — `/think` determines the right depth automatically

## Rules

- Always start with `/think` unless the user explicitly invokes a specific skill
- Never proceed to `/build` without a locked architecture doc (unless /think classified as tiny)
- Enforce TDD: tests must fail before implementation code is written
- Check memory bank at the start of `/architect` for relevant past decisions
- `/ship` blocks if `/review` or `/verify` reports failures — no exceptions

## Memory Bank

FORGE maintains a cross-project decision memory at `~/.forge/memory.jsonl`. When starting `/architect`:
- Automatically recall relevant past decisions
- Surface anti-patterns from previous projects
- At session end, remember new architectural decisions

## Project Conventions

When FORGE is installed into a project, respect any existing project conventions found in the project's own documentation. FORGE process augments — it does not override project-specific rules.
