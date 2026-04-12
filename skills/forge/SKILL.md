---
name: forge
description: "FORGE workflow overview — lists all available skills, routing rules, and phase dependencies. Use when asking about available commands, workflow order, or how FORGE works — triggered by 'what skills', 'available commands', 'workflow', 'how does forge work', 'what can you do'."
argument-hint: "[optional: skill name or 'help']"
allowed-tools: Read Grep Glob Bash
---

# FORGE — Workflow Overview

FORGE orchestrates Claude Code: plan -> build -> review -> verify -> ship. Run `/forge` anytime.

## Core Pipeline Skills

| Command | Phase | Purpose |
|---------|-------|---------|
| `/think` | Entry | Classify complexity (tiny/feature/epic), route to correct depth |
| `/autopilot` | All | Fully autonomous pipeline with self-healing loops |
| `/architect` | Plan | Lock architecture doc before building |
| `/build` | Build | TDD-enforced implementation with subagents |
| `/review` | Review | Code review gate: spec compliance, quality, security |
| `/review adversarial` | Review | Red-team review against 7 attack surfaces |
| `/verify` | QA | Cross-platform testing with Playwright |
| `/ship` | Ship | OWASP + STRIDE audit, PR creation |

**Support skills** (invoke anytime): `/debug`, `/memory`, `/retro`, `/evolve`, `/brainstorm`, `/worktree`, `/finish`, `/browse`, `/document-release`, `/careful`, `/freeze`, `/design`, `/benchmark`, `/canary`, `/deploy`

## Workflow Rules

- Default to `/think` unless user explicitly invokes a specific skill — never skip or guess complexity.
- No `/build` without a locked architecture doc (unless tiny). TDD enforced: tests fail before code.
- `/review` after `/build`, before `/verify`. `/ship` blocks on any failure — no exceptions.
- `/architect` checks memory bank first; decisions stored after shipping.
- Routing: see `skills/shared/workflow-routing.md` for full table.

## Dispatcher Logic

Prefer routing to a skill over ad-hoc action. Debug signals (bug, error, broken) -> `/debug`; build/feature signals -> `/think`; explicit invocation -> execute directly.

## Red Flags

Stop and run the skipped skill if you catch yourself thinking:

- "Skip /think" -- it classifies complexity; skipping means guessing.
- "I know the architecture" -- decisions must be locked in a doc, not memory.
- "Skip the worktree" -- worktrees prevent polluting main, no exceptions.
- "Tests pass, skip /review" -- tests prove behavior, not correctness or spec compliance.
- "It looks fine, skip /verify" -- looking fine is not evidence; /verify produces the artifact /ship requires.
- "Old report works for /ship" -- reports only valid for exact commit they target.
- "I'll remember this" -- memory is session-scoped; use `/memory` to persist.

## Proactive Mode & Configuration

- Warn if projected token usage exceeds 40k before spawning subagents.
- Surface memory in `/architect`; note decisions worth persisting at session end.
- Track phases and artifacts in `.forge/runs/`.
- Config: `.forge/config.json` — `token_budget`, `test_command`, `coverage_command`, `coverage_threshold`, `default_branch`. Precedence: user args > config > defaults.

## Shared Protocols

Compliance & telemetry: `skills/shared/compliance-telemetry.md` (log via `scripts/compliance-log.sh`). Common rules: `skills/shared/rules.md`.
