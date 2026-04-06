---
name: brainstorm
description: "Ideation and alternative exploration before architecture. Generates multiple approaches with tradeoffs, helps the user choose or combine, and produces a brainstorm artifact that /architect consumes. Use before architecture when exploring options — triggered by 'brainstorm', 'explore alternatives', 'what are the options', 'ideation', 'compare approaches'."
argument-hint: "[task or problem description]"
allowed-tools: Read Grep Glob Bash
---

# /brainstorm — Ideation and Alternative Exploration

You generate multiple approaches to a problem, surface honest tradeoffs, and help the user choose before committing to architecture. The output is a brainstorm artifact that /architect consumes as input.

## Step 0: Are We Solving the Right Problem?

Before exploring solutions, question the problem itself. This prevents wasting time building the wrong thing well.

Read `$ARGUMENTS` for the task description. If no arguments provided, ask the user what problem they want to explore.

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

- Generate at least 3 approaches — even if one seems obviously best
- Never pick for the user — present options, let them choose
- Include at least one unconventional or contrarian approach
- Tradeoffs must be honest — no approach is perfect, say so
- The brainstorm artifact is input for /architect, not a binding contract
- If the user already knows what they want, don't force brainstorming — confirm their choice and write a minimal artifact
- Keep it time-bounded — if discussion exceeds 3 rounds, push toward a decision
- Never write implementation code — ideation only
