---
name: design-review
description: "Design review against principles. Scans for anti-patterns, audits accessibility, checks state coverage, and evaluates visual and interaction quality. Use to evaluate existing designs — triggered by 'review the design', 'check accessibility', 'is this consistent', 'design quality check'."
argument-hint: "[file paths, component names, or PR to review]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-review — Design Review Against Principles

Evaluate designs against principles — never modify code. Observe, judge, report.

## Step 1: Load Context

Parse `$ARGUMENTS` for review targets (files, components, directory, or PR via `gh pr diff`). Load design system, tokens, theme definitions, and similar components. Read `skills/design/references/principles.md` — internalize full anti-pattern blocklist, state coverage checklist, and accessibility baseline.

## Step 2: Anti-Pattern & AI Slop Scan

Check every file against the **full blocklist** from `principles.md` (typography, color, layout, motion, content, interaction, images, forms). Run the **AI Fingerprints** check — flag compound patterns (e.g., Inter + purple gradient + uniform card grid). Record every match with `file:line` and specific anti-pattern.

## Step 3: Accessibility Audit

Every a11y issue is at least **Major**; usage-preventing violations are **Critical**.

- Contrast: 4.5:1 normal, 3:1 large | Keyboard: all interactive elements reachable, visible focus, logical order, modal trapping
- Semantic markup: ARIA only when semantics insufficient | Touch: 44x44dp min | Color-only status: WCAG 1.4.1
- Motion: `prefers-reduced-motion` honored | Cognitive: consistent nav, error prevention
- Flag anything undeterminable from code as "needs manual verification"

## Step 4: Interaction & State Coverage

Check every interactive component against: **default, hover, focus, active, disabled, loading, error, empty, partial-data, skeleton**. Missing error/loading = Major; missing skeleton/partial-data = Minor.

## Step 5: Visual & Content Quality

**Aesthetic coherence**: Does the design commit to a direction? Evaluate typography, color, spatial composition, motion earning its place.

**Copy quality**: Active voice, specific labels ("Create Account" not "Submit"), error messages with next step, micro-rules (ellipsis char, curly quotes, `tabular-nums` for number columns).

## Step 6: Responsiveness, Theming & Performance

**Viewports**: Layout works mobile/tablet/desktop — no overflow or hidden functionality. **Preferences**: dark mode, reduced motion, zoom not disabled. **Performance**: font loading/weight count, animations use `transform`/`opacity` only, no layout shift, images optimized, virtualization for long lists.

## Step 6b: Usability Heuristics

Walk through the **10 usability heuristics** from `principles.md` — severity per heuristic (Critical/Major/Minor/Suggestion), focusing on most relevant to target.

## Step 6c: Review Angle Stress Test

Evaluate from **5 angles** in `principles.md`: (1) power user efficiency, (2) first-time clarity, (3) accessibility compliance, (4) edge case resilience, (5) mobile/touch usability. Flag issues with `file:line`.

## Step 7: Write Review + Report

Derive topic slug. Determine verdict: **PASS** (no critical/major) or **NEEDS_CHANGES** (any critical/major).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/review-[topic].md`: Header (topic, date, result), Summary (2-3 sentences + what's done well), Anti-Pattern Findings (file:line + AI slop status), Accessibility Audit (file:line + severity), State Coverage, Usability Heuristics, Review Angles, Findings by Severity (Critical/Major/Minor/Suggestions).

Verify with `head -6`, then report:
```
FORGE /design-review — [PASS | NEEDS_CHANGES]
Output: .forge/design/review-[topic].md
Findings: [N] critical, [N] major, [N] minor, [N] suggestions
```

## What's Next

See `skills/shared/workflow-routing.md`. PASS: `/design polish` or `/build`. NEEDS_CHANGES: `/design polish` to fix, then re-review.

## Rules

**Severity**: Critical = blocks shipping. Major = fix before shipping. Minor = fix when convenient. Suggestion = enhancement. A11y issues always at least Major. Any critical/major = NEEDS_CHANGES verdict.

**Conduct**: Design review is NOT code review. Be specific and actionable with `file:line`. Praise 1-2 things done well. Unreadable files: note "NOT REVIEWED: [reason]" and continue.

> **Compliance & telemetry**: see `skills/shared/compliance-telemetry.md`. Log via `scripts/compliance-log.sh`.
> Keys: `a11y-underclassified` (major), `false-pass` (critical). Evidence before claims — show actual output, not summaries.
