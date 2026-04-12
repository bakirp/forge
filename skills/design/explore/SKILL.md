---
name: design-explore
description: "Variant exploration with aesthetic direction differentiation. Generates 3-4 distinct alternatives validated against the anti-pattern blocklist, compares across measurable dimensions, and recommends. Use to expand the solution space — triggered by 'explore design variants', 'compare design approaches', 'show me design options'."
argument-hint: "[design problem or component to explore]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-explore — Variant Exploration

Generate genuinely distinct alternatives — expand the solution space, do not confirm the obvious choice.

## Step 1: Scope the Exploration

Parse `$ARGUMENTS`. Scan codebase for existing patterns and constraints:
```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

Read references: `skills/design/references/principles.md` (anti-patterns, aesthetic catalog, AI fingerprints), `typography.md`, `color-and-contrast.md`.

State boundaries: **Fixed** (platform, existing patterns, a11y requirements, integration points) vs **Variable** (layout, interaction model, hierarchy, visual treatment).

## Step 2: Generate Variants

Create **3-4 genuinely distinct variants**, each committing to a different aesthetic direction from the catalog in `principles.md`. Validate each against the anti-pattern blocklist during generation.

For each variant:

### Variant [Letter]: [Name]
**Direction**: [from catalog or custom] | **Design language**: Type [family + scale + clamp()] | Color [OKLCH palette + contrast] | Spacing [grid + density] | Motion [easing + duration]

**Key characteristics**: Core idea (what makes this distinct), primary structural choice, state coverage (loading/error/empty handling)

**Pros**: genuine advantages | **Cons**: honest disadvantages — no softening | **Best for**: use cases favoring this

## Step 3: Compare

Build a side-by-side comparison table:

| Dimension | Variant A | Variant B | Variant C | Variant D |
|---|---|---|---|---|
| Complexity | low/med/high | ... | ... | ... |
| Flexibility | low/med/high | ... | ... | ... |
| Accessibility | WCAG level + notes | ... | ... | ... |
| Aesthetic distinctiveness | commitment strength | ... | ... | ... |
| State coverage | completeness | ... | ... | ... |
| Time to implement | relative estimate | ... | ... | ... |
| Maintenance burden | low/med/high | ... | ... | ... |

Assess honestly — do not inflate the recommended variant or deflate others.

## Step 4: Recommend

State recommendation, held loosely:
```
Recommendation: Variant [X] — [Name]
Reason: [1-2 sentences on why this balances constraints best]
When I'd choose differently: [context shift that would change this pick]
```

## Step 5: Write Output + Report

Derive topic slug (lowercase, hyphens, max 4 words). Write to `.forge/design/explore-[topic].md` with sections: Scope (Fixed/Variable), Variants (direction, design language, characteristics, pros/cons/best-for), Comparison table, Recommendation.

```bash
mkdir -p .forge/design
```

Report:
```
FORGE /design-explore — Complete
Output: .forge/design/explore-[topic].md
Variants: [count] generated
Recommendation: Variant [X] — [Name]
```

## Rules

- Every variant names its aesthetic direction with consistent type, color, spacing, and motion choices
- Every variant passes the anti-pattern blocklist — validate during generation, not after
- Variants must be genuinely different; if two differ only in minor details, merge or replace
- At least one unconventional option; all variants meet WCAG AA
- No bias toward the "safe" choice — equal honesty in pros and cons
- Ground variants in the actual codebase; fatal flaws: include but flag in cons
- Never name specific frameworks — use platform concepts

> **Compliance, telemetry, error handling, and what's-next routing**: see `skills/shared/compliance-telemetry.md`, `skills/shared/rules.md`, and `skills/shared/workflow-routing.md`.
> Log violations via `scripts/compliance-log.sh`. Keys: `duplicate-variants` (major), `no-unconventional` (minor), `accessibility-fail` (major).
> Recommended next: `/design review`. Alternative: `/architect` if a clear winner emerged.
