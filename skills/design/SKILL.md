---
name: design
description: "Design workflow hub — routes to consultation, exploration, or review with anti-pattern enforcement and aesthetic direction. Triggered by 'design this', 'how should I lay out', 'explore design options', 'review the design', 'UI design', 'component design', 'make this look better', 'improve the UI', 'design consultation'."
argument-hint: "[consult|explore|review] [context]"
allowed-tools: Read Grep Glob Bash
---

# /design — Design Workflow Hub

Every sub-skill loads `skills/design/references/principles.md` for shared anti-patterns, aesthetic direction catalog, usability heuristics, and review angles. Skills selectively load additional domain references (typography, color, motion, interaction, responsive) based on their needs — no skill loads all references.

## Design Philosophy

Commit to a direction — strong aesthetic identity over safe, generic defaults. If a recommendation could belong to any project, it belongs to none; every output names its direction, defends that choice, and enforces anti-patterns that block convergence toward AI slop.

## Routing

Delegate on `$ARGUMENTS`:

| Argument | Action |
|----------|--------|
| `consult [context]` | Invoke `/design-consult` with remaining arguments |
| `explore [context]` | Invoke `/design-explore` with remaining arguments |
| `review [context]` | Invoke `/design-review` with remaining arguments |
| `audit [context]` | Invoke `/design-audit` with remaining arguments |
| `polish [context]` | Invoke `/design-polish` with remaining arguments |
| *(no argument)* | Show available sub-commands (below) |

## Sub-Commands (No Arguments)

When invoked without arguments, display:

```
FORGE /design — Design Workflow Hub

Available commands:

  /design consult [problem]   — Design consultation with constraints
                                Selects aesthetic direction, produces a
                                design-direction artifact with anti-pattern
                                enforcement.

  /design explore [problem]   — Variant exploration
                                Generates 3-4 alternatives, each with a
                                named aesthetic direction and comparison.

  /design review [targets]    — Design review against principles
                                Evaluates for anti-pattern violations,
                                accessibility, and aesthetic coherence.
                                Quality gate: PASS or NEEDS_CHANGES.

  /design audit [targets]     — Technical design quality audit
                                Scores accessibility, responsiveness,
                                interaction completeness, anti-patterns,
                                and performance. Measurement, not gate.

  /design polish [targets]    — Final visual polish before shipping
                                6-check sweep: typography, color, spacing,
                                motion, states, copy. Makes fixes directly.

Examples:
  /design consult dashboard layout — needs an industrial, data-dense feel
  /design explore onboarding flow — compare editorial vs soft organic
  /design review src/components/Header src/components/Nav
  /design audit src/components/Dashboard
  /design polish src/components/Settings
```

## Output Location

Artifacts are saved to `.forge/design/`: `consult-[topic].md`, `explore-[topic].md`, `review-[topic].md`, `audit-[topic].md`, `polish-[topic].md`.

## Relationship to Other FORGE Skills

- `/design` is a standalone suite. Invoke it directly before or after main pipeline phases.
- `/design consult` produces a direction artifact at `.forge/design/consult-*.md`. Pass this path to `/architect` as context if you want architecture to respect design direction.
- `/design review` evaluates visual/UX quality; `/review` evaluates code quality. Complementary — run both for frontend projects.
- `/design audit` measures technical design quality. Run after `/build` for a scored report.
- `/design polish` makes final visual fixes. Run after `/design review` and before `/ship`.
- No main pipeline skill reads `.forge/design/` artifacts automatically — the user drives the design workflow.

## Rules

- Every recommendation must name an aesthetic direction. Generic output is a failure mode.
- WCAG AA is the minimum bar. Never skip accessibility.
- Respect existing design patterns. Consistency over novelty.
- Read the codebase to ground recommendations in reality, not theory.
- If a design system or component library exists, all recommendations must reference it.
- ASCII art and pseudocode are valid artifacts. High-fidelity mockups are not expected.
