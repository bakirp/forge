---
name: design
description: "Design workflow hub — routes to consultation, exploration, or review with anti-pattern enforcement and aesthetic direction. Triggered by 'design this', 'how should I lay out', 'explore design options', 'review the design', 'UI design', 'component design', 'make this look better', 'improve the UI', 'design consultation'."
argument-hint: "[consult|explore|review] [context]"
allowed-tools: Read Grep Glob Bash
---

# /design — Design Workflow Hub

Every sub-skill loads `skills/design/references/principles.md` for shared anti-patterns and the aesthetic direction catalog.

## Design Philosophy

Commit to a direction — strong aesthetic identity over safe, generic defaults. If a recommendation could belong to any project, it belongs to none; every output names its direction, defends that choice, and enforces anti-patterns that block convergence toward AI slop.

## Routing

Delegate on `$ARGUMENTS`:

| Argument | Action |
|----------|--------|
| `consult [context]` | Invoke `/design-consult` with remaining arguments |
| `explore [context]` | Invoke `/design-explore` with remaining arguments |
| `review [context]` | Invoke `/design-review` with remaining arguments |
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

Examples:
  /design consult dashboard layout — needs an industrial, data-dense feel
  /design explore onboarding flow — compare editorial vs soft organic
  /design review src/components/Header src/components/Nav
```

## Output Location

Artifacts are saved to `.forge/design/`: `consult-[topic].md`, `explore-[topic].md`, `review-[topic].md`.

## Relationship to Other FORGE Skills

- `/design` happens after `/brainstorm` and before or alongside `/architect`.
- `/design consult` produces a design-direction artifact that `/architect` consumes as input.
- `/design review` evaluates visual/UX quality; `/review` evaluates code quality. Complementary, not interchangeable.
- `/build` should read `.forge/design/` artifacts to respect the chosen aesthetic direction.

## Rules

- Every recommendation must name an aesthetic direction. Generic output is a failure mode.
- WCAG AA is the minimum bar. Never skip accessibility.
- Respect existing design patterns. Consistency over novelty.
- Read the codebase to ground recommendations in reality, not theory.
- If a design system or component library exists, all recommendations must reference it.
- ASCII art and pseudocode are valid artifacts. High-fidelity mockups are not expected.
