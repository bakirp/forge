---
name: design
description: "Design workflow hub. Routes to design consultation, variant exploration, or design review. Use when the task involves UI/UX, system design, or architectural design beyond what /architect covers."
argument-hint: "[consult|explore|review] [context]"
allowed-tools: Read Grep Glob Bash
---

# /design — Design Workflow Hub

FORGE design skills provide structured design thinking for UI/UX, system design, API design, and architectural design work that goes beyond what `/architect` covers. Design is advisory — it produces artifacts that feed into `/architect` and `/build`, not replacements for them.

## Routing

If `$ARGUMENTS` starts with a sub-command, delegate:

| Argument | Action |
|----------|--------|
| `consult [context]` | Invoke `/design-consult` with the remaining arguments |
| `explore [context]` | Invoke `/design-explore` with the remaining arguments |
| `review [context]` | Invoke `/design-review` with the remaining arguments |
| *(no argument)* | Show available sub-commands (below) |

## Sub-Commands (No Arguments)

When invoked without arguments, display:

```
FORGE /design — Design Workflow Hub

Available commands:

  /design consult [problem]   — Design consultation with constraints
                                Analyzes requirements, identifies constraints,
                                proposes a design direction with rationale.

  /design explore [problem]   — Variant exploration
                                Generates 3-4 genuinely different design
                                alternatives with side-by-side comparison.

  /design review [targets]    — Design review against principles
                                Evaluates existing design or implementation
                                for consistency, accessibility, and UX quality.

Examples:
  /design consult dashboard layout for analytics app
  /design explore notification system for mobile and web
  /design review src/components/Header.tsx src/components/Nav.tsx
```

## Design Output Location

All design artifacts are saved to `.forge/design/`:
- Consultations: `.forge/design/consult-[topic].md`
- Explorations: `.forge/design/explore-[topic].md`
- Reviews: `.forge/design/review-[topic].md`

## Rules

- Design is advisory, not a gate. Design outputs are input for `/architect`, not replacements.
- Never skip accessibility considerations. WCAG AA is the minimum bar.
- Respect existing design patterns in the project. Consistency matters more than novelty.
- Design skills read the codebase to ground recommendations in reality, not theory.
- If the project has a design system or component library, all recommendations must reference it.
- ASCII art and pseudocode are valid design artifacts. High-fidelity mockups are not expected.
