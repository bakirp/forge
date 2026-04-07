---
name: design-consult
description: "Design consultation with aesthetic direction, anti-pattern enforcement, and accessibility as a design driver. Proposes direction with implementation notes for /build — triggered by 'consult on design', 'design direction', 'what should this look like'."
argument-hint: "[design problem or requirements]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-consult — Design Consultation with Aesthetic Direction

You frame the problem, commit to an aesthetic direction, define a design language, and produce implementation notes that `/build` consumes. Accessibility shapes your choices from the start — not a checklist applied after.

## Step 1: Frame the Problem

Parse `$ARGUMENTS`. State your interpretation before proceeding. Ask: **what is the one memorable thing users should take away?**

Identify purpose, audience, emotional tone. Review the aesthetic direction catalog in `skills/design/references/principles.md`. If a named direction fits, suggest it with rationale. If none fits, define a custom one: name, 1-sentence description, 3 characteristics.

Read the codebase for patterns, design system, and stack:
```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
find . -maxdepth 4 \( -name "*.tokens.*" -o -name "theme.*" -o -name "design-system*" -o -name "*.css" \) 2>/dev/null | head -20
```

## Step 2: Identify Constraints & Accessibility Context

Read `skills/design/references/principles.md` — the anti-pattern blocklist, accessibility baseline, and state coverage checklist apply to every recommendation.

**Technical**: Platform capabilities, performance budgets, architecture boundaries.
**Business**: Timeline, expertise, maintenance burden, compatibility.
**User / Accessibility** — a design driver, not a post-hoc audit:
- Color system defined with contrast ratios in mind (4.5:1 normal text, 3:1 large text)
- Typography chosen for readability across sizes and weights
- Motion planned with reduced-motion support from the start
- Touch targets 44x44dp minimum on touch interfaces
- Color never the sole status indicator

Flag any constraint you assumed rather than confirmed.

## Step 3: Analyze Existing Patterns

Document what exists: layout system, typography, color, spacing, component patterns, interaction conventions.

**Consistency with existing patterns is default.** Deviation requires justification.

## Step 4: Define Design Language

Define the design language, validating against the anti-pattern blocklist:

**Typography Pairing**: Primary and secondary typefaces. Justify each choice. Verify not on banned list.
**Color System**: Palette with roles (primary, secondary, surface, text, error, success). Every pairing with contrast ratio verified.
**Spacing Rhythm**: Base unit and scale with consistent mathematical relationship.
**Motion Rules**: What earns motion (hierarchy, staging, reinforcement). Easing curves. Reduced-motion fallback for every animation.
**Surface Treatments**: Borders, shadows, radii, textures — consistent with direction.

## Step 5: Propose Direction + Implementation Notes

You present one recommended direction:
- **Core Principle** (1 sentence)
- **Key Decisions** (3-5 bullets with rationale)
- **Constraints Honored**: which and how
- **Tradeoffs Accepted**: what and why
- **Open Questions**: needing user input (make reasonable defaults where possible)

**Implementation Notes** (what `/build` consumes):
- Design token mapping: semantic names to values (`color-surface-primary`, `spacing-base`, `type-heading-family`)
- State coverage per component: default, hover, focus, active, disabled, loading, error, empty, partial-data, skeleton. Flag gaps as "needs design for [state]"
- Responsive strategy: breakpoints, layout shifts, changes per tier

## Step 6: Write Output + Report

Derive a topic slug (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/consult-[topic].md`:

```markdown
# Design Consultation: [Topic]
Date: [YYYY-MM-DD]

## Problem
[1-2 sentences. One memorable takeaway.]

## Aesthetic Direction
[Named or custom direction. 1-sentence description.]

## Design Language
### Typography
### Color
### Spacing
### Motion

## Constraints
### Technical
### Business
### User / Accessibility

## Implementation Notes
### Design Tokens
### State Coverage
### Responsive Strategy

## Open Questions
```

Validate against the quality gate, then report:

```
FORGE /design-consult — Complete
Output: .forge/design/consult-[topic].md

Direction: [name]
Core principle: [1 sentence]
Key decisions: [count]
Open questions: [count or "none"]
```

Show the consultation header (first 10 lines) as evidence before claiming complete.

## Rules

- **Evidence before claims** — show consultation header before reporting complete
- Never name specific frameworks — use platform concepts
- Existing patterns are default; deviation requires justification
- Ground every recommendation in the codebase
- Too broad? Narrow it — deep on one aspect beats shallow on everything
- Flag assumptions explicitly
- Propose, do not mandate

### Quality Gate

Every output must pass before the report is written:

- [ ] Names a specific aesthetic direction; all choices consistent with it
- [ ] Passes every anti-pattern blocklist item from `principles.md`
- [ ] Font choices justified and not on banned list
- [ ] Accessibility shapes choices from Step 1, not checked after
- [ ] All component states addressed or flagged "needs design for [state]"
- [ ] Responsive strategy stated
- [ ] Consultation header shown before claiming complete

### Telemetry
```bash
bash scripts/telemetry.sh design-consult [completed|error]
```

### Error Handling
If any step fails: (1) what failed, (2) what completed, (3) what remains, (4) ask user how to proceed. Never silently continue past failure.
