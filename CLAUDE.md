# FORGE — Claude Code Skill Framework

You are operating within a FORGE-powered project. FORGE provides structured skills that guide your workflow from planning through shipping.

## Core Skills

| Skill | Purpose | When to use |
|-------|---------|-------------|
| `/think` | Classify task complexity and route to the right workflow | **Start every task here** |
| `/architect` | Lock architecture before building (data flow, API contracts, test strategy) | Called by /think for feature+ tasks |
| `/build` | TDD-enforced implementation with subagents | After architecture is locked |
| `/verify` | Cross-platform QA with Playwright | After build completes |
| `/ship` | Security audit + PR creation + deploy | After verification passes |
| `/memory` | Cross-project decision memory | Automatic at /architect start |
| `/evolve` | Self-rewriting skills from retro data | After sprint retrospectives |

## Workflow

1. User describes a task
2. `/think` classifies complexity: **tiny** (direct build), **feature** (/architect → /build), **epic** (Agent Teams → /architect → /build)
3. Each phase produces an artifact the next phase consumes
4. Never skip phases — `/think` determines the right depth automatically

## Rules

- Always start with `/think` unless the user explicitly invokes a specific skill
- Never proceed to `/build` without a locked architecture doc (unless /think classified as tiny)
- Enforce TDD: tests must fail before implementation code is written
- Check memory bank at the start of `/architect` for relevant past decisions
- `/ship` blocks if `/verify` reports failures — no exceptions

## Memory Bank

FORGE maintains a cross-project decision memory at `~/.forge/memory.jsonl`. When starting `/architect`:
- Automatically recall relevant past decisions
- Surface anti-patterns from previous projects
- At session end, remember new architectural decisions

## Project Conventions

When FORGE is installed into a project, respect any existing project conventions found in the project's own documentation. FORGE process augments — it does not override project-specific rules.
