---
name: design-audit
description: "Technical design quality audit — scores accessibility, responsiveness, interaction completeness, and anti-pattern density. Use to measure design quality across dimensions — triggered by 'audit the design', 'check design quality', 'design score', 'how good is the design', 'accessibility audit'."
argument-hint: "[file paths, component names, or directory to audit]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-audit — Technical Design Quality Audit

You measure design quality across technical dimensions and produce a scored report. This is a measurement tool, not a quality gate — you report numbers and findings, not a pass/fail verdict. `/design-review` is the gate; you are the instrument.

## Step 1: Identify Targets

Parse `$ARGUMENTS` to identify audit targets (file paths, component names, directory). Read the project's design context: design system, tokens, theme definitions.

Read these references:
- `skills/design/references/principles.md` — anti-pattern blocklist, accessibility baseline
- `skills/design/references/interaction-design.md` — state patterns, form patterns, focus management
- `skills/design/references/responsive-design.md` — layout patterns, breakpoint usage, fluid design

```bash
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

## Step 2: Accessibility Dimension

Score each sub-category. For each issue, cite `file:line`.

| Check | What to look for |
|-------|------------------|
| Contrast | Text/background pairs meeting 4.5:1 (normal) / 3:1 (large, UI components) |
| Keyboard | All interactive elements reachable, logical tab order, no tabindex > 0 |
| Semantic HTML | `<button>` not `<div onclick>`, `<nav>`, `<main>`, `<header>`, headings in order |
| Focus | `:focus-visible` styles present, focus trapped in modals, returned on close |
| ARIA | `aria-label` where visible text is insufficient, `aria-live` for dynamic content |
| Forms | Labels associated, validation on blur, errors descriptive with next step |
| Alt text | All `<img>` have `alt`, decorative images have `alt=""` or `aria-hidden` |
| Motion | `prefers-reduced-motion` respected, no auto-play without pause |
| Touch | Interactive targets ≥ 44×44px |
| Zoom | `user-scalable` not disabled, layout works at 200% zoom |

## Step 3: Responsiveness Dimension

| Check | What to look for |
|-------|------------------|
| Breakpoints | Content-driven (`em`), not device-based (px). 2-4 breakpoints max. |
| Fluid layout | Uses `auto-fit`/`auto-fill` grids, `clamp()` spacing, no fixed widths |
| Container queries | Components in multiple contexts adapt to container, not viewport |
| Mobile text | No text < 16px (prevents iOS zoom), readable line lengths |
| Navigation | Adapts pattern per viewport (hamburger → horizontal → sidebar) |
| Images | `srcset` or fluid sizing, `loading="lazy"` for below-fold |
| Safe areas | `env(safe-area-inset-*)` used where needed |
| No overflow | No unintended horizontal scroll |

## Step 4: Interaction Completeness Dimension

For each interactive component, check state coverage against the 8-state model (interaction-design.md):

| Component | default | hover | focus | active | disabled | loading | error | success |
|-----------|---------|-------|-------|--------|----------|---------|-------|---------|

Mark each: ✓ (present), ✗ (missing), — (not applicable).

Also check:
- Focus order matches visual order
- Destructive actions use undo (not confirmation dialog)
- Forms validate on blur, not only on submit
- Modals use native `<dialog>` or equivalent with proper focus management

## Step 5: Anti-Pattern Density

Run the full blocklist from `principles.md` across all target files. Count matches per category:

| Category | Count | Examples |
|----------|-------|----------|
| Typography | | |
| Color | | |
| Layout | | |
| Motion | | |
| Content & Copy | | |
| Interaction | | |
| Images & Media | | |
| Forms | | |
| AI Design Fingerprints | | |

Cite every match with `file:line` and the specific anti-pattern.

## Step 6: Performance Dimension

| Check | What to look for |
|-------|------------------|
| Font loading | `font-display: swap`, subset fonts, ≤ 3 font files |
| Animation | Only `transform`/`opacity` animated, no `transition: all` |
| Images | WebP/AVIF with fallback, lazy loading, sized to prevent CLS |
| Layout shift | No content pushing layout after load (CLS sources) |
| Lists | Virtualization for 100+ items |

## Step 7: Write Report

Derive a topic slug (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/audit-[topic].md`:

```markdown
# Design Audit: [Topic]
Date: [YYYY-MM-DD]

## Scores

| Dimension | Score | Issues |
|-----------|-------|--------|
| Accessibility | [0-10] | [count] |
| Responsiveness | [0-10] | [count] |
| Interaction Completeness | [0-10] | [count] |
| Anti-Pattern Density | [0-10] | [count] |
| Performance | [0-10] | [count] |
| **Overall** | **[average]** | **[total]** |

## Accessibility
[Findings with file:line]

## Responsiveness
[Findings with file:line]

## Interaction Completeness
[State coverage table per component]

## Anti-Patterns
[Findings by category with file:line]

## Performance
[Findings with file:line]

## Top 5 Improvements
1. [Highest-impact fix]
2. ...
```

Show the report header as evidence, then report:

```
FORGE /design-audit — Complete
Output: .forge/design/audit-[topic].md
Overall: [score]/10 | A11y: [n] | Responsive: [n] | Interaction: [n] | Anti-Patterns: [n] | Perf: [n]
```

## Rules

- **This is measurement, not judgment.** Report what you find. Do not recommend whether to ship — that is `/design-review`'s job.
- **Every finding cites file:line.** Ungrounded findings are not findings.
- **Score honestly.** 10/10 means zero issues found, not "good enough." A typical production UI scores 6-8.
- **Evidence before claims** — show the report header before reporting complete.
- If a file cannot be read, note "NOT AUDITED: [reason]" and continue.

### Scoring Guide

Per dimension, 0-10:
- **9-10**: Zero or trivial issues only
- **7-8**: Minor issues, all easily fixable
- **5-6**: Several issues, some requiring meaningful work
- **3-4**: Significant gaps
- **0-2**: Fundamental problems

### Telemetry
```bash
bash scripts/telemetry.sh design-audit [completed|error]
```

### Error Handling
If any step fails: (1) what failed, (2) what completed, (3) what remains, (4) ask user how to proceed. Never silently continue past failure.
