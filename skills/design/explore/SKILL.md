---
name: design-explore
description: "Variant exploration with aesthetic direction differentiation. Generates 3-4 distinct alternatives validated against the anti-pattern blocklist, compares across measurable dimensions, and recommends. Use to expand the solution space — triggered by 'explore design variants', 'compare design approaches', 'show me design options'."
argument-hint: "[design problem or component to explore]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-explore — Variant Exploration

You generate genuinely distinct design alternatives, compare them honestly, and let the user choose. Expand the solution space — do not confirm the obvious choice.

## Step 1: Scope the Exploration

Parse `$ARGUMENTS`. Read the codebase for existing patterns and constraints:

```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

Read these references:
- `skills/design/references/principles.md` — anti-pattern blocklist, aesthetic catalog, AI fingerprints
- `skills/design/references/typography.md` — font selection, modular scales, fluid patterns
- `skills/design/references/color-and-contrast.md` — OKLCH palettes, contrast, tinted neutrals

State boundaries before generating anything:

**Fixed**: [platform, existing patterns, accessibility requirements, integration points]

**Variable**: [what differs across variants — layout, interaction model, hierarchy, visual treatment]

## Step 2: Generate Variants

You create **3-4 genuinely distinct variants**. Each SHOULD commit to a different aesthetic direction from the catalog in `principles.md` where the problem maps naturally. If it does not, variants can differ in other ways — direction is offered, not forced.

Validate each variant against the anti-pattern blocklist during generation. Fix blocklist violations before including a variant.

For each variant:

### Variant [Letter]: [Name]
**Aesthetic direction**: [from catalog or custom]

**Design language**: Type [family + modular scale ratio + clamp() range] | Color [OKLCH palette + contrast ratios] | Spacing [grid unit + density] | Motion [easing curve + duration range]

**Key characteristics**:
- [Core idea — what makes this distinct]
- [Primary structural or behavioral choice]
- [State coverage — loading, error, empty handling]

**Pros**: [genuine advantages]
**Cons**: [honest disadvantages — no softening]
**Best for**: [use cases, constraints, timelines favoring this]

## Step 3: Compare

You build a side-by-side comparison table:

| Dimension | Variant A | Variant B | Variant C | Variant D |
|---|---|---|---|---|
| Complexity | low/med/high | ... | ... | ... |
| Flexibility | low/med/high | ... | ... | ... |
| Accessibility | WCAG level + notes | ... | ... | ... |
| Aesthetic distinctiveness | commitment strength | ... | ... | ... |
| State coverage | completeness | ... | ... | ... |
| Time to implement | relative estimate | ... | ... | ... |
| Maintenance burden | low/med/high | ... | ... | ... |

Assess honestly. Do not inflate the recommended variant or deflate others.

## Step 4: Recommend

You state your recommendation, held loosely:

```
Recommendation: Variant [X] — [Name]
Reason: [1-2 sentences on why this balances constraints best]
When I'd choose differently: [context shift that would change this pick]
```

The user makes the final call.

## Step 5: Write Output + Report

Derive a topic slug (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/explore-[topic].md`:

```markdown
# Design Exploration: [Topic]
Date: [YYYY-MM-DD]

## Scope
### Fixed
- [constraint]
### Variable
- [what we are exploring]

## Variants
### Variant A: [Name]
[direction, design language, characteristics, pros, cons, best-for]

### Variant B: [Name]
...

## Comparison
[table from Step 3]

## Recommendation
[from Step 4]
```

Show the exploration file header, then report:

```
FORGE /design-explore — Complete
Output: .forge/design/explore-[topic].md

Variants: [count] generated
Recommendation: Variant [X] — [Name]
```

## Rules

- Every variant names its aesthetic direction and makes consistent choices. Type, color, spacing, and motion must not contradict the stated direction.
- Every variant passes the anti-pattern blocklist from `principles.md`. Validate during generation, not after.
- Variants are genuinely different. If two differ only in minor details, merge or replace.
- At least one unconventional option included.
- All variants meet WCAG AA. A variant that cannot be made accessible is not valid.
- No bias toward the "safe" choice. Present pros and cons with equal honesty.
- **Evidence before claims** — show the exploration file header before reporting complete.
- Ground variants in the actual codebase. Ignoring project patterns makes a variant useless.
- Fatal flaws: still include the variant but flag clearly in cons.
- Never name specific frameworks, libraries, or CSS utilities. Use platform concepts.
