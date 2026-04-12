---
name: design-polish
description: "Final visual polish pass before shipping — a narrow 6-check quality sweep for typography, color, spacing, motion, states, and copy. Use as the last design step before /ship — triggered by 'polish the design', 'final design pass', 'visual cleanup', 'design polish'."
argument-hint: "[file paths, component names, or directory to polish]"
allowed-tools: Read Grep Glob Bash Write Edit
---

# /design-polish — Final Visual Polish

You make changes, not judgments — a 6-check sweep after `/design-review`, before `/ship`.

## Step 0: Load References

Read `skills/design/references/principles.md`, `typography.md`, `color-and-contrast.md`. Parse `$ARGUMENTS` for targets. Read consult artifact if present (`ls .forge/design/consult-*.md 2>/dev/null | head -1`).

## Check 1: Typography Rendering

- [ ] Type scale follows consistent mathematical ratio
- [ ] Line lengths 45-75ch for body text
- [ ] `font-display: swap` on all custom fonts
- [ ] `tabular-nums` on number columns, prices, timestamps

**Fix**: Adjust font sizes, line lengths, add `font-variant-numeric` where needed.

## Check 2: Color Consistency

- [ ] All colors trace to design tokens (no inline hex outside token defs)
- [ ] Contrast meets WCAG AA (4.5:1 normal, 3:1 large)
- [ ] Neutrals are tinted (not pure gray)
- [ ] Dark mode colors desaturated, elevation by lightness

**Fix**: Replace inline colors with tokens, adjust contrast, tint neutrals.

## Check 3: Spacing Rhythm

- [ ] Spacing values from consistent scale (4pt grid or tokens)
- [ ] No arbitrary magic numbers
- [ ] Vertical rhythm maintained (margins/padding as multiples of line-height)

**Fix**: Replace arbitrary values with scale-based tokens.

## Check 4: Motion Quality

- [ ] Defined easing curves (ease-out-quart/quint/expo, not `ease`/`linear`)
- [ ] Correct durations (100-150ms micro, 200-300ms standard, 300-500ms complex)
- [ ] No `transition: all` — specify exact properties; only `transform`/`opacity` animated
- [ ] `prefers-reduced-motion` fallback for every animation

**Fix**: Replace easing curves, adjust durations, add reduced-motion fallbacks.

## Check 5: State Completeness

- [ ] Every interactive component has: default, hover, focus (`:focus-visible`), active
- [ ] Disabled states use `aria-disabled` + visual treatment (opacity 0.4-0.5)
- [ ] Loading states replace labels, not components — layout stays stable
- [ ] Error states include message with next step (not just red border)

**Fix**: Add missing state styles, improve error messages, design empty states.

## Check 6: Copy Quality

- [ ] Button labels are specific verbs ("Create Account" not "Submit")
- [ ] Error messages: what happened + why + how to fix
- [ ] No placeholder text in production
- [ ] Loading copy is specific ("Saving changes..." not "Loading...")

**Fix**: Rewrite labels, error messages, and placeholder copy.

## Write Report

Derive a topic slug. Run `mkdir -p .forge/design`. Write to `.forge/design/polish-[topic].md` with one section per check (changes with `file:line` or "No changes needed") and summary with total fixes and dimensions touched.

```
FORGE /design-polish — Complete
Output: .forge/design/polish-[topic].md
Changes: [count] fixes across [n] dimensions
```

## Rules

- **Quality gate** — all 6 checks must pass before reporting complete. Make changes, don't just report.
- Respect design direction from consult artifact — fix execution quality, not aesthetic choices.
- Small fixes only — structural changes deferred to `/design-consult` or `/build`.
- Evidence before claims — show actual output, not summaries.

## What's Next

`/ship` when done | `/design review` if extensive polish was applied.

Follow `skills/shared/compliance-telemetry.md` (`design-polish`). Keys: `direction-changed` (major) — aesthetic change; `structural-change` (major) — should be deferred; `scope-expanded` (minor) — beyond 6 dimensions. Follow `skills/shared/rules.md`. Log violations via `scripts/compliance-log.sh`.
