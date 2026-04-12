---
name: design-consult
description: "Design consultation with aesthetic direction, anti-pattern enforcement, and accessibility as a design driver. Proposes direction with implementation notes for /build — triggered by 'consult on design', 'design direction', 'what should this look like'."
argument-hint: "[design problem or requirements]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-consult — Design Consultation

Commit to a direction; accessibility shapes choices from the start — not a checklist applied after.

## Step 1: Frame the Problem

Parse `$ARGUMENTS`. State interpretation, identify purpose/audience/emotional tone. Ask: **what is the one memorable thing users should take away?** Review `skills/design/references/principles.md` — suggest a named direction with rationale or define a custom one (name, 1-sentence description, 3 characteristics).

```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
find . -maxdepth 4 \( -name "*.tokens.*" -o -name "theme.*" -o -name "design-system*" -o -name "*.css" \) 2>/dev/null | head -20
```

## Step 2: Constraints & Accessibility Context

Read references: `skills/design/references/principles.md` (anti-patterns, a11y baseline, state coverage), `typography.md`, `color-and-contrast.md`, `motion-design.md`.

Identify constraints — flag any assumed rather than confirmed:
- **Technical**: platform capabilities, performance budgets, architecture boundaries
- **Business**: timeline, expertise, maintenance burden, compatibility
- **User / Accessibility** (design driver): contrast 4.5:1/3:1, reduced-motion from start, 44x44dp touch targets, color never sole indicator

## Step 3: Analyze Existing Patterns

Document what exists: layout, typography, color, spacing, components, interactions. **Consistency is default** — deviation requires justification.

## Step 4: Define Design Language

Define the language, validating against the anti-pattern blocklist:

- **Typography**: Primary/secondary typefaces per `typography.md`; modular scale ratio, fluid `clamp()` values, `font-display`, OpenType features — verify not banned
- **Color**: OKLCH palette with roles (primary, neutral, semantic, surface); tint neutrals (0.01 chroma of brand hue); verify every pairing (4.5:1/3:1); dark mode strategy
- **Spacing**: 4pt grid (4, 8, 12, 16, 24, 32, 48, 64px); vertical rhythm tied to body line-height
- **Motion**: Per `motion-design.md` — `cubic-bezier()` easing, durations (micro 100-150ms, standard 200-300ms, complex 300-500ms), `prefers-reduced-motion` fallback for every animation
- **Surface**: Borders, shadows, radii, textures — consistent with direction

## Step 5: Propose Direction + Implementation Notes

Present one recommended direction: **Core Principle** (1 sentence), **Key Decisions** (3-5 bullets with rationale), **Constraints Honored**, **Tradeoffs Accepted**, **Open Questions** (with reasonable defaults).

**Implementation Notes** (what `/build` consumes):
- Design token mapping: semantic names to values (`color-surface-primary`, `spacing-base`, `type-heading-family`)
- State coverage per component: default, hover, focus, active, disabled, loading, error, empty, partial-data, skeleton — flag gaps
- Responsive strategy: breakpoints, layout shifts, changes per tier

## Step 6: Write Output + Report

Derive topic slug (lowercase, hyphens, max 4 words). Write to `.forge/design/consult-[topic].md` with sections: Problem (+ memorable takeaway), Aesthetic Direction, Design Language, Constraints, Implementation Notes, Open Questions.

```bash
mkdir -p .forge/design
```

Validate against quality gate, show consultation header (first 10 lines) as evidence, then report:
```
FORGE /design-consult — Complete
Output: .forge/design/consult-[topic].md
Direction: [name] | Core principle: [1 sentence]
Key decisions: [count] | Open questions: [count or "none"]
```

## Quality Gate

- [ ] Names a specific aesthetic direction; all choices consistent with it
- [ ] Passes every anti-pattern blocklist item; font choices justified and not banned
- [ ] Accessibility shapes choices from Step 1, not checked after
- [ ] All component states addressed or flagged "needs design for [state]"
- [ ] Consultation header shown before claiming complete

## Rules

Never name specific frameworks. Existing patterns are default; deviation requires justification. Ground every recommendation in the codebase. Too broad? Narrow it — deep beats shallow. Propose, do not mandate.

> **Compliance, telemetry, error handling, and what's-next routing**: see `skills/shared/compliance-telemetry.md`, `skills/shared/rules.md`, and `skills/shared/workflow-routing.md`.
> Log violations via `scripts/compliance-log.sh`. Keys: `design-consult no-evidence major`, `design-consult ungrounded major`.
> Recommended next: `/design explore`. Alternative: `/architect` with consult artifact as context.
