---
name: design-review
description: "Design review against principles. Scans for anti-patterns, audits accessibility, checks state coverage, and evaluates visual and interaction quality. Use to evaluate existing designs — triggered by 'review the design', 'check accessibility', 'is this consistent', 'design quality check'."
argument-hint: "[file paths, component names, or PR to review]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-review — Design Review Against Principles

You evaluate designs or implementations against design principles. This is a design review, not a code review — you focus on user-facing design quality. You never modify code; you observe, judge, and report.

## Step 1: Load Context

Parse `$ARGUMENTS` to identify review targets (file paths, component names, directory, or PR via `gh pr diff`). Load the project's design context: design system, tokens, theme definitions, and similar components for consistency comparison.

Read `skills/design/references/principles.md` — this is the contract you evaluate against. Internalize the full anti-pattern blocklist, state coverage checklist, and accessibility baseline before proceeding.

## Step 2: Anti-Pattern & AI Slop Scan

Check every file against the **full blocklist** from `principles.md` — typography, color, layout, motion, content/copy, interaction, images/media, and forms.

Additionally, run the **AI Design Fingerprints** check from `principles.md`. If multiple AI fingerprint patterns appear together (e.g., Inter font + purple gradient + uniform card grid + nested cards), flag as "AI slop compound pattern" — the combination is worse than individual violations.

Record every match with `file:line` and the specific anti-pattern triggered. This runs first because anti-pattern matches are the highest-signal findings. Do not skip categories. A clean scan is a valid result.

## Step 3: Accessibility Audit

Dedicated step — not a subsection of another check. Every a11y issue is at least **Major**; violations preventing usage are **Critical**.

- **Contrast**: 4.5:1 normal text, 3:1 large text
- **Keyboard nav**: All interactive elements reachable and operable
- **Semantic markup**: Semantic elements first; ARIA only when semantics are insufficient
- **Focus management**: Visible indicators, logical order, trapping in modals
- **Touch targets**: 44x44dp minimum
- **Color-only status**: Color must not be sole indicator (WCAG 1.4.1)
- **Motion**: `prefers-reduced-motion` honored, no auto-play without pause
- **Cognitive a11y**: Consistent navigation, error prevention, clear reading level

If a value cannot be determined from code (e.g., rendered contrast), flag as "needs manual verification."

## Step 4: Interaction & State Coverage

Check every interactive component against: **default, hover, focus, active, disabled, loading, error, empty, partial-data, skeleton**.

Flag missing states by component. Missing error/loading states are at least **Major**; missing skeleton/partial-data are **Minor**.

## Step 5: Visual & Content Quality

**Aesthetic coherence**: Does the design commit to a direction? Evaluate typography, color system, spatial composition, and whether motion earns its place.

**Copy quality** (copy is design):
- Active voice over passive
- Specific labels ("Create Account" not "Submit")
- Error messages with a next step
- Micro-rules: ellipsis character not three dots, curly quotes, `tabular-nums` for number columns

## Step 6: Responsiveness, Theming & Performance

**Viewports**: Layout works across mobile, tablet, desktop — no overflow or hidden functionality.

**User preferences**: Dark mode / color scheme, reduced motion, zoom not disabled.

**Performance**: Font loading strategy and weight count; animations use `transform`/`opacity` only; no layout shift from dynamic content; images optimized; virtualization for long lists.

## Step 6b: Usability Heuristics Check

Walk through the **10 usability heuristics** from `principles.md`. For each heuristic, note whether the design satisfies it or has issues. Use severity levels (Critical/Major/Minor/Suggestion), not numeric scores.

Focus on heuristics most relevant to the target — not every heuristic applies equally to every component.

## Step 6c: Review Angle Stress Test

Evaluate from the **5 review angles** in `principles.md`:

1. **Power user efficiency** — shortcuts, bulk operations, keyboard access
2. **First-time clarity** — can a newcomer understand without instruction?
3. **Accessibility compliance** — screen reader, keyboard-only, low vision
4. **Edge case resilience** — empty data, long strings, errors, slow connections
5. **Mobile/touch usability** — one-thumb operation, touch targets, no hover dependency

Flag issues found from each angle with `file:line`. Not every angle will surface issues — that is fine.

## Step 7: Write Review + Report

Derive a topic slug (lowercase, hyphens, max 4 words). Determine overall result: **PASS** (no critical/major) or **NEEDS_CHANGES** (any critical/major).

```bash
mkdir -p .forge/design
```

Write to `.forge/design/review-[topic].md`:

```markdown
# Design Review: [Topic]
Date: [YYYY-MM-DD]
Result: [PASS | NEEDS_CHANGES]

## Summary
[2-3 sentences. Note 1-2 things done well.]

## Anti-Pattern Findings
- [finding with file:line, or "None"]
- AI Slop: [compound pattern detected / clean]

## Accessibility Audit
- [finding with file:line and severity, or "All checks passed"]

## State Coverage
- [component: missing states, or "All components covered"]

## Usability Heuristics
- [heuristic: finding with severity, or "Satisfactory"]

## Review Angles
- [angle: finding, or "No issues from this perspective"]

## Findings by Severity

### Critical
- [finding, or "None"]

### Major
- [finding, or "None"]

### Minor
- [finding, or "None"]

### Suggestions
- [finding, or "None"]
```

Before claiming complete, show evidence:
```bash
head -6 .forge/design/review-[topic].md
```

```
FORGE /design-review — [PASS | NEEDS_CHANGES]
Output: .forge/design/review-[topic].md
Findings: [N] critical, [N] major, [N] minor, [N] suggestions
```

### Telemetry
```bash
bash scripts/telemetry.sh design-review completed
```

## Rules

**Severity**: Critical = blocks shipping (a11y preventing usage, broken core interaction). Major = fix before shipping (a11y gaps, missing error/loading states, consistency violations). Minor = fix when convenient. Suggestion = enhancement idea, not a problem.

**Quality gates**: Any critical or major finding means NEEDS_CHANGES. Only minor/suggestion findings allow PASS. Accessibility issues are always at least Major.

**Conduct**:
- Design review is NOT code review — user-facing design quality only.
- Do not nitpick preferences ("different shade of blue" is not a finding).
- Be specific and actionable ("card uses 16px padding while others use 24px" not "inconsistent").
- Praise 1-2 things done well in the summary — a review that only lists problems is incomplete.
- **Evidence before claims**: show the report header before claiming complete. Every finding must cite file and line.
- If a file cannot be read, note "NOT REVIEWED: [reason]" and continue.
