<!-- Adapted from pbakaus/impeccable (Apache 2.0). Substantially rewritten for FORGE. -->
<!-- last-reviewed: 2026-04 -->

# Color & Contrast Reference

Actionable color system patterns for `/design-consult`, `/design-explore`, and `/design-polish`.

## OKLCH Color Space

Use OKLCH instead of HSL for perceptually uniform color. In HSL, "50% lightness" varies wildly across hues. In OKLCH, equal lightness values look equally light.

```css
color: oklch(0.7 0.15 250);  /* L: lightness 0-1, C: chroma 0-0.4, H: hue 0-360 */
```

**When to use OKLCH**: Generating color ramps, computing accessible pairs, building palettes where lightness consistency matters. Fall back to hex/rgb for static single-use colors where OKLCH adds no value.

## Tinted Neutrals

Never use pure gray. Add a hint of brand hue to neutrals for cohesion:

```css
/* Pure gray — flat, disconnected */
--neutral-500: oklch(0.55 0 0);

/* Tinted neutral — cohesive, warm */
--neutral-500: oklch(0.55 0.01 250);  /* 0.01 chroma + brand hue */
```

Rule: `chroma: 0.005-0.015` on neutrals. Enough to unify; not enough to notice as "colored."

## Palette Architecture

### Required Roles

| Role | Purpose | Count |
|------|---------|-------|
| **Primary** | Brand identity, primary actions | 1 hue, 5-7 stops |
| **Neutral** | Text, borders, surfaces, backgrounds | 1 tinted ramp, 9-11 stops |
| **Semantic** | Status communication | 4: success (green), warning (amber), error (red), info (blue) |
| **Surface** | Background layers | 3-4 levels (base, raised, overlay, sunken) |

### The 60-30-10 Rule

- **60%** — Neutral surfaces and backgrounds. The canvas.
- **30%** — Secondary color, supporting elements, cards, sections.
- **10%** — Primary/accent. CTAs, active states, key indicators.

Violating this ratio creates visual noise. If accent color exceeds 15%, the design feels loud.

## Contrast Requirements

| Context | Min Ratio | Standard |
|---------|-----------|----------|
| Normal text (< 18pt / < 14pt bold) | 4.5:1 | WCAG AA |
| Large text (≥ 18pt / ≥ 14pt bold) | 3:1 | WCAG AA |
| UI components & graphical objects | 3:1 | WCAG AA |
| Enhanced (all text) | 7:1 | WCAG AAA |

### Dangerous Combinations to Avoid

- Gray text on colored backgrounds — contrast varies unpredictably
- Red text on green (or reverse) — 8% of males have red-green color vision deficiency
- Light text on light backgrounds with only weight for differentiation
- `#000` on `#fff` — technically passes but creates harsh vibration. Use `#1a1a1a` or tinted dark.

### Checking Contrast

Compute contrast in the design phase, not after. When defining a color palette, generate contrast ratios for every text/background pair:

```
text-primary on surface-base → must be ≥ 4.5:1
text-secondary on surface-base → must be ≥ 4.5:1
text-primary on surface-raised → must be ≥ 4.5:1
primary-action on surface-base → must be ≥ 3:1 (UI component)
```

## Dark Mode

Dark mode is NOT inverted light mode. Design principles:

1. **Reduce contrast, don't invert it**: Light mode text at `oklch(0.2 ...)`, dark mode text at `oklch(0.9 ...)` — not `oklch(1.0 ...)`.
2. **Elevate with lightness, not shadows**: Higher surfaces are lighter in dark mode (opposite of light mode shadows).
3. **Desaturate colors slightly**: Full-saturation colors on dark backgrounds vibrate. Reduce chroma by 10-20%.
4. **Test all semantic colors**: Success green, error red, warning amber all need re-evaluation on dark surfaces.
5. **Use `prefers-color-scheme`**: Respect system preference. Offer manual toggle. Never force dark-only.

```css
@media (prefers-color-scheme: dark) {
  :root {
    --surface-base: oklch(0.15 0.01 250);
    --surface-raised: oklch(0.2 0.01 250);
    --text-primary: oklch(0.9 0.01 250);
  }
}
```

## Design Tokens

### Primitive → Semantic Separation

```css
/* Primitives — raw values, never used directly in components */
--blue-500: oklch(0.6 0.2 250);
--blue-600: oklch(0.5 0.2 250);

/* Semantic — intent-based, used in components */
--color-primary: var(--blue-500);
--color-primary-hover: var(--blue-600);
--color-surface-base: var(--neutral-100);
--color-text-primary: var(--neutral-900);
```

Components reference semantic tokens only. Theming swaps primitives underneath.

### Token Naming Convention

`--{category}-{property}-{variant}-{state}`

Examples:
- `--color-text-primary`
- `--color-surface-raised`
- `--color-border-default`
- `--color-action-primary-hover`

## Anti-Pattern Checklist

- [ ] No pure gray (#808080 etc.) — all neutrals tinted
- [ ] No `#000` on `#fff` — use tinted darks and lights
- [ ] No purple-on-white gradient (AI slop fingerprint)
- [ ] No unrelated accent colors — every color traceable to palette
- [ ] No gradients on text
- [ ] No timid even pastels — commit to a confident palette
- [ ] Alpha transparency used sparingly — prefer explicit colors over `rgba()` layering
- [ ] All text/background pairs checked for contrast ratio
- [ ] Dark mode tested with all semantic colors
