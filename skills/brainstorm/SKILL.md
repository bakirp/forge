---
name: brainstorm
description: "Ideation and alternative exploration before architecture. Generates multiple approaches with tradeoffs, helps the user choose or combine, and produces a brainstorm artifact that /architect consumes. Use --grill to stress-test an existing plan instead of generating new approaches. Use before architecture when exploring options — triggered by 'brainstorm', 'explore alternatives', 'what are the options', 'ideation', 'compare approaches', 'grill my plan', 'stress test this', 'challenge this plan'."
argument-hint: "[task or problem description]"
allowed-tools: Read Grep Glob Bash
---

# /brainstorm — Ideation and Alternative Exploration

You generate multiple approaches to a problem, surface honest tradeoffs, and help the user choose before committing to architecture. The output is a brainstorm artifact that /architect consumes as input.

## Step 0: Parse Flags and Mode

Read `$ARGUMENTS`. Check for the `--grill` flag:
- If `--grill` is present, set GRILL_MODE=true and strip the flag from arguments before proceeding
- GRILL_MODE replaces approach generation (Steps 1-4) with decision-tree interrogation (Step 0.5)
- Default behavior (no flag) is unchanged — normal brainstorm flow

If no arguments provided (after flag stripping), ask the user what problem or plan they want to explore.

## Step 0.1: Are We Solving the Right Problem?

Before exploring solutions, question the problem itself. This prevents wasting time building the wrong thing well.

Ask the user these forcing questions (adapt to context — skip any that are obviously answered):

1. **Who benefits?** — Who is the end user of this change? What does their workflow look like today without it?
2. **What happens if we don't build this?** — Is there a workaround? How painful is the status quo, really?
3. **What does success look like?** — How will we know this worked? What's the measurable outcome?
4. **What's the simplest version?** — If we had to ship something in 1 hour, what would it be? Is that enough?
5. **Are we solving a symptom?** — Is this the root problem, or is there a deeper issue we're patching over?

Wait for the user's answers. If they reveal the problem is different from what was initially stated, reframe before proceeding. If the user says "just build it" or signals they've already thought this through, respect that — note their reasoning and move to Step 1.

```
FORGE /brainstorm — Problem validated

Original: [what was asked]
Reframed: [what we're actually solving, if different]
Success criteria: [from user's answers]
```

**If GRILL_MODE=true:** Skip Steps 1-4 entirely. Proceed to Step 0.5.

## Step 0.5: Grill Mode — Decision Tree Interrogation

**Only runs when `--grill` flag is set.** This mode stress-tests an existing plan rather than generating new approaches.

### Setup

1. Read the codebase structure, tech stack, existing patterns, and relevant memory (`/memory-recall`)
2. Read the user's plan from `$ARGUMENTS` or ask them to describe it
3. Identify the plan's key decision points — each choice the plan makes (or assumes) is a branch to interrogate

### Interrogation Loop

Walk the decision tree **one question at a time**. For each decision point in the plan:

1. **Self-resolve first** — before asking the user, check if the codebase already answers the question (existing patterns, constraints, dependencies). If it does:
   ```
   [Question about X]
   I checked the codebase — [what you found]. This confirms/contradicts the plan's assumption.
   Moving on.
   ```

2. **Ask with a recommended answer** — if the question requires user input:
   ```
   [Question about the plan]
   My recommendation: [what you'd suggest and why, based on codebase context].
   Do you agree, or see it differently?
   ```

3. **Follow branches** — each answer may reveal follow-up questions. Walk down that branch before moving to the next decision point. Keep branches focused — don't let follow-ups drift into unrelated territory.

4. **Track decisions** — maintain a running list of confirmed decisions and identified risks as you go.

### Interrogation Categories

Walk through these angles (skip any that are obviously settled):

- **Scope boundaries** — What's in, what's explicitly out? What happens at the edges?
- **Assumptions** — What does the plan take for granted? Are those assumptions valid in this codebase?
- **Failure modes** — What happens when each component fails? Is error handling specified or assumed?
- **Integration points** — Where does this touch existing code? Are those interfaces stable?
- **Missing pieces** — What does the plan not mention that it will need? (Auth, validation, migrations, etc.)
- **Ordering risks** — Does the plan's sequence create unnecessary risk? Could a different order reduce integration pain?

### Termination

- **Default cap: 10 questions.** After 10, summarize findings and move to artifact writing.
- If the user says "keep going" or there are clearly unresolved branches, continue for up to 10 more.
- If the user says "enough" or "looks good" at any point, stop immediately and move to artifact writing.
- If you run out of genuine questions before 10, stop early — don't pad with obvious questions.

### Transition to Artifact

When interrogation is complete:
```
FORGE /brainstorm — Grill complete ([N] questions, [M] decisions confirmed)

Key findings:
- [most important finding or risk identified]
- [second most important]
- [third most important]

Writing artifact...
```

**Skip Steps 1-4. Proceed directly to Step 5** (Write Brainstorm Artifact), but use the grill artifact format instead (see Step 5).

## Step 1: Understand the Problem Space

Gather context:
- Read the codebase structure (directories, key files, tech stack)
- Identify existing patterns and constraints
- Check for related features or prior art in the codebase
- Run `/memory-recall` with the current task context for relevant past decisions

Identify the core problem — what are we really trying to solve? Restate it in 1-2 sentences and confirm with the user before generating approaches.

```
FORGE /brainstorm — Problem understood

[1-2 sentence restatement of the core problem]

Generating approaches...
```

## Step 2: Generate Approaches

Generate 3-5 distinct approaches. Each must be genuinely different — not minor variations of the same idea. At least one should be unconventional or contrarian.

For each approach, provide:
- **Name** (short, memorable)
- **Description** (2-3 sentences)
- **Pros** (2-3 honest advantages)
- **Cons** (2-3 honest disadvantages)
- **Effort** (low / medium / high)
- **Risk** (low / medium / high)
- **Best for** (when this approach shines)

Present as:

```
FORGE /brainstorm — [N] approaches generated

1. [Name]: [one-line summary]
   Tradeoffs: [key pro] vs [key con]
   Effort: [low|medium|high]  Risk: [low|medium|high]

2. [Name]: [one-line summary]
   Tradeoffs: [key pro] vs [key con]
   Effort: [low|medium|high]  Risk: [low|medium|high]

3. ...
```

Then show the full detail for each approach.

## Step 3: Explore and Compare

Wait for the user to react. If they want to dig deeper:
- Compare any two approaches side-by-side in a table
- Identify hybrid possibilities (combine strengths of two approaches)
- Surface hidden constraints or dependencies that favor one approach
- Note what each approach defers vs solves now

Present a comparison table when helpful:

```
| Criterion        | Approach A      | Approach B      |
|------------------|-----------------|-----------------|
| Effort           | ...             | ...             |
| Risk             | ...             | ...             |
| Scalability      | ...             | ...             |
| Maintainability  | ...             | ...             |
```

If the user already knows what they want, skip deep comparison — confirm their choice and move to Step 4.

## Step 4: Select and Refine

Once the user picks an approach (or combination):
- Sharpen the selected approach based on discussion
- Note what was explicitly rejected and why (this context is valuable for /architect)
- Capture any constraints discovered during brainstorming

```
FORGE /brainstorm — Approach selected: [name]

Refining...
```

## Step 5: Write Brainstorm Artifact

Write to `.forge/brainstorm/[task-name-slugified].md`. Create the directory if it doesn't exist.

**If GRILL_MODE=true**, use the grill artifact format:

```markdown
# FORGE Brainstorm (Grill): [Task Name]

## Date: [YYYY-MM-DD]
## Mode: Grill
## Plan: [1-2 sentence summary of the plan that was interrogated]

## Decisions Confirmed
- [Decision 1]: [what was confirmed and why]
- [Decision 2]: [what was confirmed and why]
...

## Risks Identified
- [Risk 1]: [description and severity — low|medium|high]
- [Risk 2]: [description and severity]
...

## Plan Changes
[List any changes the user agreed to during interrogation. If none: "No changes — plan validated as-is."]

## Open Questions
[Any questions that were not resolved. If none: "All questions resolved."]

## Constraints Discovered
- [any constraints surfaced during grilling]

## Next: /architect
```

**Otherwise (normal mode)**, use the standard format:

```markdown
# FORGE Brainstorm: [Task Name]

## Date: [YYYY-MM-DD]
## Problem: [1-2 sentence restatement]

## Approaches Explored

### Approach 1: [Name]
- Description: [2-3 sentences]
- Pros: [list]
- Cons: [list]
- Effort: [low|medium|high]
- Risk: [low|medium|high]

### Approach 2: [Name]
- Description: [2-3 sentences]
- Pros: [list]
- Cons: [list]
- Effort: [low|medium|high]
- Risk: [low|medium|high]

### Approach 3: [Name]
...

## Selected: [approach name or "Hybrid: A + C"]
## Rationale: [why this was chosen over alternatives]

## Rejected Approaches
- [Name]: [why rejected — useful context for /architect]

## Constraints Discovered
- [any constraints surfaced during brainstorming]

## Next: /architect
```

## Step 6: Hand Off

```
FORGE /brainstorm — Complete

Selected approach: [name]
Rationale: [1-line]
Artifact: .forge/brainstorm/[task-name].md

Ready for /architect. The brainstorm artifact provides context for architecture decisions.
```

## Rules

- Generate at least 3 approaches — even if one seems obviously best (normal mode only)
- Never pick for the user — present options, let them choose
- Include at least one unconventional or contrarian approach (normal mode only)
- Tradeoffs must be honest — no approach is perfect, say so
- The brainstorm artifact is input for /architect, not a binding contract
- If the user already knows what they want, don't force brainstorming — confirm their choice and write a minimal artifact
- Keep it time-bounded — if discussion exceeds 3 rounds, push toward a decision (normal mode); 10 questions default cap (grill mode)
- Never write implementation code — ideation only
- **Grill mode**: always provide a recommended answer with every question — don't just ask, show what you'd decide and why
- **Grill mode**: self-resolve from the codebase before asking the user — don't waste their time on answerable questions

### Telemetry
```bash
bash scripts/telemetry.sh brainstorm [completed|error]
```
