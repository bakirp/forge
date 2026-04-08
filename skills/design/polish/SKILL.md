---
name: design-polish
description: "Final visual polish pass before shipping — a narrow 6-check quality sweep for typography, color, spacing, motion, states, and copy. Use as the last design step before /ship — triggered by 'polish the design', 'final design pass', 'visual cleanup', 'design polish'."
argument-hint: "[file paths, component names, or directory to polish]"
allowed-tools: Read Grep Glob Bash Write Edit
---

# /design-polish — Final Visual Polish

You are the last design pass before `/ship`. You check 6 specific dimensions, fix what you find, and report. This is NOT a review — you make changes, not judgments.

**Pipeline position**: After `/build` and `/design-review`. Run this when the design has been reviewed and approved but needs a final cleanup before shipping.

## Step 0: Load References

Read these references for specific values and patterns:
- `skills/design/references/principles.md` — anti-pattern blocklist, state coverage
- `skills/design/references/typography.md` — modular scales, fluid patterns, font loading
- `skills/design/references/color-and-contrast.md` — OKLCH, contrast ratios, tinted neutrals

Parse `$ARGUMENTS` to identify targets. Read the design direction artifact if it exists:
```bash
ls .forge/design/consult-*.md 2>/dev/null | head -1
```

## Check 1: Typography Rendering

- [ ] Type scale follows a consistent mathematical ratio (modular scale from typography.md)
- [ ] Line lengths within 45-75ch for body text
- [ ] Heading hierarchy is visually clear — each level distinct from the next
- [ ] No orphaned words (single word on last line of a heading)
- [ ] `font-display: swap` on all custom fonts
- [ ] `tabular-nums` on number columns, prices, timestamps

**Fix**: Adjust font sizes, line lengths, add `font-variant-numeric` where needed.

## Check 2: Color Consistency

- [ ] All colors trace to design tokens (no inline hex values outside token definitions)
- [ ] Contrast meets WCAG AA on every text/background pair (4.5:1 normal, 3:1 large)
- [ ] Neutrals are tinted (not pure gray)
- [ ] Dark mode tested — colors desaturated, elevation by lightness
- [ ] No stray colors outside the palette

**Fix**: Replace inline colors with tokens, adjust contrast ratios, tint neutrals.

## Check 3: Spacing Rhythm

- [ ] Spacing values from a consistent scale (4pt grid or defined spacing tokens)
- [ ] No arbitrary magic numbers — every spacing value traceable to the scale
- [ ] Vertical rhythm maintained (margins/padding as multiples of line-height)
- [ ] Consistent gap values in grids and flex layouts
- [ ] Adequate whitespace around section boundaries

**Fix**: Replace arbitrary values with scale-based tokens.

## Check 4: Motion Quality

- [ ] All transitions use defined easing curves (ease-out-quart/quint/expo, not `ease` or `linear`)
- [ ] Durations in correct ranges (100-150ms micro, 200-300ms standard, 300-500ms complex)
- [ ] No `transition: all` — every transition specifies exact properties
- [ ] Only `transform` and `opacity` animated (exceptions: `color`/`background-color` on hover)
- [ ] `prefers-reduced-motion` fallback present for every animation
- [ ] Stagger delays ≤ 50ms per item, ≤ 500ms total

**Fix**: Replace easing curves, adjust durations, add reduced-motion fallbacks, specify transition properties.

## Check 5: State Completeness

- [ ] Every interactive component has: default, hover (pointer only), focus (`:focus-visible`), active
- [ ] Disabled states have `aria-disabled` and visual treatment (opacity 0.4-0.5)
- [ ] Loading states replace labels, not entire components — layout stays stable
- [ ] Error states include message with next step (not just red border)
- [ ] Empty states are designed (not blank), with guidance or action

**Fix**: Add missing state styles, improve error messages, design empty states.

## Check 6: Copy Quality

- [ ] Button labels are specific verbs ("Create Account" not "Submit")
- [ ] Error messages follow formula: what happened + why + how to fix
- [ ] No placeholder text in production
- [ ] Ellipsis character (…) not three dots (...)
- [ ] No "Click here" or "Learn more" without context
- [ ] Loading copy is specific ("Saving changes..." not "Loading...")

**Fix**: Rewrite labels, error messages, and placeholder copy.

## Write Report

Derive a topic slug (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/polish-[topic].md`:

```markdown
# Design Polish: [Topic]
Date: [YYYY-MM-DD]

## Changes Made

### Typography
- [change with file:line, or "No changes needed"]

### Color
- [change with file:line, or "No changes needed"]

### Spacing
- [change with file:line, or "No changes needed"]

### Motion
- [change with file:line, or "No changes needed"]

### States
- [change with file:line, or "No changes needed"]

### Copy
- [change with file:line, or "No changes needed"]

## Summary
[Total changes] fixes across [dimensions touched] dimensions.
```

Show the report header as evidence, then report:

```
FORGE /design-polish — Complete
Output: .forge/design/polish-[topic].md
Changes: [count] fixes across [n] dimensions
```

## Rules

- **Make changes, don't just report.** This is a polish pass, not a review. Fix what you find.
- **Respect the design direction.** Read the consult artifact. Do not change aesthetic choices — only fix execution quality.
- **Small fixes only.** If a fix requires structural changes, note it but do not execute — that belongs in a new `/design-consult` or `/build` cycle.
- **Evidence before claims** — show the report header before reporting complete.
- **Do not expand scope.** 6 checks only. If you find issues outside these dimensions, note them in the report but do not fix them.

### Telemetry
```bash
bash scripts/telemetry.sh design-polish [completed|error]
```

### Error Handling
If any step fails: (1) what failed, (2) what completed, (3) what remains, (4) ask user how to proceed. Never silently continue past failure.
