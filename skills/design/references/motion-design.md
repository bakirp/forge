<!-- Adapted from pbakaus/impeccable (Apache 2.0). Substantially rewritten for FORGE. -->
<!-- last-reviewed: 2026-04 -->

# Motion Design Reference

Actionable motion patterns for `/design-consult`, `/design-explore`, and `/design-polish`.

## Duration Ranges

| Category | Duration | Use case |
|----------|----------|----------|
| **Micro** | 100-150ms | Hover effects, toggles, icon state changes — must feel instant |
| **Standard** | 200-300ms | Button presses, dropdown opens, tab switches — deliberate but brisk |
| **Complex** | 300-500ms | Modal opens, panel slides, accordion expands — structural changes |
| **Entrance** | 500-800ms | Page sections loading, hero animations — first-impression moments |

**Rule**: If it feels sluggish, it is too long. If you cannot see it happen, it is too short. When in doubt, use the lower end of the range.

## Easing Curves

### Use These

| Easing | CSS | When |
|--------|-----|------|
| **ease-out-quart** | `cubic-bezier(0.25, 1, 0.5, 1)` | Default for most transitions. Element arrives and settles. |
| **ease-out-quint** | `cubic-bezier(0.22, 1, 0.36, 1)` | Slightly more dramatic arrival. Modals, panels. |
| **ease-out-expo** | `cubic-bezier(0.16, 1, 0.3, 1)` | Maximum drama. Hero entrances, page transitions. |
| **ease-in-out-quart** | `cubic-bezier(0.76, 0, 0.24, 1)` | Symmetric motion. Toggles, switches, looping animations. |
| **linear** | `linear` | Progress bars, continuous rotation, opacity-only fades. |

### Never Use These

| Easing | Why |
|--------|-----|
| **bounce** | Feels dated (2015 Material Design era). Draws attention without informational value. |
| **elastic** | Same problem. Playful in isolation, distracting in a real UI. |
| **ease** (CSS default) | Too generic. Does not commit to a motion personality. |
| **ease-in** alone | Objects that accelerate away feel like they are escaping. Only valid as the first half of an ease-in-out. |

## What to Animate

### Safe Properties (GPU-composited)

Only animate `transform` and `opacity`. These run on the compositor thread and do not trigger layout or paint:

```css
/* Good — compositor only */
transform: translateY(8px);
opacity: 0;

/* Bad — triggers layout */
height: 0; margin-top: 0; top: 0; left: 0;

/* Bad — triggers paint */
background-color: red; box-shadow: 0 4px 8px; border-radius: 8px;
```

**Exception**: `color` and `background-color` transitions are acceptable for hover/focus states at micro durations (100-150ms) where the paint cost is negligible.

## Staggered Animations

For lists and grids, stagger entrance timing with CSS custom properties:

```css
.item {
  animation: fadeSlideIn 300ms ease-out-quart both;
  animation-delay: calc(var(--i) * 50ms);
}

/* Set --i per item: 0, 1, 2, 3... */
```

Rules:
- **Max stagger**: 50ms per item. Longer feels sluggish.
- **Max total stagger**: 500ms. Cap at 10 items; beyond that, animate in batches.
- **Direction**: Top-to-bottom or leading-edge-to-trailing. Never random.

## Entrance Patterns

| Pattern | CSS (simplified) | Best for |
|---------|-------------------|----------|
| Fade up | `opacity: 0 → 1` + `translateY(8px) → 0` | Cards, list items, sections |
| Fade in | `opacity: 0 → 1` | Subtle elements, overlays |
| Scale up | `opacity: 0 → 1` + `scale(0.95) → 1` | Modals, popovers, tooltips |
| Slide in | `translateX(-100%) → 0` | Drawers, side panels |

**Starting offset**: Keep `translateY` values small (4-12px). Large offsets (20px+) feel heavy and draw too much attention.

## Reduced Motion

Every animation must have a `prefers-reduced-motion` fallback:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**Or per-element**: Replace motion with opacity-only transitions. Do not simply remove all transitions — users who prefer reduced motion still benefit from state change indicators.

```css
@media (prefers-reduced-motion: reduce) {
  .modal {
    /* Remove slide, keep fade */
    animation: fadeIn 150ms ease-out both;
  }
}
```

## View Transitions API

For page-level transitions in SPAs and MPAs:

```css
::view-transition-old(root) {
  animation: fadeOut 200ms ease-out-quart;
}
::view-transition-new(root) {
  animation: fadeIn 200ms ease-out-quart;
}
```

Assign `view-transition-name` to elements that persist across views for shared-element transitions. Each name must be unique per page.

## Scroll-Driven Animations

Tie animation progress to scroll position instead of time:

```css
.parallax {
  animation: slideUp linear both;
  animation-timeline: view();
  animation-range: entry 0% cover 50%;
}
```

Use sparingly. Scroll-driven animations should enhance spatial understanding, not decorate.

## Anti-Pattern Checklist

- [ ] No `transition: all` — always specify exact properties
- [ ] No bounce or elastic easing
- [ ] No animation on layout properties (height, width, margin, top/left)
- [ ] No auto-play video/animation without pause control
- [ ] No animation without `prefers-reduced-motion` fallback
- [ ] No stagger exceeding 500ms total
- [ ] No entrance offsets larger than 12px
- [ ] Every animation earns its place — if removing it changes nothing, remove it
