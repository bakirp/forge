<!-- Adapted from pbakaus/impeccable (Apache 2.0). Substantially rewritten for FORGE. -->
<!-- last-reviewed: 2026-04 -->

# Responsive Design Reference

Actionable responsive patterns for `/design-audit` and design skills that define layout behavior.

## Content-Driven Breakpoints

Do not use device-based breakpoints (320px, 768px, 1024px). Use breakpoints where the content breaks:

```css
/* Bad — device-based */
@media (min-width: 768px) { ... }

/* Good — content-driven */
@media (min-width: 40em) { ... }  /* where sidebar content becomes cramped */
```

Use `em` for breakpoints (respects user font size preferences). Start mobile-first: base styles for small screens, `min-width` queries to add complexity.

### Common Breakpoint Ranges

| Range | Typical use | Approach |
|-------|-------------|----------|
| < 30em | Single column, stacked | Base styles |
| 30-50em | 2-column options, side-by-side | First breakpoint |
| 50-70em | Full layout, sidebars, multi-column | Second breakpoint |
| 70em+ | Max-width container, wider gutters | Third breakpoint (often the last) |

Most designs need 2-3 breakpoints. If you need more than 4, the layout is too rigid.

## Container Queries

Respond to a component's container size instead of viewport size:

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { flex-direction: row; }
}

@container card (max-width: 399px) {
  .card { flex-direction: column; }
}
```

**When to use**: Components that appear in different layout contexts (sidebar vs main content, dashboard grid vs full-width). Container queries make components self-adaptive.

**When viewport queries are still correct**: Page-level layout changes (sidebar visibility, navigation pattern).

## Fluid Layout Patterns

### Self-Adjusting Grids

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--spacing-4);
}
```

The grid adjusts column count automatically. No breakpoints needed. Choose `minmax` minimum based on content: cards → 280px, thumbnails → 160px, data cells → 200px.

`auto-fit` vs `auto-fill`: Use `auto-fit` (stretches items to fill space). Use `auto-fill` only when you want empty columns to remain as gaps.

### Fluid Spacing

```css
gap: clamp(1rem, 2vw, 2rem);
padding: clamp(1rem, 4vw, 3rem);
```

Spacing scales with viewport. Avoids jarring spacing jumps at breakpoints.

## Input Method Detection

Different input methods need different UI:

```css
/* Hover effects — only for devices that support hover */
@media (hover: hover) and (pointer: fine) {
  .interactive:hover { background: var(--surface-hover); }
}

/* Touch devices — larger targets */
@media (pointer: coarse) {
  .button { min-height: 48px; min-width: 48px; }
  .nav-item { padding: 12px 16px; }
}

/* Keyboard-focused — ensure focus styles are prominent */
@media (hover: none) {
  :focus-visible { outline-width: 3px; }
}
```

Never assume touch = mobile. Laptops have touchscreens. Tablets have keyboards.

## Safe Areas

Handle device notches and system UI:

```css
body {
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
  padding-left: env(safe-area-inset-left);
  padding-right: env(safe-area-inset-right);
}
```

Required for: fixed/sticky elements at screen edges, bottom navigation bars, full-bleed layouts.

Add `viewport-fit=cover` to the viewport meta tag to enable:
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

## Responsive Images

```html
<!-- Resolution switching — same image, different sizes -->
<img
  srcset="photo-400.webp 400w, photo-800.webp 800w, photo-1200.webp 1200w"
  sizes="(max-width: 600px) 100vw, (max-width: 1000px) 50vw, 33vw"
  src="photo-800.webp"
  alt="Description"
  loading="lazy"
  decoding="async"
>

<!-- Art direction — different crops per viewport -->
<picture>
  <source media="(max-width: 600px)" srcset="hero-mobile.webp">
  <source media="(max-width: 1000px)" srcset="hero-tablet.webp">
  <img src="hero-desktop.webp" alt="Description">
</picture>
```

- Always include `alt` text
- Use `loading="lazy"` for below-fold images
- Use `decoding="async"` to avoid blocking rendering
- Prefer WebP/AVIF with JPEG fallback

## Layout Adaptation Patterns

### Navigation

| Viewport | Pattern |
|----------|---------|
| Small | Hamburger menu or bottom tab bar |
| Medium | Collapsed sidebar or horizontal nav with overflow scroll |
| Large | Full horizontal nav or persistent sidebar |

### Data Tables

| Viewport | Pattern |
|----------|---------|
| Small | Stack rows as cards, or horizontal scroll with sticky first column |
| Medium | Collapse less important columns, show on expand |
| Large | Full table |

### Forms

| Viewport | Pattern |
|----------|---------|
| Small | Single column, full-width inputs |
| Medium | Two-column for related fields (first/last name) |
| Large | Same as medium, wider max-width |

## Anti-Pattern Checklist

- [ ] No fixed widths on content containers — use `max-width` + fluid widths
- [ ] No horizontal scroll on the main axis (exceptions: data tables, carousels with indication)
- [ ] No hidden functionality on small screens — adapt, don't remove
- [ ] No text smaller than 16px on mobile (prevents iOS zoom on input focus)
- [ ] No device-based breakpoints — use content-driven ones
- [ ] No `overflow: hidden` on body (breaks scrolling on some devices)
- [ ] No viewport units (`vh`) for full-height without `dvh` fallback (mobile address bar)
- [ ] Touch targets ≥ 44×44px
- [ ] Zoom not disabled (`user-scalable=no` is an accessibility violation)
- [ ] Images have responsive `srcset` or fluid sizing
