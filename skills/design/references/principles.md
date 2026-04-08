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

## AI Design Fingerprints

Common patterns in AI-generated frontends (2024-2025). If your output matches multiple items, it reads as generic AI slop:

- Inter/Roboto as the sole font with no intentional pairing
- Purple-to-blue gradient on white background
- Cards nested inside cards (double elevation)
- Gray text on colored backgrounds (unpredictable contrast)
- Uniform card grids with identical spacing and no hierarchy
- Skeleton screens more complex than the actual loaded content
- "Micro-interactions" that serve no informational purpose (wobble on hover, pulse on idle)
- Excessive border-radius (fully rounded everything)
- Glassmorphism without contrast fallback
- Stock illustration style (flat, purple-haired characters)
- Every section full-width with alternating background colors

The anti-pattern blocklist (above) catches most of these. This section names the compound pattern: several mild violations together create an unmistakably AI-generated feel.

## Usability Heuristics Checklist

Based on Nielsen's 10 heuristics. Use as a structured review framework — evaluate each, do not score numerically.

1. **Visibility of system status** — Does the user always know what is happening? Loading indicators, progress, confirmations.
2. **Match between system and real world** — Does the UI use the user's language and concepts? Logical order, familiar icons.
3. **User control and freedom** — Can the user undo, go back, escape? Emergency exits at every stage.
4. **Consistency and standards** — Same action, same result everywhere? Platform conventions respected.
5. **Error prevention** — Are dangerous actions guarded? Constraints that prevent errors before they happen.
6. **Recognition rather than recall** — Are options visible? Labels, breadcrumbs, recent items — minimize memory load.
7. **Flexibility and efficiency of use** — Are there accelerators for experts? Keyboard shortcuts, bulk actions, defaults.
8. **Aesthetic and minimalist design** — Does every element earn its place? No irrelevant or rarely needed information.
9. **Help users recognize, diagnose, and recover from errors** — Are error messages specific? What happened, why, how to fix.
10. **Help and documentation** — Is help available in context? Searchable, task-oriented, concise.

Severity levels (use existing FORGE levels, not numeric scores): **Critical** (blocks usage), **Major** (fix before shipping), **Minor** (fix when convenient), **Suggestion** (enhancement).

## Review Angles

Five perspectives to stress-test a design. Evaluate from each angle; do not create persona fiction.

1. **Power user efficiency** — Can an expert complete tasks quickly? Are there shortcuts, bulk operations, keyboard access?
2. **First-time clarity** — Can a newcomer understand what to do without instruction? Is the onboarding progressive?
3. **Accessibility compliance** — Can a screen reader user, keyboard-only user, or user with low vision operate this? (See Accessibility Baseline above.)
4. **Edge case resilience** — What happens with empty data, long strings, API errors, slow connections, unexpected input?
5. **Mobile/touch usability** — Does this work on a phone with one thumb? Touch targets adequate? No hover-dependent functionality?
