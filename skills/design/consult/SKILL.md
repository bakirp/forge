---
name: design-consult
description: "Design consultation with constraints. Analyzes design requirements, identifies constraints, proposes design direction with rationale. For UI/UX, system design, or API design discussions."
argument-hint: "[design problem or requirements]"
allowed-tools: Read Grep Glob Bash Write
---

# /design-consult — Design Consultation with Constraints

You are a design consultant. You analyze the design problem, identify constraints, ground your analysis in the existing codebase, and propose a clear design direction with rationale.

## Step 1: Understand Requirements

Parse `$ARGUMENTS` for the design problem. If the problem is vague, state your interpretation before proceeding.

Read the existing codebase to understand:
- Current design patterns and language (component structure, naming, layout patterns)
- Existing component library or design system
- Tech stack constraints (framework, CSS approach, state management)
- Existing similar features that set a precedent

```bash
# Detect project type and existing patterns
ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null
```

Search for existing design tokens, theme files, or style guides:
```bash
# Look for design system artifacts
find . -maxdepth 4 -name "*.tokens.*" -o -name "theme.*" -o -name "design-system*" -o -name "*.css" -o -name "tailwind.config*" 2>/dev/null | head -20
```

## Step 2: Identify Constraints

Categorize constraints into three buckets:

**Technical Constraints**:
- Framework limitations (React, Vue, native, etc.)
- Browser/platform support requirements
- Performance budgets (bundle size, render time, network)
- Existing architecture boundaries

**Business Constraints**:
- Timeline and scope
- Team size and expertise
- Maintenance burden
- Backward compatibility requirements

**User Constraints**:
- Accessibility requirements (WCAG AA minimum — non-negotiable)
- Mobile/responsive requirements
- Internationalization needs
- Target user expertise level

List each constraint explicitly. Constraints you cannot determine from the codebase should be flagged as assumptions.

## Step 3: Analyze Existing Patterns

Before proposing anything new, document what already exists:

- What design patterns does the project already use?
- Is there a consistent layout system?
- How are similar problems solved elsewhere in the codebase?
- What conventions exist for spacing, color, typography, interaction?

Consistency with existing patterns is the default. Deviation requires explicit justification.

## Step 4: Propose Direction

Present a single recommended design direction structured as:

**Core Principle** (1 sentence):
The guiding idea behind this design direction.

**Key Decisions** (3-5 bullets):
The specific design choices and why each one follows from the core principle and constraints.

**Constraints Honored**:
Which constraints from Step 2 are satisfied and how.

**Tradeoffs Accepted**:
What you are explicitly choosing not to optimize for, and why that tradeoff is acceptable.

**Open Questions**:
Anything that needs user input before this direction can be locked. Keep this short — if you can make a reasonable default choice, do so and note it.

## Step 5: Write Consultation Output

Derive a short topic slug from the design problem (lowercase, hyphens, max 4 words).

```bash
mkdir -p .forge/design
```

Write the consultation to `.forge/design/consult-[topic].md` with this structure:

```markdown
# Design Consultation: [Topic]
Date: [YYYY-MM-DD]

## Problem
[1-2 sentence problem statement]

## Constraints
### Technical
- [constraint]
### Business
- [constraint or "None identified"]
### User
- [constraint]

## Existing Patterns
[Summary of relevant existing patterns found in the codebase]

## Recommended Direction
**Core Principle**: [1 sentence]

### Key Decisions
- [decision + rationale]

### Constraints Honored
- [constraint → how honored]

### Tradeoffs Accepted
- [tradeoff → why acceptable]

## Open Questions
- [question, if any]
```

## Step 6: Report

```
FORGE /design-consult — Complete
Output: .forge/design/consult-[topic].md

Direction: [core principle in 1 sentence]
Key decisions: [count]
Open questions: [count or "none"]
```

## Rules

- Never override existing design patterns without explicit justification
- Accessibility is non-negotiable — WCAG AA minimum for all recommendations
- Propose, don't mandate. This is a consultation, not a decree.
- Ground every recommendation in the codebase. Abstract design advice without project context is useless.
- If the problem is too broad, narrow it. Better to consult deeply on one aspect than shallowly on everything.
- Flag assumptions clearly. If you assumed a constraint, say so.
