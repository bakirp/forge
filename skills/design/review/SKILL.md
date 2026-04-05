---
name: design-review
description: "Design review against principles. Evaluates an existing design or implementation against design principles, consistency, accessibility, and user experience."
argument-hint: "[file paths, component names, or PR to review]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-review — Design Review Against Principles

You evaluate existing designs or implementations against design principles. This is a design review, not a code review — you focus on user-facing design quality, not implementation correctness.

## Step 1: Load Design Context

Parse `$ARGUMENTS` to determine what to review:

- **File paths**: Read the specified files directly
- **Component names**: Search the codebase for matching components
- **Directory**: Review all design-relevant files in the directory
- **PR reference**: Use `gh pr view` and `gh pr diff` to load the changes

```bash
# If reviewing specific files, read them
# If reviewing a component by name, find it first
find . -maxdepth 5 -type f \( -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" -o -name "*.html" -o -name "*.css" \) 2>/dev/null | head -30
```

Also load the project's design context:
- Design system or component library (if any)
- Style guide or design tokens
- Existing similar components for consistency comparison

```bash
# Look for design system artifacts
find . -maxdepth 4 -name "*.tokens.*" -o -name "theme.*" -o -name "design-system*" -o -name "tailwind.config*" -o -name ".storybook" 2>/dev/null | head -20
```

## Step 2: Evaluate Against Principles

Review the design against each principle. For each principle, note specific findings.

### Consistency
- Does it match existing design patterns in the project?
- Are naming conventions consistent with the rest of the codebase?
- Does spacing, typography, and color usage follow established patterns?
- If it introduces new patterns, is there justification?

### Simplicity
- Is the design as simple as it could be while meeting requirements?
- Are there unnecessary layers of abstraction or visual complexity?
- Could a user understand the interface without instruction?
- Is the information hierarchy clear?

### Accessibility (WCAG AA Minimum)
- **Color contrast**: Text meets 4.5:1 ratio (3:1 for large text)
- **Keyboard navigation**: All interactive elements reachable and operable via keyboard
- **Screen reader support**: Semantic HTML, ARIA labels where needed, meaningful alt text
- **Focus management**: Visible focus indicators, logical focus order, focus trapping in modals
- **Motion**: Respects `prefers-reduced-motion`, no auto-playing animations without pause
- **Touch targets**: Minimum 44x44px for mobile interactive elements

### Responsiveness
- Does the layout work across viewport sizes (mobile, tablet, desktop)?
- Are breakpoints handled gracefully (no content overflow, no hidden functionality)?
- Do images and media scale appropriately?
- Is touch interaction considered for mobile viewports?

### Performance
- Are there obvious performance anti-patterns? (large unoptimized images, layout thrashing, excessive DOM nodes)
- Are animations GPU-accelerated where possible (transform/opacity vs. top/left)?
- Is content loading strategy appropriate (lazy loading, skeleton screens, progressive enhancement)?

## Step 3: Check Design System Adherence

If the project has a design system, component library, or style guide:

- Are the correct design tokens being used (colors, spacing, typography)?
- Are existing components being reused where appropriate, or are new ones being created unnecessarily?
- Does the implementation match the design system's documented patterns?
- Are deviations from the design system documented and justified?

If no design system exists, note this and evaluate against the project's implicit patterns.

## Step 4: Write Review

Structure findings by severity:

**Critical** — Blocks shipping. Accessibility violations that prevent usage, broken core functionality.
**Major** — Should fix before shipping. Significant consistency issues, poor UX that confuses users, accessibility gaps.
**Minor** — Fix when convenient. Small inconsistencies, polish items, minor improvements.
**Suggestion** — Nice to have. Ideas for enhancement, not problems with current implementation.

For each finding:
```
[SEVERITY] [Principle]: [Description]
  Location: [file:line or component name]
  Issue: [What is wrong]
  Recommendation: [How to fix it]
```

Determine overall result:
- **PASS**: No critical or major findings
- **NEEDS_CHANGES**: One or more critical or major findings

## Step 5: Write Review Output

Derive a short topic slug from the review target (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write the review to `.forge/design/review-[topic].md`:

```markdown
# Design Review: [Topic]
Date: [YYYY-MM-DD]
Result: [PASS | NEEDS_CHANGES]

## Summary
[2-3 sentence summary of overall design quality]

## Findings

### Critical
- [finding, or "None"]

### Major
- [finding, or "None"]

### Minor
- [finding, or "None"]

### Suggestions
- [finding, or "None"]

## Design System Compliance
[Summary of adherence to design system, or note that no design system was found]

## Scores
| Principle | Rating |
|-----------|--------|
| Consistency | [strong/adequate/weak] |
| Simplicity | [strong/adequate/weak] |
| Accessibility | [strong/adequate/weak] |
| Responsiveness | [strong/adequate/weak] |
| Performance | [strong/adequate/weak] |
```

## Step 6: Report

```
FORGE /design-review — [PASS | NEEDS_CHANGES]
Output: .forge/design/review-[topic].md

Findings: [N] critical, [N] major, [N] minor, [N] suggestions
```

## Rules

- Accessibility issues are always at least **major** severity. Accessibility failures that prevent usage are **critical**.
- Do not nitpick styling preferences. "I would have chosen a different shade of blue" is not a finding.
- Design review is not code review. Focus on user-facing design quality, not code style or architecture.
- If you cannot determine something from the code alone (e.g., actual rendered color contrast), flag it as "needs manual verification" rather than guessing.
- Be specific. "The design is inconsistent" is not actionable. "The card component uses 16px padding while all other cards use 24px" is actionable.
- Praise what works well. A review that only lists problems is demoralizing and incomplete. Note 1-2 things done well in the summary.
