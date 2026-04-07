# Design Principles & Anti-Patterns

Shared reference for `/design` sub-skills.

## Principles

1. **Commit to a direction** — strong aesthetic identity over safe/generic defaults
2. **Frame before you build** — purpose, audience, tone, one memorable thing
3. **Anti-patterns beat positive guidance** — what NOT to do breaks convergence
4. **Accessibility shapes decisions** — WCAG AA minimum, baked in from step 1
5. **Every state is a design opportunity** — loading, error, empty matter equally
6. **Motion must earn its place** — reveal hierarchy, stage info, reinforce actions
7. **Performance is a design constraint** — font loading, animation budgets, layout shift
8. **Copy quality is design quality** — active voice, specific labels, errors with next steps
9. **Respect user preferences** — reduced motion, color scheme, zoom, locale
10. **Stateful views should be addressable** — deep-linkable where platform supports it

## Aesthetic Direction Catalog

Offered, not mandated. Define a custom direction if none fits.

| Direction | Description |
|---|---|
| Brutally minimal | Raw structure; no decoration; harsh contrast; content dominates |
| Editorial | Dramatic type scale; generous whitespace; reading-focused |
| Industrial | Monospaced type; exposed grid; muted palette; data-dense |
| Luxury | Refined serif; restrained color; negative space; subtle motion |
| Playful | Rounded shapes; vibrant color; bouncy motion; personality-forward |
| Geometric | Precise shapes; mathematical spacing; bold primaries; grid-locked |
| Retro-futurist | Neon on dark; scanline textures; sci-fi type; terminal aesthetic |
| Soft organic | Rounded corners; earth tones; gentle gradients; calm |
| Maximalist | Dense layers; mixed type; rich textures; sensory overload by design |
| Swiss minimal | Grotesque sans-serif; strict grid; black/white dominant |
| Glassmorphism | Frosted panels; translucency; soft shadows; backdrop blur |
| OLED luxury | True black bg; glowing accents; cinematic; OLED power-efficient |

## Anti-Pattern Blocklist

`[web]` = web-specific; adapt for other platforms.

**Typography**: Inter/Roboto/Arial/Space Grotesk as display fonts | generic system stacks as sole choice | 6+ weights of one family | uppercase on body text `[web]` | three dots instead of ellipsis

**Color**: purple-on-white gradient | random unrelated accents | timid even pastels | #000 on #fff | gradients on text

**Layout**: uniform identical card grids | everything centered | SaaS hero templates | arbitrary z-index `[web]`

**Motion**: animation because it was easy | bounce easing everywhere | `transition: all` `[web]` | auto-play without pause/reduced-motion

**Content & Copy**: "Click here"/"Submit" labels | errors without next step | straight quotes | placeholder text in production

**Interaction**: div/span as buttons `[web]` | `outline:none` without `:focus-visible` `[web]` | disabled zoom `[web]` | disappearing input labels

**Images & Media**: no alt text | hero images 60%+ viewport with no value | decorative elements not hidden

**Forms**: no required-field indicators | validation only on submit | generic submit labels

## Accessibility Baseline (WCAG AA)

Contrast 4.5:1 (3:1 large) | keyboard navigable | semantic markup first `[web]` | visible focus, logical order | respect reduced-motion/color-scheme/zoom | 44dp touch targets | color not sole indicator | cognitive: consistent nav, error prevention, clear reading level

## State Coverage

Every interactive component: default, hover, focus, active, disabled, loading, error, empty, partial-data, skeleton.

## Design Tokens

Semantic names (`color-primary` not `blue-500`) | primitive vs semantic separation | theme-able via tokens | hierarchy: global > category > component
