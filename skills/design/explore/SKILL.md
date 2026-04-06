---
name: design-explore
description: "Design variant exploration. Generates multiple design alternatives for comparison. Produces side-by-side variants with tradeoffs to help choose the best approach. Use to compare design alternatives — triggered by 'explore design variants', 'compare design approaches', 'show me design options', 'design alternatives'."
argument-hint: "[design problem or component to explore]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-explore — Variant Exploration

You generate genuinely distinct design alternatives for a given problem, compare them honestly, and let the user choose. Your job is to expand the solution space, not narrow it prematurely.

## Step 1: Scope the Exploration

Parse `$ARGUMENTS` to determine what we are designing variants for. This could be:
- A UI component or layout
- An interaction pattern or user flow
- A data model or schema
- An API surface or endpoint design
- A system architecture component

Read the codebase to understand existing patterns and constraints:

```bash
# Detect project type
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

Identify the boundaries of the exploration: what is fixed (constraints) and what is variable (the design space). State these explicitly before generating variants.

**Fixed** (not up for exploration):
- [list what cannot change]

**Variable** (the design space):
- [list what we are exploring alternatives for]

## Step 2: Generate Variants

Create **3-4 distinct design variants**. Each variant must be genuinely different in approach, not minor tweaks of the same idea.

Guidelines for variant generation:
- Variant A: The conventional/expected approach (what most developers would reach for first)
- Variant B: A pragmatic alternative that makes a different core tradeoff
- Variant C: An unconventional or creative approach (challenge assumptions)
- Variant D (optional): A minimal/constrained approach (what if we had half the budget?)

For each variant, document:

### Variant [Letter]: [Name]
**1-line description**: What makes this variant distinct.

**Design sketch** (ASCII art, pseudocode, or structured outline):
```
[ASCII diagram, component tree, API shape, data flow, or layout sketch]
```

**Key characteristics**:
- [What makes this variant unique — the core idea]
- [Primary structural or behavioral choice]
- [Notable implementation detail]

**Pros**:
- [genuine advantage]
- [genuine advantage]

**Cons**:
- [honest disadvantage]
- [honest disadvantage]

**Best for**: [Which use cases, team sizes, timelines, or constraints favor this variant]

## Step 3: Compare

Create a side-by-side comparison table across key dimensions:

| Dimension | Variant A | Variant B | Variant C | Variant D |
|-----------|-----------|-----------|-----------|-----------|
| Complexity | [low/med/high] | ... | ... | ... |
| Flexibility | [low/med/high] | ... | ... | ... |
| Performance | [low/med/high] | ... | ... | ... |
| Consistency | [how well it fits existing patterns] | ... | ... | ... |
| Accessibility | [WCAG compliance level] | ... | ... | ... |
| Time to implement | [relative estimate] | ... | ... | ... |
| Maintenance burden | [low/med/high] | ... | ... | ... |

## Step 4: Recommend

State which variant you would recommend and why, but frame it as a recommendation, not a decision:

```
Recommendation: Variant [X] — [Name]
Reason: [1-2 sentences explaining why this balances the constraints best]
However: [1 sentence on when you'd choose differently]
```

The user makes the final call. Your recommendation should be well-reasoned but held loosely.

## Step 5: Write Exploration Output

Derive a short topic slug from the design problem (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write the exploration to `.forge/design/explore-[topic].md` with the full variant analysis from Steps 1-4.

Structure:
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
[full variant detail from Step 2]

### Variant B: [Name]
[full variant detail from Step 2]

### Variant C: [Name]
[full variant detail from Step 2]

## Comparison
[table from Step 3]

## Recommendation
[recommendation from Step 4]
```

## Step 6: Report

```
FORGE /design-explore — Complete
Output: .forge/design/explore-[topic].md

Variants: [count] generated
Recommendation: Variant [X] — [Name]
```

## Rules

- Every variant must be genuinely different. If two variants only differ in minor details, merge them or replace one.
- Include at least one unconventional option. The purpose of exploration is to expand thinking, not confirm the obvious choice.
- Do not bias toward the "safe" choice. Present each variant's pros and cons with equal honesty.
- ASCII art is fine for design sketches. Do not apologize for low fidelity.
- If a variant has a fatal flaw, still include it but flag the flaw clearly in cons. Understanding why an approach fails is valuable.
- All variants must meet WCAG AA accessibility. A variant that cannot be made accessible is not a valid variant.
- Ground variants in the actual codebase. A variant that ignores the project's tech stack or existing patterns is not useful.
