---
name: design-audit
description: "Technical design quality audit — scores accessibility, responsiveness, interaction completeness, and anti-pattern density. Use to measure design quality across dimensions — triggered by 'audit the design', 'check design quality', 'design score', 'how good is the design', 'accessibility audit'."
argument-hint: "[file paths, component names, or directory to audit]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-audit — Technical Design Quality Audit

You measure design quality across technical dimensions and produce a scored report. You are the instrument, not the gate — `/design-review` decides ship-readiness.

## Step 1: Identify Targets

Parse `$ARGUMENTS` for targets. Read design context and references (`skills/design/references/principles.md`, `interaction-design.md`, `responsive-design.md`).

```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

## Step 2: Accessibility

| Check | What to look for |
|-------|------------------|
| Contrast | 4.5:1 normal text, 3:1 large text / UI components |
| Keyboard | All interactive elements reachable, logical tab order, no tabindex > 0 |
| Semantic HTML | `<button>` not `<div onclick>`, proper landmarks, headings in order |
| Focus | `:focus-visible` styles, focus trapped in modals, returned on close |
| ARIA | `aria-label` where needed, `aria-live` for dynamic content |
| Forms | Labels associated, validation on blur, descriptive errors |
| Alt text | All `<img>` have `alt`, decorative images `alt=""` or `aria-hidden` |
| Motion | `prefers-reduced-motion` respected, no auto-play without pause |
| Touch | Interactive targets >= 44x44px |
| Zoom | `user-scalable` not disabled, layout works at 200% zoom |

## Step 3: Responsiveness

| Check | What to look for |
|-------|------------------|
| Breakpoints | Content-driven (`em`), not device-based (px), 2-4 max |
| Fluid layout | `auto-fit`/`auto-fill` grids, `clamp()` spacing, no fixed widths |
| Container queries | Components adapt to container, not viewport |
| Mobile text | No text < 16px, readable line lengths |
| Navigation | Adapts per viewport (hamburger / horizontal / sidebar) |
| Images | `srcset` or fluid sizing, `loading="lazy"` below fold |
| Safe areas | `env(safe-area-inset-*)` where needed |
| No overflow | No unintended horizontal scroll |

## Step 4: Interaction Completeness

For each interactive component, check the 8-state model: default, hover, focus, active, disabled, loading, error, success. Mark each: check/x/dash. Also verify: focus order matches visual order, destructive actions use undo not confirmation, forms validate on blur, modals use `<dialog>` with focus management.

## Step 5: Anti-Pattern Density

Run the full blocklist from `principles.md` across all targets. Count matches per category (Typography, Color, Layout, Motion, Content, Interaction, Images, Forms, AI Fingerprints). Cite every match with `file:line`.

## Step 6: Performance

| Check | What to look for |
|-------|------------------|
| Font loading | `font-display: swap`, subset fonts, <= 3 font files |
| Animation | Only `transform`/`opacity` animated, no `transition: all` |
| Images | WebP/AVIF with fallback, lazy loading, sized to prevent CLS |
| Layout shift | No content pushing layout after load |
| Lists | Virtualization for 100+ items |

## Step 7: Write Report

Derive a topic slug (lowercase, hyphens, max 4 words). Run `mkdir -p .forge/design`. Write to `.forge/design/audit-[topic].md` with: scores table (Dimension | Score 0-10 | Issue count for all 5 dimensions + Overall), per-dimension findings with `file:line` citations, and Top 5 Improvements by priority.

```
FORGE /design-audit — Complete
Output: .forge/design/audit-[topic].md
Overall: [score]/10 | A11y: [n] | Responsive: [n] | Interaction: [n] | Anti-Patterns: [n] | Perf: [n]
```

## What's Next
- `/design polish` — address findings | `/design review` — qualitative complement

## Rules & Scoring

- Measurement, not judgment — never recommend whether to ship. Every finding must cite `file:line`.
- Score 0-10: **9-10** zero/trivial | **7-8** minor | **5-6** several | **3-4** significant gaps | **0-2** fundamental problems.
- If a file cannot be read, note "NOT AUDITED: [reason]" and continue.
- Evidence before claims — show actual output, not summaries.

### Quality Gate
Every output must pass: all 5 dimensions scored, every finding has `file:line`, no ship recommendations, anti-pattern blocklist checked.

Follow `skills/shared/compliance-telemetry.md` (`design-audit`). Keys: `ungrounded-finding` (major) — no `file:line`; `scope-creep` (minor) — ship recommendation made. Follow `skills/shared/rules.md`. Log violations via `scripts/compliance-log.sh`.
