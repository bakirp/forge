---
name: brainstorm
description: "Ideation and alternative exploration before architecture. Generates multiple approaches with tradeoffs, helps the user choose or combine, and produces a brainstorm artifact that /architect consumes. Use --grill to stress-test an existing plan instead of generating new approaches. Use before architecture when exploring options — triggered by 'brainstorm', 'explore alternatives', 'what are the options', 'ideation', 'compare approaches', 'grill my plan', 'stress test this', 'challenge this plan'."
argument-hint: "[task or problem description]"
allowed-tools: Read Grep Glob Bash
---

# /brainstorm — Ideation and Alternative Exploration

Generate 3-5 genuinely distinct approaches (at least one unconventional/contrarian), surface honest tradeoffs, and help the user choose before committing to architecture. Output is a brainstorm artifact for /architect. Never pick for the user. Never write implementation code.

## Step 0: Parse Flags and Mode

Read `$ARGUMENTS`. If `--grill` flag present, set GRILL_MODE=true and strip it. If no arguments remain, ask what to explore.

## Step 0.1: Forcing Questions

Before exploring solutions, verify you're solving the right problem (skip obviously answered):

1. **Who benefits?** — End user and their current workflow?
2. **What if we don't build this?** — Workaround? Status quo pain?
3. **What does success look like?** — Measurable outcome?
4. **Simplest version?** — 1-hour ship — enough?
5. **Solving a symptom?** — Root problem or patch?

Wait for answers; reframe if they reveal a different problem. If GRILL_MODE=true, skip Steps 1-4 and proceed to Step 0.5.

## Step 0.5: Grill Mode — Decision Tree Interrogation

**Only runs with `--grill`.** Stress-tests an existing plan instead of generating approaches.

**Setup:** Read codebase, tech stack, existing patterns, `/memory-recall`. Read the user's plan from `$ARGUMENTS` or ask. Identify key decision points to interrogate.

**Interrogation Loop** (one question at a time per decision point):
1. **Self-resolve first** — check if codebase answers it; state findings and move on if so
2. **Ask with recommendation** — state question, your recommended answer with reasoning, ask if they agree
3. **Follow branches** — walk follow-ups before next decision point
4. **Track decisions** — maintain running list of confirmed decisions and risks

**Categories** (skip settled): Scope boundaries, Assumptions, Failure modes, Integration points, Missing pieces, Ordering risks.

**Termination:** Default cap 10 questions, then summarize and write artifact. "Keep going" extends 10 more; "enough"/"looks good" stops immediately. Stop early if out of genuine questions. Skip Steps 1-4, proceed to Step 5 with grill artifact format.

## Step 1: Understand the Problem Space

Gather context: codebase structure, patterns/constraints, related features, `/memory-recall`. Restate the core problem in 1-2 sentences and confirm with the user.

## Step 2: Generate Approaches

Generate 3-5 distinct approaches (not minor variations; at least one unconventional/contrarian). For each: **Name**, **Description** (2-3 sentences), **Pros** (2-3), **Cons** (2-3), **Effort** (L/M/H), **Risk** (L/M/H), **Best for**. Show summary table then full detail.

## Step 3: Compare and Select

Wait for user reaction. Offer side-by-side table or hybrid possibilities if they want deeper comparison. Once they pick: sharpen the choice, note what was rejected and why (context for /architect), capture constraints discovered.

## Step 4: Write Brainstorm Artifact

Write to `.forge/brainstorm/[task-name-slugified].md` (create dir if needed).

**Grill fields:** Title, Date, Mode (Grill), Plan summary, Decisions Confirmed, Risks Identified, Plan Changes, Open Questions, Constraints, Next: /architect.
**Normal fields:** Title, Date, Problem, Approaches (Name/Desc/Pros/Cons/Effort/Risk each), Selected + Rationale, Rejected + Reasons, Constraints, Next: /architect.

## Step 5: Hand Off

Report selected approach, rationale, artifact path. Suggest /architect as next step.

> **Routing:** See `skills/shared/workflow-routing.md` for next-step guidance.

## Rules & Compliance

- 3+ approaches in normal mode; at least one unconventional. Never pick for the user. Honest tradeoffs only.
- Grill mode: always recommend an answer; self-resolve from codebase first. Cap: 10 questions.
- Normal mode: 3 discussion rounds max before pushing toward decision.
- Never write implementation code. Artifact is input for /architect, not a binding contract.
- If user already knows what they want, confirm and write minimal artifact.
- **Compliance:** See `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh` per shared protocol. Keys: `insufficient-approaches`, `implementation-in-brainstorm`, `choice-not-presented` (all major).
- **Shared rules:** See `skills/shared/rules.md`.
