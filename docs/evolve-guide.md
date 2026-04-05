# FORGE Evolve Guide

`/evolve` is FORGE's most unique feature: a meta-agent that rewrites FORGE's own skills based on how well they worked for you.

## How It Works

```
/ship → /retro → (accumulate data) → /evolve → improved skills → repeat
```

1. After each `/ship` cycle, run `/retro` to record what went well and what didn't
2. `/retro` stores structured data: answers to three questions + per-skill ratings
3. After a few cycles, run `/evolve` to analyze the data and propose improvements
4. `/evolve` classifies changes by risk, applies safe ones automatically, asks about the rest

## The Feedback Loop

### Step 1: Accumulate Retros

Run `/retro` after each ship cycle. The more retros you have, the better `/evolve`'s proposals:

- **1 retro**: `/evolve` will warn about limited data
- **2-3 retros**: Enough for basic pattern detection
- **5+ retros**: Strong signal for targeted improvements

### Step 2: Run /evolve

```
/evolve
```

Or target a specific skill:
```
/evolve build
```

### Step 3: Review the Report

`/evolve` produces a skill effectiveness report showing average scores and trends across all retros. Skills scoring below 2.5 are flagged as "needs work".

### Step 4: Review Proposals

Each proposed change includes:
- What changes and why
- Which retros prompted it
- Risk classification
- The exact diff

## Risk Levels

### Low-Risk (Auto-Applied)

These don't change behavior — just clarity:
- Better wording in instructions
- Added examples for unclear steps
- Fixed typos or formatting
- Reordered steps for better flow

You can approve all low-risk changes at once.

### Medium-Risk (Recommended, Needs Approval)

These adjust behavior within existing guardrails:
- Changing thresholds (e.g., token budget warning from 40k to 50k)
- Adding optional escape hatches (e.g., skip TDD for config-only changes)
- Adjusting output verbosity based on feedback
- Adding new edge case handling

Review each one individually. The diff is shown before you decide.

### High-Risk (Requires Explicit Approval)

These alter core behavior or safety guardrails:
- Removing TDD enforcement
- Changing when `/ship` blocks
- Modifying the memory schema
- Altering `/think` classification criteria
- Changing the skill chain order

These are rare and should be considered carefully. `/evolve` will explain the rationale and impact.

## What /evolve Will Never Do

- Remove safety checks without your explicit per-change approval
- Apply high-risk changes automatically
- Modify files outside the skills directory
- Delete retro data
- Run itself recursively

## Evolution History

Every `/evolve` run produces a log at `~/.forge/retros/evolve_[date].json` containing:
- Which retros were analyzed
- Skill scores
- Every proposed change and whether it was applied or rejected

This history is part of FORGE's story. If you git-track your `~/.forge/` directory, you can trace how your workflow evolved over time.

## Tips

- **Run /retro consistently** — the signal comes from patterns across multiple cycles, not one-off complaints
- **Rate skills honestly** — a 5 on every skill gives /evolve nothing to work with
- **Focus feedback on specifics** — "the TDD loop was too strict for config changes" is more useful than "build was slow"
- **Review medium-risk changes carefully** — these are where the real improvements happen
- **Commit after evolving** — `git commit -m "evolve: [summary]"` preserves the evolution history
