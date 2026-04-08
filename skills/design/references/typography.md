<!-- Adapted from pbakaus/impeccable (Apache 2.0). Substantially rewritten for FORGE. -->
<!-- last-reviewed: 2026-04 -->

# Typography Reference

Actionable typography patterns for `/design-consult`, `/design-explore`, and `/design-polish`.

## Modular Scale

Use a mathematical scale for type hierarchy. Pick one ratio and derive all sizes from it.

| Ratio | Name | Sizes (base 1rem) |
|-------|------|--------------------|
| 1.125 | Major Second | 0.889, 1, 1.125, 1.266, 1.424 |
| 1.200 | Minor Third | 0.833, 1, 1.2, 1.44, 1.728 |
| 1.250 | Major Third | 0.8, 1, 1.25, 1.563, 1.953 |
| 1.333 | Perfect Fourth | 0.75, 1, 1.333, 1.777, 2.369 |

**Decision tree**: Data-dense UI → Major Second. Editorial/marketing → Perfect Fourth. General app → Minor Third or Major Third.

## Fluid Typography

Use `clamp()` to scale type between viewport sizes without breakpoints:

```
font-size: clamp([min], [preferred], [max]);
```

Common patterns:
- Body: `clamp(1rem, 0.95rem + 0.25vw, 1.125rem)`
- H1: `clamp(2rem, 1.5rem + 2.5vw, 3.5rem)`
- H2: `clamp(1.5rem, 1.25rem + 1.25vw, 2.25rem)`
- Small: `clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem)`

## Vertical Rhythm

Use `line-height` as the base rhythm unit. All spacing (margins, padding, gaps) should be multiples of this unit.

- Body `line-height`: 1.5 (default) to 1.6 (long-form reading)
- Heading `line-height`: 1.1 to 1.3 (tighter — headings need less leading)
- `margin-bottom` on paragraphs: 1 line-height unit
- Space above headings: 2× line-height. Below headings: 0.5-1× line-height.

## Measure (Line Length)

Optimal: 45-75 characters per line. Use `ch` units:

```css
max-width: 65ch;  /* prose */
max-width: 45ch;  /* narrow columns, captions */
max-width: 80ch;  /* code blocks */
```

Lines shorter than 40ch feel choppy. Lines longer than 80ch cause tracking errors.

## Font Selection Checklist

1. **Not on the banned list**: Inter, Roboto, Arial, Space Grotesk as display fonts (principles.md blocklist)
2. **Has the weights you need**: Regular + Bold minimum. Italic if body text. Avoid 6+ weights of one family.
3. **Readable at body size**: Test at 16px / 1rem. If it struggles, it is a display font only.
4. **Supports your character set**: Check Latin Extended, Cyrillic, CJK if relevant.
5. **Has tabular figures**: Essential for data-heavy UIs (`font-variant-numeric: tabular-nums`).

### Better Alternatives to Generic Fonts

| Instead of | Try |
|-----------|-----|
| Inter | Instrument Sans, General Sans, Switzer, Plus Jakarta Sans |
| Roboto | Source Sans 3, IBM Plex Sans, Nunito Sans |
| Open Sans | DM Sans, Outfit, Figtree |
| System sans-serif | Choose deliberately — the "system stack" is fine for body but not for display |

## Font Pairing Principles

- **Contrast, not conflict**: Pair a serif with a sans-serif, or a geometric with a humanist. Two similar fonts fight.
- **One display, one body**: Display font carries personality; body font carries content. Never reverse this.
- **Match x-height**: Fonts with similar x-heights sit well together at the same size.
- **Limit to 2 families**: A third family needs strong justification.

## Web Font Loading

```css
@font-face {
  font-family: "Display";
  src: url("display.woff2") format("woff2");
  font-display: swap;        /* show fallback immediately, swap when loaded */
  font-weight: 400 700;      /* variable font range */
  unicode-range: U+0000-00FF; /* subset to Latin if possible */
}
```

- **`font-display: swap`**: Always. Invisible text is worse than a flash of fallback.
- **Subset aggressively**: Latin-only? Drop Cyrillic/Greek/CJK glyphs. Tools: `glyphhanger`, `subfont`.
- **Preload critical fonts**: `<link rel="preload" href="display.woff2" as="font" crossorigin>`
- **Size-adjust for CLS**: Use `size-adjust`, `ascent-override`, `descent-override` on the fallback to minimize layout shift.

## OpenType Features

Enable selectively — not all fonts support all features:

| Feature | Property | Use case |
|---------|----------|----------|
| `tabular-nums` | `font-variant-numeric: tabular-nums` | Tables, prices, dashboards — aligns digits |
| `lining-nums` | `font-variant-numeric: lining-nums` | Headings — uniform digit height |
| `oldstyle-nums` | `font-variant-numeric: oldstyle-nums` | Body text — digits blend with lowercase |
| `fractions` | `font-variant-numeric: diagonal-fractions` | Recipes, measurements |
| `small-caps` | `font-variant-caps: small-caps` | Labels, abbreviations — NOT for emphasis |
| `ligatures` | `font-variant-ligatures: common-ligatures` | Body text — usually on by default |
| `kerning` | `font-kerning: normal` | Always on for body text |

## Hierarchy Checklist

A type system needs exactly these levels, clearly differentiated:

1. **Display / Hero** — largest, most expressive. Used 1-2× per page max.
2. **Section heading** — organizes major sections. Clear step down from display.
3. **Subsection heading** — organizes within sections. Differentiated by size or weight, not both.
4. **Body** — default reading size. 1rem / 16px minimum.
5. **Small / Caption** — metadata, timestamps, labels. Never below 0.75rem / 12px.

If two levels look similar at a glance, they are not differentiated enough. Increase contrast between them.
