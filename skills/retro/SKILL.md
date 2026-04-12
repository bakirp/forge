---
name: retro
description: "Post-ship retrospective. Asks three structured questions about what slowed you down, what you'd do differently, and what FORGE should remember. Stores structured retro data that /evolve consumes. Use after shipping — triggered by 'run a retro', 'retrospective', 'what went well', 'what slowed us down', 'reflect on the session'."
argument-hint: "[optional: project name or session context]"
allowed-tools: Read Grep Glob Bash Write
---

# /retro — Post-Ship Retrospective

Never fabricate user answers — only record what they actually said. Collect structured feedback after `/ship` that `/evolve` uses to improve FORGE skills.

> **Shared protocols apply.** See `skills/shared/rules.md`, `skills/shared/compliance-telemetry.md`, and `skills/shared/workflow-routing.md`.

## Step 1: Gather Context

```bash
git log --oneline -20
ls -t .forge/architecture/*.md 2>/dev/null | head -1
FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)
cat .forge/verify/${FEATURE_NAME}.md 2>/dev/null | head -5
bash scripts/artifact-discover.sh all
```

Read `$ARGUMENTS` for user context. Detect project name via `basename "$(pwd)"`.

## Step 2: Ask Three Questions

Present each question one at a time; wait for the response before proceeding. Each accepts free text or "skip".

- **Q1 — What slowed us down?** Bottlenecks, unclear requirements, wrong assumptions.
- **Q2 — What would we do differently?** Architecture decisions, phases to skip/add.
- **Q3 — What should FORGE remember?** Decisions to carry forward, anti-patterns, preferences.

## Step 3: Score FORGE Skills

Ask the user to rate each skill used (1-5 or skip): `"think:4 architect:5 build:3 verify:skip ship:4"`. For any skill rated 1-2, ask: "What went wrong specifically?"

## Step 4: Trend Analysis

```bash
ls ~/.forge/retros/*.json 2>/dev/null | wc -l
```

If 3+ retros exist, surface recurring themes in `what_slowed_us` / `what_differently` per project and cross-project low-rated skills. Present as `"[theme] (mentioned N times)"`. Fewer than 3 retros — skip silently.

## Step 5: Build Retro Document

Compile JSON with fields:
- `date`, `project`, `session_summary` — identifiers and 1-2 sentence summary
- `questions` — `what_slowed_us`, `what_differently`, `what_to_remember` (string or null)
- `skill_ratings` — map of skill name to `{ score, feedback }` (null if skipped)
- `decisions_to_remember` — array from Q3; `improvements_suggested` — array from Q1-Q2

## Step 6: Save Retro

```bash
mkdir -p ~/.forge/retros
DATE=$(date +%Y-%m-%d)
PROJECT="[project name]"
BASE="$HOME/.forge/retros/${DATE}_${PROJECT}"
TARGET="${BASE}.json"
COUNTER=1
while [ -f "$TARGET" ]; do
  TARGET="${BASE}_${COUNTER}.json"
  COUNTER=$((COUNTER + 1))
done
```

Write the JSON document to `$TARGET`.

## Step 7: Store Memories

If Q3 was answered, invoke `/memory-remember` with those decisions — don't just note them.

## Step 8: Summary

```
FORGE /retro — Complete

Retro saved: ~/.forge/retros/[filename].json
Skills rated: [count]
Decisions stored: [count] (via /memory-remember)
Improvements noted: [count] (available for /evolve)

Low-rated skills:
  /[skill] — [score]: [feedback summary]
```

## What's Next

Recommend `/evolve` to apply learnings, or `/think` to start a new task.

## Rules & Compliance

Never skip the three questions (accept "skip" as valid). Always save the retro even if all questions are skipped. Output must be valid parseable JSON — `/evolve` depends on it. Do not suggest skill changes during retro — that's `/evolve`'s job.

Follow `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh` per shared protocol. Violation keys: `fabricated-answers` (critical), `invalid-json` (major), `memory-not-stored` (minor), `scope-creep` (minor).
