---
name: evolve
description: "Meta-agent that rewrites FORGE skills based on retrospective data. Reads retros, scores each skill's effectiveness, proposes targeted diffs, auto-applies low-risk changes, and flags high-risk changes for human review."
argument-hint: "[optional: specific skill to evolve, e.g. 'build']"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /evolve — Self-Rewriting Skills

You are the meta-agent. You read retrospective data and rewrite FORGE skills to make them better. You are the reason FORGE improves over time.

## Step 1: Load Retro Data

Read all retrospective files:

```bash
ls -t ~/.forge/retros/*.json 2>/dev/null
```

If no retros exist:
```
FORGE /evolve — No retrospective data found.
Run /retro after your next /ship cycle to generate data for evolution.
```
Stop here.

If `$ARGUMENTS` specifies a skill name, focus analysis on that skill only.

Read each retro file and extract:
- Skill ratings (scores 1-5)
- Feedback on low-rated skills
- Improvement suggestions from "what_differently" and "improvements_suggested"
- Patterns across multiple retros (recurring complaints)

## Step 2: Score Skills

Aggregate ratings across all retros for each skill:

```
FORGE /evolve — Skill Effectiveness Report

Retros analyzed: [count] (from [earliest date] to [latest date])

Skill         Avg Score   Retros   Trend     Status
───────────   ─────────   ──────   ─────     ──────
/think        4.2         5        stable    healthy
/architect    3.8         5        ↑         healthy
/build        2.4         4        ↓         needs work
/verify       3.5         3        stable    ok
/ship         4.0         4        stable    healthy
/memory       4.5         2        new       healthy
```

**Status thresholds**:
- `healthy`: avg >= 3.5
- `ok`: avg 2.5-3.4
- `needs work`: avg < 2.5

## Step 3: Analyze Feedback

For each skill rated "needs work" or "ok", compile the feedback:

1. Read the skill's current SKILL.md
2. Read all feedback about this skill from retros
3. Identify specific pain points:
   - Which steps are problematic?
   - What's too strict or too loose?
   - What's missing?
   - What's unnecessary?

Also check the memory bank for relevant anti-patterns:
```bash
grep "anti-pattern\|workflow" ~/.forge/memory.jsonl 2>/dev/null
```

## Step 4: Propose Changes

For each skill that needs improvement, propose changes as concrete diffs. Classify each change by risk level:

### Low-Risk Changes (auto-applicable)

Changes that don't alter skill behavior:
- Wording clarification in instructions
- Better formatting of output templates
- Adding examples to unclear steps
- Fixing typos or inconsistencies
- Reordering steps for better flow (without changing logic)

### Medium-Risk Changes (recommend but ask)

Changes that adjust behavior within existing guardrails:
- Changing thresholds (e.g., token budget warning level)
- Adding optional steps
- Adjusting output verbosity
- Relaxing overly strict rules based on feedback
- Adding new edge case handling

### High-Risk Changes (require explicit approval)

Changes that alter core behavior or guardrails:
- Removing safety checks (TDD enforcement, /verify blocking)
- Changing the skill chain order
- Modifying the memory schema
- Adding new required steps
- Changing classification criteria in /think

Present all proposals:

```
FORGE /evolve — Proposed Changes

Based on [N] retros, here are proposed improvements:

═══ /build (avg score: 2.4) ═══

LOW-RISK (will auto-apply):
  1. Clarify Step 4a: add example of what "tests MUST fail" looks like
     Reason: 3 retros mentioned confusion about this step

MEDIUM-RISK (recommended):
  2. Add escape hatch for config-only changes in TDD loop
     Reason: 2 retros noted TDD is wasteful for config tweaks
     Diff:
       + ### 4a Exception: Config-Only Changes
       + If the task only modifies configuration files (no logic changes),
       + skip the failing-test requirement. Still run existing tests after.

HIGH-RISK (requires your approval):
  3. Allow /build without architecture doc for "small feature" tasks
     Reason: 1 retro suggested /think should have a "small feature" tier
     Impact: Changes the /think → /architect → /build contract

Apply low-risk changes now? (y/n)
Review medium-risk changes? (y/n/select numbers)
```

## Step 5: Apply Changes

### Auto-Apply Low-Risk

For each approved low-risk change:
1. Read the target SKILL.md
2. Apply the edit using the Edit tool
3. Verify the file is still valid (frontmatter intact, markdown well-formed)

### Apply Approved Medium/High-Risk

For each user-approved change:
1. Show the exact diff before applying
2. Apply the edit
3. Run a quick validation (frontmatter check)

After all changes:
```bash
# Verify all modified skill files still have valid frontmatter
for f in [modified files]; do
  head -1 "$f" | grep -q "^---" && echo "OK: $f" || echo "BROKEN: $f"
done
```

## Step 6: Log Evolution

Write an evolution log to `~/.forge/retros/evolve_[date].json`:

```json
{
  "date": "YYYY-MM-DD",
  "retros_analyzed": 5,
  "skills_scored": {
    "think": 4.2,
    "architect": 3.8,
    "build": 2.4,
    "verify": 3.5,
    "ship": 4.0
  },
  "changes_proposed": 6,
  "changes_applied": {
    "low_risk": 3,
    "medium_risk": 1,
    "high_risk": 0
  },
  "changes_rejected": 2,
  "details": [
    {
      "skill": "build",
      "risk": "low",
      "description": "Clarified TDD step with example",
      "applied": true
    }
  ]
}
```

## Step 7: Remember

If any significant changes were applied, invoke `/memory-remember` to store the evolution decisions:
- What was changed and why
- Category: `workflow`
- Tags: `evolve`, `skill-improvement`, `[skill-name]`

## Step 8: Report

```
FORGE /evolve — Complete

Retros analyzed: [N]
Changes proposed: [N] (low: [N], medium: [N], high: [N])
Changes applied: [N]
Changes rejected: [N]
Evolution log: ~/.forge/retros/evolve_[date].json

Skills improved:
  /[skill] — [summary of changes]

Next: Run /retro after your next /ship cycle to continue the feedback loop.
```

## Rules

- **Low-risk changes only auto-apply** — everything else needs explicit user approval
- **Never remove safety guardrails** without the user explicitly approving (TDD enforcement, /verify blocking /ship, etc.)
- **Never modify the memory schema** without high-risk approval — other skills depend on it
- **Always validate** skill files after editing — broken frontmatter breaks the skill
- **Keep a log** of every change — the evolution history is part of FORGE's story
- **One evolution per session** — don't run /evolve multiple times without new retro data
- If there are fewer than 2 retros, warn: "Limited data — proposals may be noisy. Consider running more cycles before evolving."
- Git-track skill changes: after applying, suggest the user commits with a message like "evolve: [summary]"
