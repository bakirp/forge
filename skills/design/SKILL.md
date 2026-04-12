---
name: design
description: "Design workflow hub — routes to consultation, exploration, or review with anti-pattern enforcement and aesthetic direction. Triggered by 'design this', 'how should I lay out', 'explore design options', 'review the design', 'UI design', 'component design', 'make this look better', 'improve the UI', 'design consultation'."
argument-hint: "[consult|explore|review] [context]"
allowed-tools: Read Grep Glob Bash
---

# /design — Design Workflow Hub

Every sub-skill loads `skills/design/references/principles.md` for shared anti-patterns, aesthetics, usability heuristics; domain references loaded selectively per sub-skill. Commit to a direction -- strong aesthetic identity over safe, generic defaults.

## Routing

Delegate on `$ARGUMENTS`:

| Argument | Action |
|----------|--------|
| `consult [context]` | Invoke `/design-consult` with remaining arguments |
| `explore [context]` | Invoke `/design-explore` with remaining arguments |
| `review [context]` | Invoke `/design-review` with remaining arguments |
| `audit [context]` | Invoke `/design-audit` with remaining arguments |
| `polish [context]` | Invoke `/design-polish` with remaining arguments |
| *(no argument)* | Show sub-command table below |

## Sub-Commands (No Arguments)

| Command | Purpose |
|---------|---------|
| `/design consult [problem]` | Selects aesthetic direction, produces design-direction artifact with anti-pattern enforcement |
| `/design explore [problem]` | Generates 3-4 alternatives with named directions and comparison |
| `/design review [targets]` | Evaluates anti-patterns, accessibility, aesthetic coherence; gate: PASS/NEEDS_CHANGES |
| `/design audit [targets]` | Scores accessibility, responsiveness, interaction, anti-patterns, performance |
| `/design polish [targets]` | 6-check sweep (typography, color, spacing, motion, states, copy); makes fixes directly |

## Output Location

Artifacts saved to `.forge/design/`: `consult-[topic].md`, `explore-[topic].md`, `review-[topic].md`, `audit-[topic].md`, `polish-[topic].md`.

## What's Next

| After | Next | Alternative |
|-------|------|-------------|
| `/design consult` | `/design explore` | `/architect` (pass consult artifact) |
| `/design explore` | `/design review` | -- |
| `/design review` | `/design polish` | `/build` (if design ready) |
| `/design audit` | `/design polish` | -- |
| `/design polish` | `/ship` | -- |

Design is standalone -- no pipeline skill reads `.forge/design/` automatically. `/design review` evaluates visual/UX quality; `/review` evaluates code -- run both for frontend.

## Rules & Compliance

- Every recommendation must name an aesthetic direction; generic output is a failure mode.
- WCAG AA minimum bar. Respect existing design patterns and component libraries.
- Read the codebase to ground recommendations in reality. ASCII art and pseudocode are valid artifacts.

Follow `skills/shared/compliance-telemetry.md`. Log via `scripts/compliance-log.sh`. Keys: `generic-output` (major) -- no aesthetic direction named; `accessibility-skipped` (major) -- WCAG AA not evaluated; `design-system-ignored` (major) -- existing design system not referenced.
